// ============================================================
// lib/widgets/add_entry_dialog.dart
// FIX: Overflow resolved — smaller day circles, Flexible time boxes
// ============================================================

import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';

void showAddEntryDialog(BuildContext context, VoidCallback onRefresh) {
  final schedCodeCtrl   = TextEditingController();
  final courseCodeCtrl  = TextEditingController();
  final courseTitleCtrl = TextEditingController();
  final instructorCtrl  = TextEditingController();
  final roomCtrl        = TextEditingController();

  int tempSet = 0;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final List<String> allDays     = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<bool>   selectedDays = List.filled(7, false);

  const green = Color(0xFF1B5E20);

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();

  Color setColor(int set) {
    if (set == 0) return const Color(0xFF1B5E20);
    if (set == 1) return const Color(0xFF1D4ED8);
    return const Color(0xFF7C3AED);
  }

  String formatTime(TimeOfDay t) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // FIX: Tighten padding so content has more horizontal room
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        title: const Text('New Entry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildField(schedCodeCtrl, null, 'Schedule Code', Icons.tag,
                  TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f1)),
              const SizedBox(height: 10),
              _buildField(courseCodeCtrl, f1, 'Course Code', Icons.code,
                  TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f2)),
              const SizedBox(height: 10),
              _buildField(courseTitleCtrl, f2, 'Course Title', Icons.book,
                  TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f3)),
              const SizedBox(height: 10),
              _buildField(instructorCtrl, f3, 'Instructor Name', Icons.person,
                  TextInputAction.next,
                  () => FocusScope.of(dialogContext).requestFocus(f4)),
              const SizedBox(height: 10),
              _buildField(roomCtrl, f4, 'Room / MOL', Icons.room,
                  TextInputAction.done, null),
              const SizedBox(height: 14),

              // ── Time pickers ──────────────────────────
              Text('Class Time',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                children: [
                  // FIX: Expanded so both boxes share space equally, no overflow
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: startTime ??
                              const TimeOfDay(hour: 0, minute: 0),
                          helpText: 'Select Start Time',
                          builder: (ctx, child) => MediaQuery(
                            data: MediaQuery.of(ctx)
                                .copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          ),
                        );
                        if (picked != null) setSt(() => startTime = picked);
                      },
                      child: _timeBox(
                        'Start',
                        startTime != null ? formatTime(startTime!) : 'Tap to set',
                        startTime != null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: endTime ??
                              const TimeOfDay(hour: 0, minute: 0),
                          helpText: 'Select End Time',
                          builder: (ctx, child) => MediaQuery(
                            data: MediaQuery.of(ctx)
                                .copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          ),
                        );
                        if (picked != null) setSt(() => endTime = picked);
                      },
                      child: _timeBox(
                        'End',
                        endTime != null ? formatTime(endTime!) : 'Tap to set',
                        endTime != null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Day picker — FIX: spaceEvenly + smaller circles ──
              Text('Class Days',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final isSelected = selectedDays[i];
                  return GestureDetector(
                    onTap: () =>
                        setSt(() => selectedDays[i] = !selectedDays[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      // FIX: Reduced from 34 → 30 to prevent overflow
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected ? green : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSelected ? green : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          allDays[i].substring(0, 2),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // ── Class type ────────────────────────────
              Text('Class Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey[700])),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () {
              if (instructorCtrl.text.isEmpty ||
                  courseCodeCtrl.text.isEmpty ||
                  roomCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in required fields.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final timeStr = (startTime != null && endTime != null)
                  ? '${formatTime(startTime!)} - ${formatTime(endTime!)}'
                  : 'TBA';
              final dayStr = buildDayString(selectedDays);

              allInstructors.add(ClassSchedule(
                instructor:   instructorCtrl.text.toUpperCase(),
                courseCode:   courseCodeCtrl.text.toUpperCase(),
                subjectTitle: courseTitleCtrl.text,
                room:         roomCtrl.text.toUpperCase(),
                building:     schedCodeCtrl.text.toUpperCase(),
                timeRange:    timeStr,
                days:         dayStr.isEmpty ? 'TBA' : dayStr,
                setNumber:    tempSet,
              ));

              PersistenceService.saveAttendance(allInstructors);
              onRefresh();
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

Widget _buildField(
    TextEditingController ctrl,
    FocusNode? focus,
    String label,
    IconData icon,
    TextInputAction action,
    VoidCallback? onSubmit) {
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

// FIX: Flexible text column — no more overflow
Widget _timeBox(String label, String value, bool hasPicked) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    decoration: BoxDecoration(
      color: hasPicked
          ? const Color(0xFF1B5E20).withValues(alpha: 0.06)
          : Colors.grey[50],
      border: Border.all(
        color: hasPicked
            ? const Color(0xFF1B5E20).withValues(alpha: 0.4)
            : Colors.grey[300]!,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          Icons.access_time,
          size: 15,
          color: hasPicked ? const Color(0xFF1B5E20) : Colors.grey[400],
        ),
        const SizedBox(width: 6),
        // FIX: Flexible prevents horizontal overflow
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasPicked ? FontWeight.w700 : FontWeight.w400,
                  color: hasPicked ? const Color(0xFF111827) : Colors.grey[400],
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
    VoidCallback onTap) {
  final isSelected = current == value;
  final color = colorFn(value);
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
                color: isSelected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600]),
            ),
            Text(
              sub,
              style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey[400]),
            ),
          ],
        ),
      ),
    ),
  );
}