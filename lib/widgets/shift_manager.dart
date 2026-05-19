// ============================================================
// lib/widgets/shift_manager.dart
// I-filter ang mga schedule base sa set number (shift)
// ============================================================

import '../models/schedule.dart';

class ShiftManager {
  /// 0 = Face to Face, 1 = Online Set 1, 2 = Online Set 2
  static List<ClassSchedule> filterByShift(
      List<ClassSchedule> all, int shift) {
    return all.where((item) => item.setNumber == shift).toList();
  }
}