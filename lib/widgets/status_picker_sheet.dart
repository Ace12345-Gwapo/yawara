
// lib/widgets/status_picker_sheet.dart
// Bottom sheet para i-set ang attendance status sa instructor
// Present / Late / Absent — pwede usab mag-cancel check

import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';
import 'remarks_handler.dart';

void showStatusPickerSheet(
    BuildContext context, int idx, VoidCallback onRefresh) {
  final item = allInstructors[idx];
  final remarksCtrl = TextEditingController(text: item.remarks ?? '');

  Color setColor(int set) {
    if (set == 0) return const Color(0xFF1B5E20);
    if (set == 1) return const Color(0xFF1D4ED8);
    return const Color(0xFF7C3AED);
  }

  String setLabel(int set) {
    if (set == 0) return 'Face to Face';
    if (set == 1) return 'Online · Set 1';
    return 'Online · Set 2';
  }

  IconData setIcon(int set) =>
      set == 0 ? Icons.school_outlined : Icons.computer_outlined;

  /// I-format ang petsa karon
  String formatDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),

            // Instructor info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    setColor(item.setNumber).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: setColor(item.setNumber)
                        .withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: setColor(item.setNumber)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(setIcon(item.setNumber),
                        color: setColor(item.setNumber), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.instructor,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.room}  •  ${setLabel(item.setNumber)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status buttons ug remarks
            StatefulBuilder(
              builder: (context, setInner) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusBtn(
                          context, 'Present', const Color(0xFF16A34A),
                          Icons.check_circle_outline, idx,
                          remarksCtrl, ctx, formatDate, onRefresh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusBtn(
                          context, 'Late', const Color(0xFFEA580C),
                          Icons.timer_outlined, idx,
                          remarksCtrl, ctx, formatDate, onRefresh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusBtn(
                          context, 'Absent', const Color(0xFFDC2626),
                          Icons.cancel_outlined, idx,
                          remarksCtrl, ctx, formatDate, onRefresh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Remarks field
                  RemarksHandler.buildRemarksField(remarksCtrl),
                  const SizedBox(height: 10),

                  // Cancel check button — kung naay existing status
                  if (item.status != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          allInstructors[idx].status = null;
                          allInstructors[idx].attendanceTime = null;
                          allInstructors[idx].remarks = null;
                          PersistenceService.saveAttendance(allInstructors);
                          onRefresh();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.undo, size: 16),
                        label: const Text('Cancel Check'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Dismiss',
                          style: TextStyle(color: Colors.grey[400])),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Status button widget — Present, Late, o Absent
Widget _buildStatusBtn(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
    int idx,
    TextEditingController remarksCtrl,
    BuildContext ctx,
    String Function() formatDate,
    VoidCallback onRefresh) {
  final isSelected = allInstructors[idx].status == label;

  return GestureDetector(
    onTap: () {
      // I-set ang status ug i-record ang oras
      final timeStr = TimeOfDay.now().format(context);
      allInstructors[idx].status = label;
      allInstructors[idx].attendanceTime =
          '${formatDate()}  •  $timeStr';
      allInstructors[idx].remarks = remarksCtrl.text.trim().isEmpty
          ? null
          : remarksCtrl.text.trim();
      PersistenceService.saveAttendance(allInstructors);
      onRefresh();
      Navigator.pop(ctx);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isSelected ? color : color.withValues(alpha: 0.25)),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isSelected ? Colors.white : color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    ),
  );
}