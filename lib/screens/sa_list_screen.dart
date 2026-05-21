// ============================================================
// lib/screens/sa_list_screen.dart
// REWRITTEN: All SharedPreferences calls replaced with
//            LocalDatabase (SQLite) via AuthService.
//            No more `import shared_preferences`.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/local_database.dart';

class SAListScreen extends StatefulWidget {
  const SAListScreen({super.key});

  @override
  State<SAListScreen> createState() => _SAListScreenState();
}

class _SAListScreenState extends State<SAListScreen> {
  static const _green = Color(0xFF1B5E20);
  List<Map<String, dynamic>> _saData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSAData();
  }

  /// Load SA data from SQLite via LocalDatabase
  void _loadSAData() async {
    setState(() => _loading = true);

    final saList = await AuthService.getSAList();
    final List<Map<String, dynamic>> data = [];

    for (final username in saList) {
      // Each SA's profile fields live in the `users` SQLite table
      final row = await LocalDatabase.getUser(username);

      Uint8List? imageBytes;
      final imgB64 = row?['profile_img'] as String?;
      if (imgB64 != null && imgB64.isNotEmpty) {
        try {
          imageBytes = base64Decode(imgB64);
        } catch (_) {
          imageBytes = null;
        }
      }

      data.add({
        'name':    username,
        'image':   imageBytes,
        'gmail':   row?['gmail']   ?? '',
        'phone':   row?['phone']   ?? '',
        'address': row?['address'] ?? '',
        'bio':     row?['bio']     ?? '',
      });
    }

    if (!mounted) return;
    setState(() {
      _saData  = data;
      _loading = false;
    });
  }

  // ── Delete confirmation ───────────────────────────────────

  void _confirmDeleteSA(Map<String, dynamic> sa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete SA Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Are you sure you want to permanently delete the account of:'),
            const SizedBox(height: 10),
            Text(
              sa['name'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will also unassign them from all schedules. '
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.deleteSA(sa['name']);
              _loadSAData();
            },
          ),
        ],
      ),
    );
  }

  // ── SA detail sheet ───────────────────────────────────────

  void _showSADetail(Map<String, dynamic> sa) {
    final imageBytes = sa['image'] as Uint8List?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: _green.withValues(alpha: 0.12),
              backgroundImage:
                  imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null
                  ? Text(
                      _getInitials(sa['name']),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _green),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              sa['name'],
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Student Assistant',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green),
              ),
            ),
            const SizedBox(height: 24),

            if ((sa['bio'] as String).isNotEmpty) ...[
              Text(
                sa['bio'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
            ],

            if ((sa['gmail'] as String).isNotEmpty)
              _buildDetailRow(
                  Icons.email_outlined, 'Gmail', sa['gmail']),
            if ((sa['phone'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                  Icons.phone_outlined, 'Phone', sa['phone']),
            ],
            if ((sa['address'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(Icons.location_on_outlined, 'Address',
                  sa['address']),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Account'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSA(sa);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _green, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts =
        name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return 'SA';
  }

  // ── Build ─────────────────────────────────────────────────

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
            const Text(
              'Student Assistants',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${_saData.length} registered',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSAData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No Student Assistants yet',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Registered SAs will appear here',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: _saData.length,
                  itemBuilder: (c, i) {
                    final sa         = _saData[i];
                    final imageBytes = sa['image'] as Uint8List?;
                    return GestureDetector(
                      onTap: () => _showSADetail(sa),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                _green.withValues(alpha: 0.12),
                            backgroundImage: imageBytes != null
                                ? MemoryImage(imageBytes)
                                : null,
                            child: imageBytes == null
                                ? Text(
                                    _getInitials(sa['name']),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _green),
                                  )
                                : null,
                          ),
                          title: Text(
                            sa['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF111827)),
                          ),
                          subtitle: Text(
                            (sa['bio'] as String).isNotEmpty
                                ? sa['bio']
                                : (sa['gmail'] as String).isNotEmpty
                                    ? sa['gmail']
                                    : 'No info added yet',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20),
                                tooltip: 'Delete Account',
                                onPressed: () =>
                                    _confirmDeleteSA(sa),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}