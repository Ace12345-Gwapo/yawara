import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/persistence_service.dart';
import '../services/theme_service.dart';

class SAArchiveScreen extends StatefulWidget {
  final String username;
  final VoidCallback onRefresh;

  const SAArchiveScreen({
    super.key,
    required this.username,
    required this.onRefresh,
  });

  @override
  State<SAArchiveScreen> createState() => _SAArchiveScreenState();
}

class _SAArchiveScreenState extends State<SAArchiveScreen> {
  static const _green = Color(0xFF1B5E20);

  List<ClassSchedule> _archived = [];

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  void _loadArchived() {
    setState(() {
      _archived = allInstructors
          .where((s) =>
              s.assignedSA == widget.username && s.isArchivedBySA)
          .toList();
    });
  }

  Future<void> _restore(ClassSchedule item) async {
    final idx = allInstructors.indexOf(item);
    if (idx == -1) return;
    allInstructors[idx].isArchivedBySA = false;
    await PersistenceService.saveAttendance(allInstructors);
    widget.onRefresh();
    _loadArchived();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.instructor} restored.'),
        backgroundColor: _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Archive'),
            backgroundColor: const Color(0xFF4B5563),
          ),
          body: _archived.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _archived.length,
                  itemBuilder: (_, i) =>
                      _buildCard(_archived[i], isDark),
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No archived entries',
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Swipe cards left on the dashboard to archive them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ClassSchedule item, bool isDark) {
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Dismissible(
      key: ValueKey('archive_${item.instructor}_${item.room}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => _restore(item),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.unarchive_rounded,
                color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Restore',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(
              left: BorderSide(
                  color: Colors.grey.shade400, width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.instructor,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.courseCode} · ${item.subjectTitle}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.room} · ${item.timeRange} · ${item.days}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.unarchive_outlined,
                    color: _green),
                tooltip: 'Restore',
                onPressed: () => _restore(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}