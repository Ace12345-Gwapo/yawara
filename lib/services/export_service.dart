// ============================================================
// lib/services/export_service.dart
// Maghimo og plain-text attendance report para ma-share
// ============================================================

import '../models/schedule.dart';

class ExportService {
  /// Maghimo og formatted text summary sa attendance
  static String generatePlainSummary(List<ClassSchedule> schedules) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int present = 0, late = 0, absent = 0, unchecked = 0;
    for (var item in schedules) {
      if (item.status == 'Present') {
        present++;
      } else if (item.status == 'Late') {
        late++;
      } else if (item.status == 'Absent') {
        absent++;
      } else {
        unchecked++;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('TCGC ATTENDANCE REPORT');
    buffer.writeln('Date : $dateStr');
    buffer.writeln('Time : $timeStr');
    buffer.writeln();
    buffer.writeln('SUMMARY');
    buffer.writeln();
    buffer.writeln('Present   : $present');
    buffer.writeln('Late      : $late');
    buffer.writeln('Absent    : $absent');
    buffer.writeln('Unchecked : $unchecked');
    buffer.writeln('Total     : ${schedules.length}');
    buffer.writeln();

    final checked = schedules.where((s) => s.status != null).toList();
    if (checked.isEmpty) {
      buffer.writeln('No attendance records yet.');
    } else {
      for (var item in checked) {
        buffer.writeln('▸ ${item.instructor}');
        buffer.writeln(
            '  Course  : ${item.courseCode} — ${item.subjectTitle}');
        buffer.writeln('  Room    : ${item.room}');
        buffer.writeln(
            '  Status  : ${item.status} @ ${item.attendanceTime ?? '-'}');
        buffer.writeln('  Remarks : ${item.remarks ?? 'None'}');
        buffer.writeln();
      }
    }

    buffer.writeln('TCGC Monitoring System');
    return buffer.toString();
  }
}