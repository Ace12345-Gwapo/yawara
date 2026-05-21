// ============================================================
// lib/services/local_database.dart
// VERSION 2: Added `email` column to users table.
//            onUpgrade handles migration from v1 → v2 safely.
//            Admin profile image stored as a special 'admin' row.
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'tcgc_attendance.db');

    return openDatabase(
      path,
      version: 2,             // ← bumped from 1 to 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema creation (fresh install) ─────────────────────

  static Future<void> _onCreate(Database db, int version) async {
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

    // v2 schema — includes email from the start
    await db.execute('''
      CREATE TABLE users (
        username        TEXT PRIMARY KEY,
        password_hash   TEXT NOT NULL DEFAULT '',
        email           TEXT,
        profile_img     TEXT,
        gmail           TEXT,
        phone           TEXT,
        address         TEXT,
        bio             TEXT,
        sync_status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sqlite_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ── Schema migration (existing install) ─────────────────

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add email column — safe even if already present
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN email TEXT');
      } catch (_) {
        // Column already exists — ignore
      }
      // Ensure sqlite_meta table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sqlite_meta (
          key   TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SCHEDULE CRUD
  // ═══════════════════════════════════════════════════════════

  static Future<int> insertSchedule(ClassSchedule s) async {
    final db  = await database;
    final map = s.toSqliteMap()..remove('id');
    return db.insert('schedules', map);
  }

  static Future<void> updateSchedule(ClassSchedule s) async {
    if (s.id == null) return;
    final db = await database;
    await db.update('schedules', s.toSqliteMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  static Future<int> upsertSchedule(ClassSchedule s) async {
    final db = await database;
    return db.insert('schedules', s.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<ClassSchedule>> loadAllSchedules() async {
    final db   = await database;
    final rows = await db.query('schedules',
        where: 'sync_status != ?', whereArgs: ['deleted']);
    return rows.map(ClassSchedule.fromSqliteMap).toList();
  }

  static Future<void> markPending(int id) async {
    final db = await database;
    await db.update('schedules', {'sync_status': SyncStatus.pending.name},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> markSynced(int id) async {
    final db = await database;
    await db.update('schedules', {'sync_status': SyncStatus.synced.name},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<ClassSchedule>> getPendingSchedules() async {
    final db   = await database;
    final rows = await db.query('schedules',
        where: 'sync_status = ?', whereArgs: [SyncStatus.pending.name]);
    return rows.map(ClassSchedule.fromSqliteMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORY CRUD
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveHistory(
      String dateStr, List<ClassSchedule> records) async {
    final db    = await database;
    final batch = db.batch();
    for (final s in records) {
      batch.insert('history', {
        'date_str':        dateStr,
        'instructor':      s.instructor,
        'course_code':     s.courseCode,
        'subject_title':   s.subjectTitle,
        'room':            s.room,
        'time_range':      s.timeRange,
        'days':            s.days,
        'status':          s.status ?? '',
        'attendance_time': s.attendanceTime ?? '',
        'remarks':         s.remarks ?? '',
        'set_number':      s.setNumber,
        'sync_status':     SyncStatus.pending.name,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> loadAllHistory() async {
    final db   = await database;
    final rows = await db.query('history', orderBy: 'date_str DESC');
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final row in rows) {
      final date = row['date_str'] as String;
      grouped.putIfAbsent(date, () => []).add(Map.from(row));
    }
    return grouped.entries
        .map((e) => {'date': e.key, 'records': e.value})
        .toList();
  }

  static Future<void> deleteHistory(String dateStr) async {
    final db = await database;
    await db.delete('history',
        where: 'date_str = ?', whereArgs: [dateStr]);
  }

  static Future<List<Map<String, dynamic>>> getPendingHistory() async {
    final db = await database;
    return db.query('history',
        where: 'sync_status = ?', whereArgs: [SyncStatus.pending.name]);
  }

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
  // USERS CRUD
  // ═══════════════════════════════════════════════════════════

  static Future<void> upsertUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('users', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getUser(String username) async {
    final db   = await database;
    final rows = await db.query('users',
        where: 'LOWER(username) = LOWER(?)', whereArgs: [username], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<List<String>> getAllSAUsernames() async {
    final db   = await database;
    // Exclude the 'admin' special row from SA list
    final rows = await db.query('users',
        columns: ['username'],
        where: 'username != ?',
        whereArgs: ['admin']);
    return rows.map((r) => r['username'] as String).toList();
  }

  static Future<void> deleteUser(String username) async {
    final db = await database;
    await db.delete('users', where: 'LOWER(username) = LOWER(?)', whereArgs: [username]);
  }

  static Future<void> updateUserField(
      String username, String field, String value) async {
    final db = await database;
    await db.update(
      'users',
      {field: value, 'sync_status': SyncStatus.pending.name},
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final db = await database;
    return db.query('users',
        where: 'sync_status = ? AND username != ?',
        whereArgs: [SyncStatus.pending.name, 'admin']);
  }

  static Future<void> markUserSynced(String username) async {
    final db = await database;
    await db.update('users', {'sync_status': SyncStatus.synced.name},
        where: 'LOWER(username) = LOWER(?)', whereArgs: [username]);
  }

  // ── Admin profile helpers ─────────────────────────────────

  /// Ensure the admin row exists so profile data can be stored.
  static Future<void> ensureAdminRow() async {
    final existing = await getUser('admin');
    if (existing == null) {
      await upsertUser({
        'username':      'admin',
        'password_hash': '',     // Auth is handled outside DB
        'sync_status':   SyncStatus.synced.name,
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MAINTENANCE
  // ═══════════════════════════════════════════════════════════

  static Future<void> resetAttendanceStatuses() async {
    final db = await database;
    await db.update('schedules', {
      'status':          null,
      'attendance_time': null,
      'remarks':         null,
      'sync_status':     SyncStatus.pending.name,
    });
  }

  // ── sqlite_meta helpers (used by HistoryService) ─────────

  static Future<String?> getMeta(String key) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sqlite_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    final rows = await db.query('sqlite_meta',
        where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  static Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sqlite_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.insert('sqlite_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}