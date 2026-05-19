// ============================================================
// lib/models/schedule.dart
// Data model sa matag instructor schedule entry
// ============================================================

// Global list — gikuha sa tanan nga screens
List<ClassSchedule> allInstructors = [];

/// Nagrepresenta sa usa ka class schedule sa usa ka instructor
class ClassSchedule {
  String instructor;
  String courseCode;
  String subjectTitle;
  String room;
  String building;      // gigamit para sa schedule code
  String timeRange;
  String days;
  int setNumber;        // 0 = Face to Face, 1 = Online Set 1, 2 = Online Set 2
  String? status;       // Present, Late, Absent, o null
  String? attendanceTime;
  String? remarks;
  String? assignedSA;   // username sa assigned Student Assistant

  // Duha ka SEPARATE archive flags — dili mag-affect ang usa sa usa
  // isArchived     = Admin ang nag-archive — Admin view ra
  // isArchivedBySA = SA ang nag-archive   — SA view ra
  bool isArchived;
  bool isArchivedBySA;

  ClassSchedule({
    required this.instructor,
    required this.courseCode,
    required this.subjectTitle,
    required this.room,
    required this.building,
    required this.timeRange,
    required this.days,
    required this.setNumber,
    this.status,
    this.attendanceTime,
    this.remarks,
    this.assignedSA,
    this.isArchived = false,
    this.isArchivedBySA = false,
  });
}