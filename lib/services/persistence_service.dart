// ============================================================
// lib/services/persistence_service.dart
// REWRITTEN: Now delegates to LocalDatabase (SQLite) instead of
//            SharedPreferences.
//
// The public API (saveAttendance / loadAttendance) is kept
// identical so every widget that imports this file continues
// to compile without changes.
// ============================================================

import '../models/schedule.dart';
import 'local_database.dart';

class PersistenceService {
  /// Persist all schedule entries to SQLite.
  /// Existing rows are updated; new rows (id == null) are inserted.
  static Future<void> saveAttendance(List<ClassSchedule> schedules) async {
    for (final s in schedules) {
      if (s.id != null) {
        // Already in DB — update in place
        s.syncStatus = SyncStatus.pending;
        await LocalDatabase.updateSchedule(s);
      } else {
        // Brand-new entry — insert and store the generated id
        final newId = await LocalDatabase.insertSchedule(s);
        s.id = newId;
        s.syncStatus = SyncStatus.pending;
      }
    }
  }

  /// Load all schedules from SQLite into the provided list.
  /// Clears and repopulates the list — same behaviour as the
  /// original SharedPreferences version.
  static Future<void> loadAttendance(List<ClassSchedule> schedules) async {
    final loaded = await LocalDatabase.loadAllSchedules();
    schedules.clear();
    schedules.addAll(loaded);
  }
}