// ============================================================
// lib/widgets/edit_entry_dialog.dart
// FIXED: Layout overflow on Class Time and Class Days rows.
//   • Days: Row replaced with Wrap — circles wrap on small screens
//   • Time: uses Flexible instead of fixed-width containers
//   • All time/day sections wrapped in LayoutBuilder for safety
// ============================================================

import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';

void showEditEntryDialog(
    BuildContext context, int idx, VoidCallback onRefresh) {
  final entry = allInstructors[idx];

  final schedCodeCtrl   = TextEditingController(text: entry.building);
  final courseCodeCtrl  = TextEditingController(text: entry.courseCode);
  final courseTitleCtrl = TextEditingController(text: entry.subjectTitle);
  final instructorCtrl  = TextEditingController(text: entry.instructor);
  final roomCtrl        = TextEditingController(text: entry.room);

  int tempSet = entry.setNumber;

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();

  const green = Color(0xFF1B5E20);

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  try {
    if (entry.timeRange != 'TBA' && entry.timeRange.contains(' - ')) {
      final parts = entry.timeRange.split(' - ');
      startTime = _parseTimeOfDay(parts[0].trim());
      endTime   = _parseTimeOfDay(parts[1].trim());
    }
  } catch (_) {}

  final List<String> allDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  final List<bool> selectedDays =
      List.generate(7, (i) => entry.days.contains(allDays[i]));

  Color setColor(int set) {
    if (set == 0) return const Color(0xFF1B5E20);
    if (set == 1) return const Color(0xFF1D4ED8);
    return const Color(0xFF7C3AED);
  }

  String formatTime(TimeOfDay? t) {
    if (t == null) return '--:-- --';
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min    = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  String buildDayString(List<bool> days) {
    final result = <String>[];
    for (int i = 0; i < allDays.length; i++) {
      if (days[i]) result.add(allDays[i]);
    }
    return result.join(', ');
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setSt) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded, color: green, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Edit Entry',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fields ──────────────────────────────
              _buildField(schedCodeCtrl, null, 'Schedule Code',
                  Icons.tag, TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f1)),
              const SizedBox(height: 10),
              _buildField(courseCodeCtrl, f1, 'Course Code',
                  Icons.code, TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f2)),
              const SizedBox(height: 10),
              _buildField(courseTitleCtrl, f2, 'Course Title',
                  Icons.book, TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f3)),
              const SizedBox(height: 10),
              _buildField(instructorCtrl, f3, 'Instructor Name',
                  Icons.person, TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f4)),
              const SizedBox(height: 10),
              _buildField(roomCtrl, f4, 'Room / MOL',
                  Icons.room, TextInputAction.done, null),
              const SizedBox(height: 14),

              // ── Time picker — FIX: Flexible, no fixed widths ──
              Text('Class Time',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              // LayoutBuilder prevents overflow regardless of dialog width
              LayoutBuilder(
                builder: (_, constraints) => Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: startTime ??
                                const TimeOfDay(hour: 8, minute: 0),
                            helpText: 'Select Start Time',
                          );
                          if (picked != null) {
                            setSt(() => startTime = picked);
                          }
                        },
                        child: _timeBox(
                            'Start', formatTime(startTime),
                            startTime != null),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[400])),
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: endTime ??
                                const TimeOfDay(hour: 9, minute: 30),
                            helpText: 'Select End Time',
                          );
                          if (picked != null) {
                            setSt(() => endTime = picked);
                          }
                        },
                        child: _timeBox(
                            'End', formatTime(endTime), endTime != null),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Day picker — FIX: Wrap prevents overflow ──────
              Text('Class Days',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,   // horizontal gap
                runSpacing: 6, // vertical gap when wrapping
                children: List.generate(7, (i) {
                  final isSelected = selectedDays[i];
                  return GestureDetector(
                    onTap: () =>
                        setSt(() => selectedDays[i] = !selectedDays[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? green
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSelected
                                ? green
                                : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          allDays[i].substring(0, 2),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // ── Class type ───────────────────────────
              Text('Class Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildClassTypeBtn(tempSet, 0, Icons.school,
                      'Face to Face', 'Set 0', setColor,
                      () => setSt(() => tempSet = 0)),
                  const SizedBox(width: 8),
                  _buildClassTypeBtn(tempSet, 1, Icons.computer,
                      'Online', 'Set 1', setColor,
                      () => setSt(() => tempSet = 1)),
                  const SizedBox(width: 8),
                  _buildClassTypeBtn(tempSet, 2, Icons.videocam,
                      'Online', 'Set 2', setColor,
                      () => setSt(() => tempSet = 2)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            icon: const Icon(Icons.save_outlined,
                color: Colors.white, size: 16),
            label: const Text('Save Changes',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (instructorCtrl.text.trim().isEmpty ||
                  courseCodeCtrl.text.trim().isEmpty ||
                  roomCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in required fields.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final timeStr =
                  (startTime != null && endTime != null)
                      ? '${formatTime(startTime)} - ${formatTime(endTime)}'
                      : 'TBA';
              final dayStr = buildDayString(selectedDays);

              allInstructors[idx]
                ..instructor   = instructorCtrl.text.trim().toUpperCase()
                ..courseCode   = courseCodeCtrl.text.trim().toUpperCase()
                ..subjectTitle = courseTitleCtrl.text.trim()
                ..room         = roomCtrl.text.trim().toUpperCase()
                ..building     = schedCodeCtrl.text.trim().toUpperCase()
                ..timeRange    = timeStr
                ..days         = dayStr.isEmpty ? 'TBA' : dayStr
                ..setNumber    = tempSet;

              PersistenceService.saveAttendance(allInstructors);
              onRefresh();
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry updated successfully.'),
                  backgroundColor: Color(0xFF1B5E20),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────

TimeOfDay? _parseTimeOfDay(String timeStr) {
  try {
    final parts     = timeStr.trim().split(' ');
    final timeParts = parts[0].split(':');
    int hour        = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    final String period = parts[1].toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  } catch (_) {
    return null;
  }
}

Widget _buildField(
  TextEditingController ctrl,
  FocusNode? focus,
  String label,
  IconData icon,
  TextInputAction action,
  VoidCallback? onSubmit,
) {
  return TextField(
    controller: ctrl,
    focusNode: focus,
    textInputAction: action,
    textCapitalization: TextCapitalization.words,
    onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

// Time box — no fixed pixel width, fills Flexible parent
Widget _timeBox(String label, String value, bool hasValue) {
  return Container(
    width: double.infinity, // fills Flexible
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[400]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? const Color(0xFF111827)
                      : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildClassTypeBtn(
  int current,
  int value,
  IconData icon,
  String label,
  String sub,
  Color Function(int) colorFn,
  VoidCallback onTap,
) {
  final isSelected = current == value;
  final color      = colorFn(value);
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey[600])),
            Text(sub,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white70
                        : Colors.grey[400])),
          ],
        ),
      ),
    ),
  );
}