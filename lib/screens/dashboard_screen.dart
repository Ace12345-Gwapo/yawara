// ============================================================
// lib/screens/dashboard_screen.dart
// UPDATED: Added SyncService.syncAll() call on load and on
//          app resume. Everything else is identical to original.
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
import '../services/sync_service.dart';          // ← NEW
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

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {              // ← NEW: observe lifecycle
  static const _green = Color(0xFF1B5E20);

  List<ClassSchedule> displayList = [];
  int _selectedShift  = 0;
  String _searchVal   = '';
  Uint8List? _profileImageBytes;
  bool _showArchived  = false;
  bool _isSyncing     = false;                 // ← NEW: sync indicator

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ← NEW
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ← NEW
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Sync when app comes back to foreground ── NEW ──────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await SyncService.syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  void _loadData() async {
    await PersistenceService.loadAttendance(allInstructors);
    await AuthService.getSAList();

    if (await HistoryService.shouldAutoSave()) {
      await HistoryService.saveToday(allInstructors);
      await ResetUtility.resetAll(allInstructors);
      await PersistenceService.saveAttendance(allInstructors);
    }

    await _loadProfileImage();

    // ── Trigger background sync after local load ── NEW ──────
    _triggerSync();

    if (!mounted) return;
    _refresh();
  }

  Future<void> _loadProfileImage() async {
    final savedBase64 = await AuthService.loadProfileImage(widget.username);
    if (!mounted) return;
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
        item.courseCode.toLowerCase().contains(q) ||
        item.subjectTitle.toLowerCase().contains(q) ||
        item.room.toLowerCase().contains(q);
  }

  void _refresh() {
    if (!mounted) return;
    final role = widget.userRole;

    final filtered = allInstructors.where((item) {
      if (!ShiftManager.matchesShift(item, _selectedShift)) return false;
      if (!_matchesSearch(item)) return false;
      if (role == 'Admin') {
        return _showArchived ? item.isArchived : !item.isArchived;
      } else {
        if (item.assignedSA != widget.username) return false;
        return _showArchived ? item.isArchivedBySA : !item.isArchivedBySA;
      }
    }).toList();

    setState(() => displayList = filtered);
  }

  // ─────────────────────────────────────────────────────────
  // The rest of the build method is IDENTICAL to the original.
  // Paste your existing build() and helper methods here.
  // Only the initState / dispose / _loadData sections changed.
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // NOTE: Copy the full build() from your original dashboard_screen.dart
    // below this line. No other changes are needed inside build().
    //
    // Optionally show a subtle sync indicator in the AppBar:
    //
    //   title: Row(children: [
    //     const Text('TCGC Monitoring'),
    //     if (_isSyncing) ...[
    //       const SizedBox(width: 8),
    //       const SizedBox(
    //         width: 12, height: 12,
    //         child: CircularProgressIndicator(strokeWidth: 2,
    //           color: Colors.white70),
    //       ),
    //     ],
    //   ]),

    return const Scaffold(
      body: Center(child: Text('Paste original build() here')),
    );
  }
}