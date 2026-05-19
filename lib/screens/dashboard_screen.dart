// ============================================================
// lib/screens/dashboard_screen.dart
// FIX: History icon added — auto-saves to history when new day starts
//      and resets attendance for the fresh day.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';
import '../services/auth_service.dart';
import '../services/reset_utility.dart';
import '../services/history_service.dart';
import '../widgets/shift_manager.dart';
import '../widgets/schedule_card.dart';
import '../widgets/add_entry_dialog.dart';
import '../screens/login_screen.dart';
import '../screens/report_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sa_list_screen.dart';
import '../screens/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final String username;

  const DashboardScreen({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _green = Color(0xFF1B5E20);

  List<ClassSchedule> displayList = [];
  int _selectedShift = 0;
  String _searchVal  = '';
  Uint8List? _profileImageBytes;
  bool _showArchived = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() async {
    await PersistenceService.loadAttendance(allInstructors);
    await AuthService.getSAList();

    // ── Auto-save history and reset when a new day starts ──
    // On first load of a new day: save checked records to history,
    // then clear all attendance statuses so it's fresh for today.
    if (await HistoryService.shouldAutoSave()) {
      await HistoryService.saveToday(allInstructors);
      await ResetUtility.resetAll(allInstructors);
      await PersistenceService.saveAttendance(allInstructors);
    }

    await _loadProfileImage();
    if (!mounted) return;
    _refresh();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedBase64 = prefs.getString('profile_img_${widget.username}');
    setState(() {
      if (savedBase64 != null && savedBase64.isNotEmpty) {
        try {
          _profileImageBytes = base64Decode(savedBase64);
        } catch (_) {
          _profileImageBytes = null;
        }
      } else {
        _profileImageBytes = null;
      }
    });
  }

  bool _matchesSearch(ClassSchedule item) {
    if (_searchVal.isEmpty) return true;
    final q = _searchVal.toLowerCase().trim();
    return item.instructor.toLowerCase().contains(q) ||
        item.room.toLowerCase().contains(q) ||
        item.courseCode.toLowerCase().contains(q) ||
        item.subjectTitle.toLowerCase().contains(q) ||
        item.days.toLowerCase().contains(q) ||
        item.timeRange.toLowerCase().contains(q) ||
        item.building.toLowerCase().contains(q) ||
        (item.assignedSA?.toLowerCase().contains(q) ?? false);
  }

  void _refresh() {
    setState(() {
      displayList =
          ShiftManager.filterByShift(allInstructors, _selectedShift)
              .where((i) {
        final matchSearch  = _matchesSearch(i);
        final matchSA      = widget.userRole == 'Admin' ||
            i.assignedSA == widget.username;
        final bool matchArchive;
        if (widget.userRole == 'Admin') {
          matchArchive = _showArchived ? i.isArchived : !i.isArchived;
        } else {
          matchArchive =
              _showArchived ? i.isArchivedBySA : !i.isArchivedBySA;
        }
        return matchSearch && matchSA && matchArchive;
      }).toList();
    });
  }

  int get _presentCount =>
      displayList.where((i) => i.status == 'Present').length;
  int get _lateCount =>
      displayList.where((i) => i.status == 'Late').length;
  int get _absentCount =>
      displayList.where((i) => i.status == 'Absent').length;

  int _setCount(int set) {
    if (widget.userRole == 'Admin') {
      return allInstructors
          .where((i) => i.setNumber == set && !i.isArchived)
          .length;
    }
    return allInstructors
        .where((i) =>
            i.setNumber == set &&
            i.assignedSA == widget.username &&
            !i.isArchivedBySA)
        .length;
  }

  int get _archivedCount {
    if (widget.userRole == 'Admin') {
      return allInstructors.where((i) => i.isArchived).length;
    }
    return allInstructors
        .where((i) =>
            i.isArchivedBySA && i.assignedSA == widget.username)
        .length;
  }

  Color _setColor(int set) {
    if (set == 0) return const Color(0xFF1B5E20);
    if (set == 1) return const Color(0xFF1D4ED8);
    if (set == 2) return const Color(0xFF7C3AED);
    return Colors.grey;
  }

  String _getInitials() {
    final parts = widget.username
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return 'SA';
  }

  void _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (c) => ProfileScreen(username: widget.username)),
    );
    if (!mounted) return;
    _loadProfileImage();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Attendance',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will clear all attendance records. SA accounts will not be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ResetUtility.resetAll(allInstructors);
              if (!mounted) return;
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Attendance reset.'),
                    backgroundColor: Colors.orange),
              );
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin     = widget.userRole == 'Admin';
    final appBarColor = _showArchived ? Colors.blueGrey[800]! : _green;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showArchived
                  ? 'Archived Entries'
                  : isAdmin
                      ? 'Admin Panel'
                      : 'My Tasks',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              _showArchived
                  ? '$_archivedCount archived entries'
                  : isAdmin
                      ? 'Instructor Monitoring System'
                      : 'Welcome, ${widget.username}',
              style:
                  const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) =>
                      ReportScreen(schedules: allInstructors)),
            ),
          ),

          // ── History icon — Admin only ─────────────────
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Attendance History',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const HistoryScreen()),
              ),
            ),

          Stack(
            children: [
              IconButton(
                icon: Icon(_showArchived
                    ? Icons.inventory_2_rounded
                    : Icons.archive_outlined),
                tooltip:
                    _showArchived ? 'Show Active' : 'Show Archived',
                onPressed: () {
                  setState(() => _showArchived = !_showArchived);
                  _refresh();
                },
              ),
              if (_archivedCount > 0 && !_showArchived)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                    child: Text(
                      '$_archivedCount',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.people_rounded),
              tooltip: 'SA List',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => const SAListScreen()),
                );
                _refresh();
              },
            ),
            if (!_showArchived) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Entry',
                onPressed: () =>
                    showAddEntryDialog(context, _refresh),
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reset Attendance',
                onPressed: _showResetDialog,
              ),
            ],
          ],
          if (!isAdmin)
            GestureDetector(
              onTap: _goToProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.25),
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                      : null,
                  child: _profileImageBytes == null
                      ? Text(
                          _getInitials(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        )
                      : null,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => const LoginScreen()),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search bar ────────────────────────────────
          Container(
            color: appBarColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchVal = v);
                  _refresh();
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search instructor, room, course...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchVal.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchVal = '');
                            _refresh();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                ),
              ),
            ),
          ),

          if (_searchVal.isNotEmpty)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayList.isEmpty
                          ? 'No results for "$_searchVal"'
                          : '${displayList.length} result${displayList.length != 1 ? "s" : ""} for "$_searchVal"',
                      style: TextStyle(
                        fontSize: 12,
                        color: displayList.isEmpty
                            ? Colors.red[400]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchVal = '');
                      _refresh();
                    },
                    child: Text('Clear',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          if (!_showArchived)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildShiftTab('Face to Face', 0),
                          const SizedBox(width: 8),
                          _buildShiftTab('Online · Set 1', 1),
                          const SizedBox(width: 8),
                          _buildShiftTab('Online · Set 2', 2),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      children: [
                        _buildStatChip('Total',
                            displayList.length.toString(),
                            Colors.grey[600]!),
                        const SizedBox(width: 8),
                        _buildStatChip('Present',
                            _presentCount.toString(),
                            const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildStatChip('Late', _lateCount.toString(),
                            const Color(0xFFEA580C)),
                        const SizedBox(width: 8),
                        _buildStatChip('Absent',
                            _absentCount.toString(),
                            const Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (!_showArchived) const Divider(height: 1),

          if (_showArchived)
            Container(
              color: Colors.blueGrey[50],
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.blueGrey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAdmin
                          ? 'Swipe right to restore · Swipe left to delete permanently'
                          : 'Swipe right to restore your archived entries',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blueGrey[400]),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchVal.isNotEmpty
                              ? Icons.search_off_rounded
                              : _showArchived
                                  ? Icons.archive_outlined
                                  : Icons.inbox_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchVal.isNotEmpty
                              ? 'No results found'
                              : _showArchived
                                  ? 'No archived entries'
                                  : 'No entries found',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchVal.isNotEmpty
                              ? 'Try a different keyword'
                              : _showArchived
                                  ? 'Swipe right on active cards to archive'
                                  : isAdmin
                                      ? 'Tap + to add a new entry'
                                      : 'No tasks assigned yet',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                        if (_searchVal.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchVal = '');
                              _refresh();
                            },
                            icon: const Icon(Icons.close_rounded,
                                size: 16),
                            label: const Text('Clear Search'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              side: const BorderSide(color: _green),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: displayList.length,
                    itemBuilder: (c, i) => ScheduleCard(
                      item: displayList[i],
                      isAdmin: isAdmin,
                      currentUsername: widget.username,
                      onRefresh: _refresh,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
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

  Widget _buildShiftTab(String label, int shift) {
    final isActive = _selectedShift == shift;
    final color    = _setColor(shift);
    final count    = _setCount(shift);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedShift = shift);
        _refresh();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: isActive ? color : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color)),
            ),
          ],
        ),
      ),
    );
  }
}