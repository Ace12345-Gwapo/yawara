// ============================================================
// lib/screens/sa_list_screen.dart
// Lista sa tanan nga Student Assistants
// Admin makakita ug makaDelete sa SA accounts — permanente
// Kung ma-delete ang SA, dili na sila makalog-in
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

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

  /// I-load ang datos sa tanan nga SA para sa list
  void _loadSAData() async {
    final prefs = await SharedPreferences.getInstance();
    final saList = await AuthService.getSAList();
    final List<Map<String, dynamic>> data = [];

    for (final sa in saList) {
      final savedBase64 = prefs.getString('profile_img_$sa');
      Uint8List? imageBytes;
      if (savedBase64 != null && savedBase64.isNotEmpty) {
        try {
          imageBytes = base64Decode(savedBase64);
        } catch (_) {
          imageBytes = null;
        }
      }
      data.add({
        'name': sa,
        'image': imageBytes,
        'gmail': prefs.getString('profile_gmail_$sa') ?? '',
        'phone': prefs.getString('profile_phone_$sa') ?? '',
        'address': prefs.getString('profile_address_$sa') ?? '',
        'bio': prefs.getString('profile_bio_$sa') ?? '',
      });
    }

    if (!mounted) return;
    setState(() {
      _saData = data;
      _loading = false;
    });
  }

  /// I-show ang delete confirmation dialog para sa SA account
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
            const Text('Are you sure you want to permanently delete the account of:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sa['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Warning message
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This SA will no longer be able to log in. '
                      'Their assigned entries will be unassigned.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever, color: Colors.white, size: 16),
            label: const Text('Delete Account',
                style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              // I-delete ang SA account — i-clear usab ang assignments
              final ok = await AuthService.deleteSA(sa['name']);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${sa['name']} account deleted.'),
                    backgroundColor: Colors.red[700],
                  ),
                );
                // I-refresh ang list
                setState(() => _loading = true);
                _loadSAData();
              }
            },
          ),
        ],
      ),
    );
  }

  /// I-show ang SA detail bottom sheet
  void _showSADetail(Map<String, dynamic> sa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: ListView(
            controller: controller,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // SA Avatar
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _green.withValues(alpha: 0.12),
                  backgroundImage: sa['image'] != null
                      ? MemoryImage(sa['image'] as Uint8List)
                      : null,
                  child: sa['image'] == null
                      ? Text(
                          _getInitials(sa['name']),
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _green),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // SA name
              Center(
                child: Text(
                  sa['name'],
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _green.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Student Assistant',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _green),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              // SA profile info
              if ((sa['bio'] as String).isNotEmpty) ...[
                _buildDetailRow(Icons.info_outline, 'Bio', sa['bio']),
                const SizedBox(height: 12),
              ],
              if ((sa['gmail'] as String).isNotEmpty) ...[
                _buildDetailRow(
                    Icons.email_outlined, 'Gmail', sa['gmail']),
                const SizedBox(height: 12),
              ],
              if ((sa['phone'] as String).isNotEmpty) ...[
                _buildDetailRow(
                    Icons.phone_outlined, 'Phone', sa['phone']),
                const SizedBox(height: 12),
              ],
              if ((sa['address'] as String).isNotEmpty) ...[
                _buildDetailRow(
                    Icons.location_on_outlined, 'Address', sa['address']),
                const SizedBox(height: 12),
              ],
              if ((sa['bio'] as String).isEmpty &&
                  (sa['gmail'] as String).isEmpty &&
                  (sa['phone'] as String).isEmpty &&
                  (sa['address'] as String).isEmpty)
                Center(
                  child: Text(
                    'No personal information added yet.',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 13),
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Delete account button — permanent deletion
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: const Text(
                    'Delete Account Permanently',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close detail sheet first
                    _confirmDeleteSA(sa); // Then show confirm dialog
                  },
                ),
              ),
            ],
          ),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
            onPressed: () {
              setState(() => _loading = true);
              _loadSAData();
            },
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
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: _saData.length,
                  itemBuilder: (c, i) {
                    final sa = _saData[i];
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
                                color: Colors.black.withValues(alpha: 0.04),
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
                                fontSize: 12, color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quick delete button para sa admin
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                tooltip: 'Delete Account',
                                onPressed: () => _confirmDeleteSA(sa),
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