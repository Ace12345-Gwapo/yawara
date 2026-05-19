// ============================================================
// lib/widgets/schedule_card.dart
// Schedule card widget — ipakita ang matag instructor entry
//
// Archive rules:
//   isArchived     = Admin lang ang makaarchive — SA dili maka-affect
//   isArchivedBySA = SA lang ang makaarchive    — Admin dili maka-affect
//
// Admin: makakita sa isArchived entries, dili makakita sa isArchivedBySA
// SA:    makakita sa isArchivedBySA entries, dili makakita sa isArchived
//
// Edit: Admin lang — edit icon sa sulod sa card
// ============================================================

import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';
import 'status_picker_sheet.dart';
import 'assign_sa_sheet.dart';
import 'edit_entry_dialog.dart';

class ScheduleCard extends StatelessWidget {
  final ClassSchedule item;
  final bool isAdmin;
  final String currentUsername; // Kinahanglan para sa SA archive
  final VoidCallback onRefresh;

  const ScheduleCard({
    super.key,
    required this.item,
    required this.isAdmin,
    required this.currentUsername,
    required this.onRefresh,
  });

  // ── Color helpers ─────────────────────────────────────────

  Color _statusColor(String? s) {
    if (s == 'Present') return const Color(0xFF16A34A);
    if (s == 'Late') return const Color(0xFFEA580C);
    if (s == 'Absent') return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  IconData _statusIcon(String? s) {
    if (s == 'Present') return Icons.check_circle_rounded;
    if (s == 'Late') return Icons.timer_rounded;
    if (s == 'Absent') return Icons.cancel_rounded;
    return Icons.touch_app_rounded;
  }

  Color _setColor(int set) {
    if (set == 0) return const Color(0xFF1B5E20);
    if (set == 1) return const Color(0xFF1D4ED8);
    if (set == 2) return const Color(0xFF7C3AED);
    return Colors.grey;
  }

  String _setLabel(int set) {
    if (set == 0) return 'Face to Face';
    if (set == 1) return 'Online · Set 1';
    if (set == 2) return 'Online · Set 2';
    return 'Unknown';
  }

  IconData _setIcon(int set) =>
      set == 0 ? Icons.school_outlined : Icons.computer_outlined;

  // ── Determine archive state per role ─────────────────────
  // Admin: gamiton ang isArchived
  // SA:    gamiton ang isArchivedBySA
  bool get _isCurrentlyArchived =>
      isAdmin ? item.isArchived : item.isArchivedBySA;

  // ── Actions ───────────────────────────────────────────────

  /// I-delete ang entry — permanente (Admin only)
  void _deleteItem(BuildContext context) {
    final idx = allInstructors.indexOf(item);
    if (idx == -1) return;
    allInstructors.removeAt(idx);
    PersistenceService.saveAttendance(allInstructors);
    onRefresh();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.instructor} deleted.'),
        backgroundColor: Colors.red[700],
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            allInstructors.insert(idx, item);
            PersistenceService.saveAttendance(allInstructors);
            onRefresh();
          },
        ),
      ),
    );
  }

  /// I-archive ang entry
  /// Admin: i-set ang isArchived = true
  /// SA:    i-set ang isArchivedBySA = true — Admin dili maka-affect
  void _archiveItem(BuildContext context) {
    final idx = allInstructors.indexOf(item);
    if (idx == -1) return;

    if (isAdmin) {
      allInstructors[idx].isArchived = true;
    } else {
      // SA archive — separate sa Admin archive
      allInstructors[idx].isArchivedBySA = true;
    }

    PersistenceService.saveAttendance(allInstructors);
    onRefresh();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.instructor} archived.'),
        backgroundColor: Colors.blueGrey[700],
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            final i = allInstructors.indexOf(item);
            if (i != -1) {
              if (isAdmin) {
                allInstructors[i].isArchived = false;
              } else {
                allInstructors[i].isArchivedBySA = false;
              }
              PersistenceService.saveAttendance(allInstructors);
              onRefresh();
            }
          },
        ),
      ),
    );
  }

  /// I-unarchive (restore) ang entry
  /// Admin: i-set ang isArchived = false
  /// SA:    i-set ang isArchivedBySA = false
  void _unarchiveItem(BuildContext context) {
    final idx = allInstructors.indexOf(item);
    if (idx == -1) return;

    if (isAdmin) {
      allInstructors[idx].isArchived = false;
    } else {
      allInstructors[idx].isArchivedBySA = false;
    }

    PersistenceService.saveAttendance(allInstructors);
    onRefresh();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.instructor} restored.'),
        backgroundColor: const Color(0xFF1B5E20),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            final i = allInstructors.indexOf(item);
            if (i != -1) {
              if (isAdmin) {
                allInstructors[i].isArchived = true;
              } else {
                allInstructors[i].isArchivedBySA = true;
              }
              PersistenceService.saveAttendance(allInstructors);
              onRefresh();
            }
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final idx = allInstructors.indexOf(item);
    final statusColor = _statusColor(item.status);
    final archived = _isCurrentlyArchived;

    // ── Card content ──────────────────────────────────────
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: archived ? Colors.blueGrey[50] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: set label + status chip ────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Set label chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        _setColor(item.setNumber).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _setColor(item.setNumber)
                            .withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_setIcon(item.setNumber),
                          color: _setColor(item.setNumber), size: 11),
                      const SizedBox(width: 4),
                      Text(
                        _setLabel(item.setNumber),
                        style: TextStyle(
                            color: _setColor(item.setNumber),
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Admin only: Edit button — makita bisan archived
                    if (isAdmin)
                      GestureDetector(
                        onTap: () =>
                            showEditEntryDialog(context, idx, onRefresh),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Edit',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),

                    // Status / Check button
                    GestureDetector(
                      onTap: archived
                          ? null
                          : () => showStatusPickerSheet(
                              context, idx, onRefresh),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              archived ? Colors.grey[400] : statusColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: archived
                              ? []
                              : [
                                  BoxShadow(
                                      color: statusColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // SA archived: show archive icon
                            Icon(
                              archived
                                  ? Icons.archive_rounded
                                  : _statusIcon(item.status),
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              archived
                                  ? 'ARCHIVED'
                                  : (item.status ?? 'CHECK'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Instructor name
            Text(
              item.instructor,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),

            // Info tags
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (item.building.isNotEmpty)
                  _infoTag(Icons.tag, 'Sched', item.building),
                if (item.courseCode.isNotEmpty)
                  _infoTag(Icons.code, 'Course', item.courseCode),
                if (item.subjectTitle.isNotEmpty)
                  _infoTag(Icons.book, 'Title', item.subjectTitle),
                if (item.timeRange.isNotEmpty)
                  _infoTag(Icons.access_time, 'Time', item.timeRange),
                if (item.days.isNotEmpty)
                  _infoTag(Icons.calendar_today, 'Day', item.days),
                if (item.room.isNotEmpty)
                  _infoTag(Icons.room, 'Room', item.room,
                      color: const Color(0xFFDC2626)),
              ],
            ),

            // Remarks chip
            if (item.remarks != null && item.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note_alt_outlined,
                        size: 13, color: Colors.amber[700]),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(item.remarks!,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],

            // Attendance time chip
            if (item.status != null && item.attendanceTime != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled,
                        size: 12, color: statusColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text('Monitored: ${item.attendanceTime}',
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],

            // Admin-only: Assign SA section
            if (isAdmin && !archived) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showAssignSASheet(context, idx, onRefresh),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: item.assignedSA != null
                          ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                          : Colors.grey[100],
                      child: item.assignedSA != null
                          ? Text(
                              item.assignedSA!
                                  .trim()
                                  .split(' ')
                                  .where((w) => w.isNotEmpty)
                                  .map((w) => w[0].toUpperCase())
                                  .take(2)
                                  .join(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20)),
                            )
                          : Icon(Icons.person_add_outlined,
                              size: 14, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.assignedSA != null
                                ? 'Assigned SA — tap to update'
                                : 'No SA Assigned',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400]),
                          ),
                          Text(
                            item.assignedSA ?? 'Tap to assign',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item.assignedSA != null
                                    ? const Color(0xFF111827)
                                    : Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.grey[300], size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '← delete   archive →',
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey[300]),
                  ),
                ],
              ),
            ],

            // SA active swipe hint
            if (!isAdmin && !archived) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 11, color: Colors.grey[300]),
                  const SizedBox(width: 3),
                  Text('swipe right to archive',
                      style: TextStyle(
                          fontSize: 9, color: Colors.grey[300])),
                ],
              ),
            ],

            // Archived hint — restore
            if (archived) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.unarchive_outlined,
                      size: 11, color: Colors.grey[300]),
                  const SizedBox(width: 3),
                  Text(
                    isAdmin
                        ? 'swipe right to restore · left to delete'
                        : 'swipe right to restore',
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey[300]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    // ── Dismissible wrapping ──────────────────────────────

    // ARCHIVED view swipe
    if (archived) {
      return Dismissible(
        key: ValueKey(
            'archived_${isAdmin}_${item.instructor}_${item.room}'),
        direction: isAdmin
            ? DismissDirection.horizontal
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Delete Permanently',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(
                    'Delete ${item.instructor} permanently? This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return true; // Swipe right = restore
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteItem(context);
          } else {
            _unarchiveItem(context);
          }
        },
        background: _swipeBg(
            Alignment.centerLeft, const Color(0xFF1B5E20),
            Icons.unarchive_rounded, 'Restore'),
        secondaryBackground: _swipeBg(
            Alignment.centerRight, Colors.red[700]!,
            Icons.delete_rounded, 'Delete'),
        child: card,
      );
    }

    // ACTIVE view — SA: swipe right = archive only
    if (!isAdmin) {
      return Dismissible(
        key: ValueKey(
            'sa_active_${item.instructor}_${item.room}'),
        direction: DismissDirection.startToEnd,
        onDismissed: (_) => _archiveItem(context),
        background: _swipeBg(
            Alignment.centerLeft, const Color(0xFF4B5563),
            Icons.archive_rounded, 'Archive'),
        child: card,
      );
    }

    // ACTIVE view — Admin: right = archive, left = delete
    return Dismissible(
      key: ValueKey(
          'admin_active_${item.instructor}_${item.room}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Entry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                  'Delete ${item.instructor}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return true; // Swipe right = archive
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteItem(context);
        } else {
          _archiveItem(context);
        }
      },
      background: _swipeBg(Alignment.centerLeft,
          const Color(0xFF4B5563), Icons.archive_rounded, 'Archive'),
      secondaryBackground: _swipeBg(Alignment.centerRight,
          Colors.red[700]!, Icons.delete_rounded, 'Delete'),
      child: card,
    );
  }

  // ── Swipe background helper ───────────────────────────────
  Widget _swipeBg(
      AlignmentGeometry align, Color color, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(14)),
      alignment: align,
      padding: EdgeInsets.only(
        left: align == Alignment.centerLeft ? 20 : 0,
        right: align == Alignment.centerRight ? 20 : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String label, String value,
      {Color? color}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color ?? Colors.grey[400]),
        const SizedBox(width: 3),
        Text('$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        LimitedBox(
          maxWidth: 150,
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xFF374151))),
        ),
      ],
    );
  }
}