// ============================================================
// lib/widgets/shift_manager.dart
// UPDATED: Added matchesShift() — used by dashboard filtering.
// ============================================================

import '../models/schedule.dart';

class ShiftManager {
  /// 0 = Face to Face, 1 = Online Set 1, 2 = Online Set 2

  /// Returns true when [item]'s set number matches [shift].
  /// Used for filtering in DashboardScreen.
  static bool matchesShift(ClassSchedule item, int shift) {
    return item.setNumber == shift;
  }

  /// Returns the filtered subset — kept for backwards compatibility.
  static List<ClassSchedule> filterByShift(
      List<ClassSchedule> all, int shift) {
    return all.where((item) => matchesShift(item, shift)).toList();
  }
}