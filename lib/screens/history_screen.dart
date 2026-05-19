// ============================================================
// lib/screens/history_screen.dart
// Shows saved daily attendance records — one section per day.
// Accessible via the history icon in the Admin AppBar.
// ============================================================

import 'package:flutter/material.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _green        = Color(0xFF1B5E20);
  static const _presentColor = Color(0xFF16A34A);
  static const _lateColor    = Color(0xFFEA580C);
  static const _absentColor  = Color(0xFFDC2626);

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  // Track which days are expanded
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await HistoryService.loadAllHistory();
    if (!mounted) return;
    setState(() {
      _history = data;
      _loading = false;
      // Auto-expand the first (most recent) entry
      if (data.isNotEmpty) _expanded.add(data.first['date'] as String);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present': return _presentColor;
      case 'Late':    return _lateColor;
      case 'Absent':  return _absentColor;
      default:        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Present': return Icons.check_circle_rounded;
      case 'Late':    return Icons.timer_rounded;
      case 'Absent':  return Icons.cancel_rounded;
      default:        return Icons.help_outline_rounded;
    }
  }

  // Format "2025-01-15" → "Wednesday, January 15, 2025"
  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months   = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // Summary counts for a day
  Map<String, int> _counts(List records) {
    int present = 0, late = 0, absent = 0;
    for (final r in records) {
      final s = r['status'] as String? ?? '';
      if (s == 'Present') present++;
      else if (s == 'Late') late++;
      else if (s == 'Absent') absent++;
    }
    return {'present': present, 'late': late, 'absent': absent};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              '${_history.length} day${_history.length != 1 ? "s" : ""} recorded',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All History',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  itemCount: _history.length,
                  itemBuilder: (c, i) => _buildDayCard(_history[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No history yet',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Past daily records will appear here',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final dateStr = day['date'] as String;
    final records = day['records'] as List;
    final counts  = _counts(records);
    final isOpen  = _expanded.contains(dateStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Day header — tap to expand/collapse ───────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              if (isOpen) _expanded.remove(dateStr);
              else _expanded.add(dateStr);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: _green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatDate(dateStr),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF111827))),
                        const SizedBox(height: 4),
                        // Summary chips
                        Row(
                          children: [
                            _miniChip('${records.length}', Colors.grey[600]!, 'Total'),
                            const SizedBox(width: 6),
                            _miniChip('${counts['present']}', _presentColor, 'Present'),
                            const SizedBox(width: 6),
                            _miniChip('${counts['late']}', _lateColor, 'Late'),
                            const SizedBox(width: 6),
                            _miniChip('${counts['absent']}', _absentColor, 'Absent'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // ── Records list — shown when expanded ────────
          if (isOpen) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            ...records.map((r) => _buildRecordRow(r as Map<String, dynamic>)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordRow(Map<String, dynamic> r) {
    final status    = r['status'] as String? ?? '';
    final color     = _statusColor(status);
    final timeStr   = r['attendanceTime'] as String? ?? '';
    final remarks   = r['remarks'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(r['instructor'] as String? ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF111827))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status),
                          color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text(status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r['courseCode']}  •  ${r['room']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(timeStr,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Note: $remarks',
                  style: TextStyle(
                      fontSize: 11, color: Colors.amber[700])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently delete all saved attendance history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await HistoryService.clearAll();
              if (!mounted) return;
              setState(() {
                _history = [];
                _expanded.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('History cleared.'),
                    backgroundColor: Colors.red),
              );
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}