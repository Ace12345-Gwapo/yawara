// ============================================================
// lib/services/persistence_service.dart
// REWRITTEN: Delegates to LocalDatabase (SQLite).
//            Same public API — widgets need no changes.
// ============================================================

import '../models/schedule.dart';
import 'local_database.dart';

class PersistenceService {
  static Future<void> saveAttendance(List<ClassSchedule> schedules) async {
    for (final s in schedules) {
      if (s.id != null) {
        s.syncStatus = SyncStatus.pending;
        await LocalDatabase.updateSchedule(s);
      } else {
        final newId = await LocalDatabase.insertSchedule(s);
        s.id = newId;
        s.syncStatus = SyncStatus.pending;
      }
    }
  }

  static Future<void> loadAttendance(List<ClassSchedule> schedules) async {
    final loaded = await LocalDatabase.loadAllSchedules();
    schedules.clear();
    schedules.addAll(loaded);
  }
}