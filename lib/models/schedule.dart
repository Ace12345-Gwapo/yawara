// ============================================================
// lib/models/schedule.dart
// UPDATED: Added `id` and `syncStatus` for hybrid DB support
// ============================================================

// Global list — gikuha sa tanan nga screens
List<ClassSchedule> allInstructors = [];

/// Sync status para sa hybrid offline-first strategy
enum SyncStatus {
  synced,    // Saved sa SQLite ug Supabase
  pending,   // Saved sa SQLite, dili pa sa Supabase (offline)
  deleted,   // Soft-deleted locally, pending delete sa Supabase
}

/// Nagrepresenta sa usa ka class schedule sa usa ka instructor
class ClassSchedule {
  // ── NEW: Hybrid DB fields ─────────────────────────────────
  /// Local SQLite primary key (auto-incremented, null = not yet saved)
  int? id;

  /// Tracks whether this record has been synced to Supabase
  SyncStatus syncStatus;

  // ── Existing fields ───────────────────────────────────────
  String instructor;
  String courseCode;
  String subjectTitle;
  String room;
  String building;
  String timeRange;
  String days;
  int setNumber;        // 0 = Face to Face, 1 = Online Set 1, 2 = Online Set 2
  String? status;       // Present, Late, Absent, o null
  String? attendanceTime;
  String? remarks;
  String? assignedSA;

  bool isArchived;
  bool isArchivedBySA;

  ClassSchedule({
    this.id,
    this.syncStatus = SyncStatus.pending,
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

  // ── Serialization helpers ─────────────────────────────────

  /// Convert to a Map for SQLite insertion
  Map<String, dynamic> toSqliteMap() {
    return {
      if (id != null) 'id': id,
      'instructor':      instructor,
      'course_code':     courseCode,
      'subject_title':   subjectTitle,
      'room':            room,
      'building':        building,
      'time_range':      timeRange,
      'days':            days,
      'set_number':      setNumber,
      'status':          status ?? '',
      'attendance_time': attendanceTime ?? '',
      'remarks':         remarks ?? '',
      'assigned_sa':     assignedSA ?? '',
      'is_archived':     isArchived ? 1 : 0,
      'is_archived_sa':  isArchivedBySA ? 1 : 0,
      'sync_status':     syncStatus.name,
    };
  }

  /// Build a ClassSchedule from a SQLite row
  factory ClassSchedule.fromSqliteMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id:              map['id'] as int?,
      syncStatus:      SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      instructor:      map['instructor'] ?? '',
      courseCode:      map['course_code'] ?? 'NEW',
      subjectTitle:    map['subject_title'] ?? '',
      room:            map['room'] ?? '',
      building:        map['building'] ?? '',
      timeRange:       map['time_range'] ?? 'TBA',
      days:            map['days'] ?? 'TBA',
      setNumber:       map['set_number'] ?? 0,
      status:          _nullIfEmpty(map['status']),
      attendanceTime:  _nullIfEmpty(map['attendance_time']),
      remarks:         _nullIfEmpty(map['remarks']),
      assignedSA:      _nullIfEmpty(map['assigned_sa']),
      isArchived:      (map['is_archived'] ?? 0) == 1,
      isArchivedBySA:  (map['is_archived_sa'] ?? 0) == 1,
    );
  }

  /// Convert to a Map for Supabase upsert
  /// Note: Supabase uses the local SQLite `id` as primary key
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id':              id,
      'instructor':      instructor,
      'course_code':     courseCode,
      'subject_title':   subjectTitle,
      'room':            room,
      'building':        building,
      'time_range':      timeRange,
      'days':            days,
      'set_number':      setNumber,
      'status':          status ?? '',
      'attendance_time': attendanceTime ?? '',
      'remarks':         remarks ?? '',
      'assigned_sa':     assignedSA ?? '',
      'is_archived':     isArchived,
      'is_archived_sa':  isArchivedBySA,
    };
  }

  static String? _nullIfEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}