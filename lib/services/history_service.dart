// ============================================================
// lib/services/history_service.dart
// UPDATED: Now uses SQLite (LocalDatabase) instead of
//          SharedPreferences JSON blobs.
//
// Public API is identical to the original.
// ============================================================

import 'package:sqflite/sqflite.dart';
import '../models/schedule.dart';
import 'local_database.dart';

class HistoryService {
  static const _lastSavedKey = 'history_last_saved_date';

  static String get _todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Should we auto-save today? ────────────────────────────
  static Future<bool> shouldAutoSave() async {
    final db   = await LocalDatabase.database;
    // Use a tiny meta table stored in the same DB
    final rows = await db.rawQuery(
      "SELECT value FROM sqlite_meta WHERE key = ?",
      [_lastSavedKey],
    ).catchError((_) async {
      // Table may not exist on first run — create it
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sqlite_meta (
          key   TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      return <Map<String, dynamic>>[];
    });

    if (rows.isEmpty) return true;
    return (rows.first['value'] as String?) != _todayStr;
  }

  // ── Save today's checked records ──────────────────────────
  static Future<void> saveToday(List<ClassSchedule> schedules) async {
    final checked = schedules
        .where((s) => s.status != null && !s.isArchived)
        .toList();

    if (checked.isNotEmpty) {
      await LocalDatabase.saveHistory(_todayStr, checked);
    }

    // Mark today as saved
    final db = await LocalDatabase.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sqlite_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.insert(
      'sqlite_meta',
      {'key': _lastSavedKey, 'value': _todayStr},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Load all history (newest first) ──────────────────────
  static Future<List<Map<String, dynamic>>> loadAllHistory() async {
    return LocalDatabase.loadAllHistory();
  }

  // ── Delete a single day ───────────────────────────────────
  static Future<void> deleteDay(String dateStr) async {
    await LocalDatabase.deleteHistory(dateStr);
  }

  // ── Clear all history ─────────────────────────────────────
  static Future<void> clearAll() async {
    final db = await LocalDatabase.database;
    await db.delete('history');
    await db.delete('sqlite_meta',
        where: 'key = ?', whereArgs: [_lastSavedKey]);
  }
}