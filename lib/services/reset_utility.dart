// ============================================================
// lib/services/reset_utility.dart
// UPDATED: Uses SQLite instead of SharedPreferences.
//          SA accounts and profiles are preserved automatically
//          because they live in a separate `users` table.
// ============================================================

import '../models/schedule.dart';
import 'local_database.dart';

class ResetUtility {
  /// Clear attendance statuses for all schedules.
  /// Schedule records, SA accounts, and history are NOT deleted.
  static Future<void> resetAll(List<ClassSchedule> schedules) async {
    // Reset in SQLite
    await LocalDatabase.resetAttendanceStatuses();

    // Mirror reset in the in-memory list
    for (final s in schedules) {
      s.status          = null;
      s.attendanceTime  = null;
      s.remarks         = null;
      s.syncStatus      = SyncStatus.pending;
    }
  }
}