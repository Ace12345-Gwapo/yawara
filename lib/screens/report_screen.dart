// ============================================================
// lib/screens/report_screen.dart
// Attendance report screen — summary sa tanan nga checked entries
// ============================================================

import 'package:flutter/material.dart';
import '../models/schedule.dart';

class ReportScreen extends StatelessWidget {
  final List<ClassSchedule> schedules;
  const ReportScreen({super.key, required this.schedules});

  static const Color _green = Color(0xFF1B5E20);
  static const Color _presentColor = Color(0xFF16A34A);
  static const Color _lateColor = Color(0xFFEA580C);
  static const Color _absentColor = Color(0xFFDC2626);

  Color _statusColor(String? status) {
    switch (status) {
      case 'Present':
        return _presentColor;
      case 'Late':
        return _lateColor;
      case 'Absent':
        return _absentColor;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle_rounded;
      case 'Late':
        return Icons.timer_rounded;
      case 'Absent':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ipakita lang ang mga nay status (checked)
    final checked =
        schedules.where((s) => s.status != null && !s.isArchived).toList();
    final present = checked.where((s) => s.status == 'Present').length;
    final late = checked.where((s) => s.status == 'Late').length;
    final absent = checked.where((s) => s.status == 'Absent').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Report',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
            Text('Today\'s monitoring summary',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Summary stat cards ────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                _buildStatCard(
                    'Total', checked.length.toString(), Colors.grey[600]!),
                const SizedBox(width: 10),
                _buildStatCard('Present', present.toString(), _presentColor),
                const SizedBox(width: 10),
                _buildStatCard('Late', late.toString(), _lateColor),
                const SizedBox(width: 10),
                _buildStatCard('Absent', absent.toString(), _absentColor),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // ── Entries list ──────────────────────────────
          Expanded(
            child: checked.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No records yet',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 17,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Attendance checks will appear here',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: checked.length,
                    itemBuilder: (c, i) {
                      final item = checked[i];
                      final color = _statusColor(item.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                              left: BorderSide(color: color, width: 4)),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.instructor,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF111827)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                            color: color
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_statusIcon(item.status),
                                            color: Colors.white, size: 13),
                                        const SizedBox(width: 5),
                                        Text(
                                          item.status!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                children: [
                                  _buildDetail(Icons.code_rounded,
                                      item.courseCode),
                                  _buildDetail(Icons.book_outlined,
                                      item.subjectTitle),
                                  _buildDetail(Icons.room_rounded,
                                      item.room,
                                      color: _absentColor),
                                ],
                              ),
                              if (item.attendanceTime != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.07),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: color
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                          Icons
                                              .access_time_filled_rounded,
                                          size: 13,
                                          color: color),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Monitored: ${item.attendanceTime!}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: color,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (item.remarks != null &&
                                  item.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.amber[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.note_alt_outlined,
                                          size: 14,
                                          color: Colors.amber[700]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.remarks!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber[800],
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String value, {Color? color}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? Colors.grey[400]),
        const SizedBox(width: 4),
        LimitedBox(
          maxWidth: 160,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}