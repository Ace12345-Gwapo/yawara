// ============================================================
// lib/services/persistence_service.dart
// I-save ug i-load ang attendance data sa SharedPreferences
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class PersistenceService {
  /// I-save ang tanan nga schedule entries sa local storage
  static Future<void> saveAttendance(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();

    // I-save ang total count sa entries
    await prefs.setInt('instructor_count', schedules.length);

    for (int i = 0; i < schedules.length; i++) {
      await prefs.setString('name_$i', schedules[i].instructor);
      await prefs.setString('course_code_$i', schedules[i].courseCode);
      await prefs.setString('sub_$i', schedules[i].subjectTitle);
      await prefs.setString('room_$i', schedules[i].room);
      await prefs.setString('bldg_$i', schedules[i].building);
      await prefs.setString('time_range_$i', schedules[i].timeRange);
      await prefs.setString('days_$i', schedules[i].days);
      await prefs.setInt('shift_$i', schedules[i].setNumber);
      await prefs.setString('status_$i', schedules[i].status ?? '');
      await prefs.setString('attend_time_$i', schedules[i].attendanceTime ?? '');
      await prefs.setString('remarks_$i', schedules[i].remarks ?? '');
      await prefs.setString('sa_assign_$i', schedules[i].assignedSA ?? '');
      // I-save ang duha ka archive flags — Admin ug SA — separately
      await prefs.setBool('archived_$i', schedules[i].isArchived);
      await prefs.setBool('archived_sa_$i', schedules[i].isArchivedBySA);
    }
  }

  /// I-load ang tanan nga entries gikan sa local storage
  static Future<void> loadAttendance(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final int? count = prefs.getInt('instructor_count');

    // Dugangi ang list kung naay bag-ong entries
    if (count != null && count > schedules.length) {
      for (int i = schedules.length; i < count; i++) {
        schedules.add(ClassSchedule(
          instructor: prefs.getString('name_$i') ?? '',
          courseCode: prefs.getString('course_code_$i') ?? 'NEW',
          subjectTitle: prefs.getString('sub_$i') ?? '',
          room: prefs.getString('room_$i') ?? '',
          building: prefs.getString('bldg_$i') ?? '',
          timeRange: prefs.getString('time_range_$i') ?? 'TBA',
          days: prefs.getString('days_$i') ?? 'TBA',
          setNumber: prefs.getInt('shift_$i') ?? 0,
          isArchived: prefs.getBool('archived_$i') ?? false,
          isArchivedBySA: prefs.getBool('archived_sa_$i') ?? false,
        ));
      }
    }

    // I-update ang attendance data sa existing entries
    for (int i = 0; i < schedules.length; i++) {
      final st = prefs.getString('status_$i');
      schedules[i].status = (st == null || st.isEmpty) ? null : st;
      schedules[i].attendanceTime = prefs.getString('attend_time_$i');
      final rm = prefs.getString('remarks_$i');
      schedules[i].remarks = (rm == null || rm.isEmpty) ? null : rm;
      final sa = prefs.getString('sa_assign_$i');
      schedules[i].assignedSA = (sa == null || sa.isEmpty) ? null : sa;
      schedules[i].isArchived = prefs.getBool('archived_$i') ?? false;
      // I-load ang SA archive flag — separate sa Admin archive
      schedules[i].isArchivedBySA = prefs.getBool('archived_sa_$i') ?? false;
    }
  }
}