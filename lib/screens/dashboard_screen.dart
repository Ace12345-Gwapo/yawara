// ============================================================
// lib/screens/dashboard_screen.dart
// FULL REWRITE:
//   • Complete build() — no more placeholder
//   • Dark / Light mode toggle in AppBar
//   • Admin can upload profile picture via Drawer
//   • SA sees Archive toggle (was admin-only before)
//   • Auto-sync on resume
//   • All data loaded from SQLite (LocalDatabase)
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/schedule.dart';
import '../services/local_database.dart';
import '../services/auth_service.dart';
import '../services/reset_utility.dart';
import '../services/history_service.dart';
import '../services/sync_service.dart';
import '../services/theme_service.dart';
import '../widgets/shift_manager.dart';
import '../widgets/schedule_card.dart';
import '../widgets/add_entry_dialog.dart';
import 'login_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import 'sa_list_screen.dart';
import 'history_screen.dart';

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
    with WidgetsBindingObserver {
  static const _green = Color(0xFF1B5E20);

  List<ClassSchedule> displayList = [];
  int    _selectedShift = 0;
  String _searchVal     = '';
  bool   _showArchived  = false;
  bool   _showSearch    = false;
  bool   _isSyncing     = false;

  Uint8List? _profileImageBytes;
  bool _isPickingAdminImage = false;

  final _searchCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  bool get _isAdmin => widget.userRole == 'Admin';

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _triggerSync();
  }

  // ── Data ──────────────────────────────────────────────────

  Future<void> _loadData() async {
    // Pull from SQLite (offline-first)
    final loaded = await LocalDatabase.loadAllSchedules();
    allInstructors.clear();
    allInstructors.addAll(loaded);

    await AuthService.getSAList();

    if (await HistoryService.shouldAutoSave()) {
      await HistoryService.saveToday(allInstructors);
      await ResetUtility.resetAll(allInstructors);
    }

    await _loadProfileImage();
    _triggerSync();

    if (!mounted) return;
    _refresh();
  }

  Future<void> _loadProfileImage() async {
    final b64 = await AuthService.loadProfileImage(widget.username);
    if (!mounted) return;
    setState(() {
      if (b64 != null && b64.isNotEmpty) {
        try {
          _profileImageBytes = base64Decode(b64);
        } catch (_) {
          _profileImageBytes = null;
        }
      } else {
        _profileImageBytes = null;
      }
    });
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await SyncService.syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  // ── Admin profile image upload ────────────────────────────

  Future<void> _pickAdminImage() async {
    if (_isPickingAdminImage) return;
    setState(() => _isPickingAdminImage = true);
    try {
      final XFile? picked =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _isPickingAdminImage = false);
        return;
      }
      final bytes   = await picked.readAsBytes();
      final b64     = base64Encode(bytes);
      await AuthService.saveProfileImage(widget.username, b64);
      if (!mounted) return;
      setState(() {
        _profileImageBytes  = bytes;
        _isPickingAdminImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated!'),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickingAdminImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Filtering ─────────────────────────────────────────────

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
    final filtered = allInstructors.where((item) {
      if (!ShiftManager.matchesShift(item, _selectedShift)) return false;
      if (!_matchesSearch(item)) return false;
      if (_isAdmin) {
        return _showArchived ? item.isArchived : !item.isArchived;
      } else {
        if (item.assignedSA != widget.username) return false;
        return _showArchived ? item.isArchivedBySA : !item.isArchivedBySA;
      }
    }).toList();
    setState(() => displayList = filtered);
  }

  // ── Stats ─────────────────────────────────────────────────

  int get _presentCount =>
      displayList.where((s) => s.status == 'Present').length;
  int get _lateCount =>
      displayList.where((s) => s.status == 'Late').length;
  int get _absentCount =>
      displayList.where((s) => s.status == 'Absent').length;
  int get _uncheckedCount =>
      displayList.where((s) => s.status == null).length;

  // ── Helpers ───────────────────────────────────────────────

  String _getInitials(String name) {
    final parts =
        name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      drawer: _buildDrawer(isDark),
      body: Column(
        children: [
          _buildShiftTabs(isDark),
          if (_showSearch) _buildSearchBar(),
          if (_isAdmin && !_showArchived) _buildStatBar(isDark),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: _isAdmin && !_showArchived ? _buildFab() : null,
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: _green,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TCGC Monitoring',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _showArchived
                      ? '${widget.userRole} · Archive'
                      : widget.userRole,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    color: Colors.white60, strokeWidth: 2),
              ),
            ),
        ],
      ),
      actions: [
        // Search
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchVal = '';
                _searchCtrl.clear();
                _refresh();
              }
            });
          },
        ),
        // Archive toggle — visible to BOTH Admin and SA
        IconButton(
          icon: Icon(
            _showArchived ? Icons.inventory_2 : Icons.archive_outlined,
            color: _showArchived ? Colors.amber : Colors.white,
          ),
          tooltip: _showArchived ? 'Show Active' : 'Show Archived',
          onPressed: () {
            setState(() => _showArchived = !_showArchived);
            _refresh();
          },
        ),
        // Report (admin only)
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ReportScreen(schedules: allInstructors)),
            ),
          ),
        // Dark mode toggle
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeMode,
          builder: (_, mode, __) => IconButton(
            icon: Icon(
              mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: mode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => ThemeService.toggle(),
          ),
        ),
        // Profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: _isAdmin
                ? _pickAdminImage
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(username: widget.username)),
                    ).then((_) => _loadProfileImage()),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.25),
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                      : null,
                  child: _profileImageBytes == null
                      ? Text(
                          _getInitials(widget.username),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        )
                      : null,
                ),
                if (_isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 8, color: _green),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Drawer ────────────────────────────────────────────────

  Widget _buildDrawer(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Drawer(
      backgroundColor: cardBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(color: _green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _isAdmin ? _pickAdminImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.25),
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : null,
                        child: _profileImageBytes == null
                            ? Text(
                                _getInitials(widget.username),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      if (_isAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _green, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 10, color: _green),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Text(
                  widget.userRole,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Admin — Update Profile Photo
          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _green),
              title: const Text('Update Profile Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAdminImage();
              },
            ),

          // SA — My Profile
          if (!_isAdmin)
            ListTile(
              leading: const Icon(Icons.person_outline, color: _green),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProfileScreen(username: widget.username)),
                ).then((_) => _loadProfileImage());
              },
            ),

          // Admin — SA list & History
          if (_isAdmin) ...[
            ListTile(
              leading:
                  const Icon(Icons.people_outline, color: _green),
              title: const Text('Student Assistants'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SAListScreen()),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.history_rounded, color: _green),
              title: const Text('Attendance History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.bar_chart_rounded, color: _green),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ReportScreen(schedules: allInstructors)),
                );
              },
            ),
          ],

          // Dark mode toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeMode,
            builder: (_, mode, __) => ListTile(
              leading: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: _green,
              ),
              title: Text(
                mode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
              ),
              onTap: () {
                ThemeService.toggle();
              },
            ),
          ),

          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  // ── Shift tabs ────────────────────────────────────────────

  Widget _buildShiftTabs(bool isDark) {
    const labels = ['Face to Face', 'Online Set 1', 'Online Set 2'];
    const colors = [
      Color(0xFF1B5E20),
      Color(0xFF1D4ED8),
      Color(0xFF7C3AED),
    ];
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final selected = _selectedShift == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedShift = i);
                  _refresh();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors[i]
                        : colors[i].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors[i]
                          .withValues(alpha: selected ? 0 : 0.3),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : colors[i],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search instructor, subject, room…',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          suffixIcon: _searchVal.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchVal = '');
                    _refresh();
                  },
                )
              : null,
        ),
        onChanged: (v) {
          setState(() => _searchVal = v);
          _refresh();
        },
      ),
    );
  }

  // ── Stat bar ──────────────────────────────────────────────

  Widget _buildStatBar(bool isDark) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        children: [
          _statChip('Present', _presentCount, const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          _statChip('Late', _lateCount, const Color(0xFFEA580C)),
          const SizedBox(width: 6),
          _statChip('Absent', _absentCount, const Color(0xFFDC2626)),
          const SizedBox(width: 6),
          _statChip('Unchecked', _uncheckedCount, Colors.grey),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 9, color: color, height: 1.2)),
          ],
        ),
      ),
    );
  }

  // ── Schedule list ─────────────────────────────────────────

  Widget _buildList() {
    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showArchived
                  ? Icons.inventory_2_outlined
                  : Icons.event_note_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _showArchived
                  ? 'No archived entries'
                  : 'No schedules found',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            if (_isAdmin && !_showArchived) ...[
              const SizedBox(height: 6),
              Text(
                'Tap + to add a new schedule',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
        itemCount: displayList.length,
        itemBuilder: (_, i) => ScheduleCard(
          item:            displayList[i],
          isAdmin:         _isAdmin,
          currentUsername: widget.username,
          onRefresh:       _refresh,
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Entry'),
      onPressed: () => showAddEntryDialog(context, _refresh),
    );
  }
}