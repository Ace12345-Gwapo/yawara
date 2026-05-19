// ============================================================
// lib/services/reset_utility.dart
// I-reset ang tanan nga attendance — SA accounts dili mawala
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class ResetUtility {
  /// I-clear ang attendance data pero i-preserve ang SA accounts ug profiles
  static Future<void> resetAll(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();

    for (final key in keys) {
      // Dili tangtangon ang SA accounts ug profile data
      if (!key.startsWith('sa_') &&
          !key.startsWith('profile_')) {
        await prefs.remove(key);
      }
    }

    // I-clear ang attendance status sa memory
    for (var item in schedules) {
      item.status = null;
      item.attendanceTime = null;
      item.remarks = null;
    }
  }
}