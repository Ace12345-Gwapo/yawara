// ============================================================
// lib/services/history_service.dart
// Auto-saves daily attendance to history when a new day starts.
// History is keyed by date string. Admin can view all past records.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class HistoryService {
  static const _prefix        = 'history_';
  static const _lastSavedKey  = 'history_last_saved_date';

  // ── Today's date string ──────────────────────────────────
  static String get _todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Should we auto-save? True if last save was not today ─
  static Future<bool> shouldAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSavedKey) != _todayStr;
  }

  // ── Save today's checked records to history ───────────────
  // Call this before resetting attendance at start of new day.
  static Future<void> saveToday(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();

    // Only save entries that have been checked (have a status)
    final checked = schedules
        .where((s) => s.status != null && !s.isArchived)
        .toList();

    if (checked.isEmpty) {
      // Nothing to save — still mark today so we don't re-trigger
      await prefs.setString(_lastSavedKey, _todayStr);
      return;
    }

    final records = checked.map((s) => {
      'instructor'    : s.instructor,
      'courseCode'    : s.courseCode,
      'subjectTitle'  : s.subjectTitle,
      'room'          : s.room,
      'timeRange'     : s.timeRange,
      'days'          : s.days,
      'status'        : s.status,
      'attendanceTime': s.attendanceTime ?? '',
      'remarks'       : s.remarks ?? '',
      'setNumber'     : s.setNumber,
    }).toList();

    await prefs.setString('$_prefix$_todayStr', jsonEncode(records));
    await prefs.setString(_lastSavedKey, _todayStr);
  }

  // ── Load all history entries — newest first ───────────────
  static Future<List<Map<String, dynamic>>> loadAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final result = <Map<String, dynamic>>[];
    for (final key in keys) {
      final dateStr = key.replaceFirst(_prefix, '');
      final raw     = prefs.getString(key);
      if (raw == null) continue;
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        result.add({'date': dateStr, 'records': list});
      } catch (_) {
        // Skip malformed entries
      }
    }
    return result;
  }

  // ── Delete a single day's history (optional, for cleanup) ─
  static Future<void> deleteDay(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$dateStr');
  }

  // ── Clear all history ─────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    await prefs.remove(_lastSavedKey);
  }
}