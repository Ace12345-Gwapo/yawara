// ============================================================
// lib/services/local_database.dart
// NEW: SQLite local database using sqflite
//
// Replaces PersistenceService's SharedPreferences key-value hack
// with a proper relational table. All writes go here first.
// SyncService reads from here to push to Supabase when online.
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule.dart';

class LocalDatabase {
  static Database? _db;

  // ── Open / create the database ────────────────────────────
  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'tcgc_attendance.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ── schedules table ───────────────────────────────────────
    await db.execute('''
      CREATE TABLE schedules (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        instructor      TEXT NOT NULL,
        course_code     TEXT NOT NULL,
        subject_title   TEXT NOT NULL,
        room            TEXT NOT NULL,
        building        TEXT NOT NULL,
        time_range      TEXT NOT NULL,
        days            TEXT NOT NULL,
        set_number      INTEGER NOT NULL DEFAULT 0,
        status          TEXT,
        attendance_time TEXT,
        remarks         TEXT,
        assigned_sa     TEXT,
        is_archived     INTEGER NOT NULL DEFAULT 0,
        is_archived_sa  INTEGER NOT NULL DEFAULT 0,
        sync_status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // ── history table ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE history (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        date_str        TEXT NOT NULL,
        instructor      TEXT NOT NULL,
        course_code     TEXT NOT NULL,
        subject_title   TEXT NOT NULL,
        room            TEXT NOT NULL,
        time_range      TEXT NOT NULL,
        days            TEXT NOT NULL,
        status          TEXT NOT NULL,
        attendance_time TEXT,
        remarks         TEXT,
        set_number      INTEGER NOT NULL DEFAULT 0,
        sync_status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // ── users table (SA accounts) ─────────────────────────────
    // Note: Admin credentials remain hard-coded in AuthService.
    await db.execute('''
      CREATE TABLE users (
        username        TEXT PRIMARY KEY,
        password_hash   TEXT NOT NULL,
        profile_img     TEXT,
        gmail           TEXT,
        phone           TEXT,
        address         TEXT,
        bio             TEXT,
        sync_status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════════
  // SCHEDULE CRUD
  // ═══════════════════════════════════════════════════════════

  /// Insert a new schedule. Returns the new row id.
  static Future<int> insertSchedule(ClassSchedule s) async {
    final db  = await database;
    final map = s.toSqliteMap()..remove('id'); // let SQLite assign id
    return db.insert('schedules', map);
  }

  /// Update an existing schedule by id.
  static Future<void> updateSchedule(ClassSchedule s) async {
    if (s.id == null) return;
    final db  = await database;
    await db.update(
      'schedules',
      s.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  /// Upsert (insert or update) a schedule.
  static Future<int> upsertSchedule(ClassSchedule s) async {
    final db = await database;
    return db.insert(
      'schedules',
      s.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a schedule by id (hard delete).
  static Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// Load all non-deleted schedules.
  static Future<List<ClassSchedule>> loadAllSchedules() async {
    final db   = await database;
    final rows = await db.query(
      'schedules',
      where: 'sync_status != ?',
      whereArgs: ['deleted'],
    );
    return rows.map(ClassSchedule.fromSqliteMap).toList();
  }

  /// Mark a schedule as needing sync (e.g. after an offline edit).
  static Future<void> markPending(int id) async {
    final db = await database;
    await db.update(
      'schedules',
      {'sync_status': SyncStatus.pending.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark a schedule as synced after successful Supabase push.
  static Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'schedules',
      {'sync_status': SyncStatus.synced.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Return all records that still need to be pushed to Supabase.
  static Future<List<ClassSchedule>> getPendingSchedules() async {
    final db   = await database;
    final rows = await db.query(
      'schedules',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.name],
    );
    return rows.map(ClassSchedule.fromSqliteMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORY CRUD
  // ═══════════════════════════════════════════════════════════

  /// Save one day's attendance snapshot to history.
  static Future<void> saveHistory(
      String dateStr, List<ClassSchedule> records) async {
    final db = await database;
    final batch = db.batch();
    for (final s in records) {
      batch.insert('history', {
        'date_str':       dateStr,
        'instructor':     s.instructor,
        'course_code':    s.courseCode,
        'subject_title':  s.subjectTitle,
        'room':           s.room,
        'time_range':     s.timeRange,
        'days':           s.days,
        'status':         s.status ?? '',
        'attendance_time':s.attendanceTime ?? '',
        'remarks':        s.remarks ?? '',
        'set_number':     s.setNumber,
        'sync_status':    SyncStatus.pending.name,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Load all history records grouped by date (newest first).
  static Future<List<Map<String, dynamic>>> loadAllHistory() async {
    final db   = await database;
    final rows = await db.query('history', orderBy: 'date_str DESC');

    // Group by date_str
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final row in rows) {
      final date = row['date_str'] as String;
      grouped.putIfAbsent(date, () => []).add(Map<String, dynamic>.from(row));
    }

    return grouped.entries
        .map((e) => {'date': e.key, 'records': e.value})
        .toList();
  }

  /// Delete all history for a specific date.
  static Future<void> deleteHistory(String dateStr) async {
    final db = await database;
    await db.delete('history', where: 'date_str = ?', whereArgs: [dateStr]);
  }

  /// Get unsynced history rows for Supabase push.
  static Future<List<Map<String, dynamic>>> getPendingHistory() async {
    final db   = await database;
    return db.query('history',
        where: 'sync_status = ?', whereArgs: [SyncStatus.pending.name]);
  }

  /// Mark history rows as synced.
  static Future<void> markHistorySynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db          = await database;
    final placeholder = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE history SET sync_status = ? WHERE id IN ($placeholder)',
      [SyncStatus.synced.name, ...ids],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // USERS CRUD  (SA accounts)
  // ═══════════════════════════════════════════════════════════

  /// Insert or replace a user row.
  static Future<void> upsertUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('users', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a user by username. Returns null if not found.
  static Future<Map<String, dynamic>?> getUser(String username) async {
    final db   = await database;
    final rows = await db.query('users',
        where: 'username = ?', whereArgs: [username], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Get all SA usernames.
  static Future<List<String>> getAllSAUsernames() async {
    final db   = await database;
    final rows = await db.query('users', columns: ['username']);
    return rows.map((r) => r['username'] as String).toList();
  }

  /// Delete a user.
  static Future<void> deleteUser(String username) async {
    final db = await database;
    await db.delete('users', where: 'username = ?', whereArgs: [username]);
  }

  /// Update a user's field (e.g. password_hash, gmail, etc.)
  static Future<void> updateUserField(
      String username, String field, String value) async {
    final db = await database;
    await db.update(
      'users',
      {field: value, 'sync_status': SyncStatus.pending.name},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  /// Get users that need to be synced.
  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final db = await database;
    return db.query('users',
        where: 'sync_status = ?', whereArgs: [SyncStatus.pending.name]);
  }

  /// Mark a user as synced.
  static Future<void> markUserSynced(String username) async {
    final db = await database;
    await db.update(
      'users',
      {'sync_status': SyncStatus.synced.name},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAINTENANCE
  // ═══════════════════════════════════════════════════════════

  /// Clear all attendance statuses (daily reset) while keeping
  /// schedule entries, SA accounts, and history intact.
  static Future<void> resetAttendanceStatuses() async {
    final db = await database;
    await db.update('schedules', {
      'status':          null,
      'attendance_time': null,
      'remarks':         null,
      'sync_status':     SyncStatus.pending.name,
    });
  }
}