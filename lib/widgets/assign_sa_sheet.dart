// ============================================================
// lib/widgets/assign_sa_sheet.dart
// Bottom sheet para i-assign (o i-update) ang SA sa usa ka entry
// Pwede ra gamiton ang Admin — pwede usab mag-update kung sayop
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/auth_service.dart';
import '../services/persistence_service.dart';

/// I-show ang assign SA bottom sheet
/// Pwede gamiton para sa unang assign o para mag-update/correct
void showAssignSASheet(
    BuildContext context, int idx, VoidCallback onRefresh) async {
  final saList = await AuthService.getSAList();
  if (!context.mounted) return;

  if (saList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No Student Assistants registered yet.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // I-load ang profile images sa tanan nga SA
  final prefs = await SharedPreferences.getInstance();
  final Map<String, Uint8List?> saImages = {};
  for (final sa in saList) {
    final savedBase64 = prefs.getString('profile_img_$sa');
    if (savedBase64 != null && savedBase64.isNotEmpty) {
      try {
        saImages[sa] = base64Decode(savedBase64);
      } catch (_) {
        saImages[sa] = null;
      }
    } else {
      saImages[sa] = null;
    }
  }

  if (!context.mounted) return;

  const green = Color(0xFF1B5E20);
  final currentAssigned = allInstructors[idx].assignedSA;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
          const SizedBox(height: 14),

          // Header — ipakita kung naa nay assign para klaro nga pwede mag-update
          Row(
            children: [
              const Icon(Icons.people_outline, color: green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Kung naay assign na, ipakita "Update Assignment"
                      currentAssigned != null
                          ? 'Update Assignment'
                          : 'Assign Student Assistant',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      allInstructors[idx].instructor,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Ipakita ang currently assigned SA
                    if (currentAssigned != null)
                      Text(
                        'Current: $currentAssigned',
                        style: const TextStyle(
                            fontSize: 11,
                            color: green,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),

          // SA List — pilia ang bag-ong SA o i-unassign
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: saList.length + 1,
              itemBuilder: (c, i) {
                // Unna nga option: Unassigned
                if (i == 0) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[100],
                      child: Icon(Icons.person_off_outlined,
                          color: Colors.grey[400], size: 20),
                    ),
                    title: const Text('Unassigned',
                        style: TextStyle(color: Colors.grey)),
                    trailing:
                        allInstructors[idx].assignedSA == null
                            ? const Icon(Icons.check_circle, color: green)
                            : null,
                    onTap: () {
                      // I-unassign — tangtangon ang SA
                      allInstructors[idx].assignedSA = null;
                      PersistenceService.saveAttendance(allInstructors);
                      onRefresh();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SA unassigned.'),
                          backgroundColor: Colors.blueGrey,
                        ),
                      );
                    },
                  );
                }

                final sa = saList[i - 1];
                final isSelected = allInstructors[idx].assignedSA == sa;
                final imageBytes = saImages[sa];
                final initials = sa
                    .trim()
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .map((w) => w[0].toUpperCase())
                    .take(2)
                    .join();

                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: isSelected
                        ? green
                        : green.withValues(alpha: 0.1),
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes)
                        : null,
                    child: imageBytes == null
                        ? Text(initials,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : green))
                        : null,
                  ),
                  title: Text(sa,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Student Assistant',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400])),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: green)
                      : const Icon(Icons.chevron_right,
                          color: Colors.grey),
                  // I-assign o i-update ang SA para sa entry
                  onTap: () {
                    allInstructors[idx].assignedSA = sa;
                    PersistenceService.saveAttendance(allInstructors);
                    onRefresh();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Assigned to $sa'),
                        backgroundColor: green,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}