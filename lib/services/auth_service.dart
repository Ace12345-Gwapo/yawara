// ============================================================
// lib/services/auth_service.dart
// Nagdumala sa login, register, ug delete sa accounts
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/schedule.dart';
import 'persistence_service.dart';

class AuthService {
  // Hard-coded admin credentials
  static const String _adminUser = 'admin';
  static const String _adminPass = '123';

  /// I-hash ang password para dili makita sa plain text
  static String _hashPassword(String password) {
    return base64.encode(utf8.encode('tcgc_salt_$password'));
  }

  /// I-register ang bag-ong Student Assistant account
  static Future<bool> registerSA(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Dili pwede mag-register isip admin
    if (username.toLowerCase() == _adminUser) return false;

    // Tan-awa kung naay existing na account
    if (prefs.containsKey('sa_$username')) return false;

    await prefs.setString('sa_$username', _hashPassword(password));
    return true;
  }

  /// I-login ang user — ibalik ang role o null kung sayop
  static Future<String?> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Admin login check
    if (username == _adminUser && password == _adminPass) return 'Admin';

    // SA login check
    final savedHash = prefs.getString('sa_$username');

    // Tan-awa kung deleted na ang account — dili sila makalog-in
    if (savedHash == null) return null;

    if (savedHash == _hashPassword(password)) return 'Student Assistant';
    return null;
  }

  /// Kuhaa ang lista sa tanan nga registered SA
  static Future<List<String>> getSAList() async {
    final prefs = await SharedPreferences.getInstance();
    final saList = prefs
        .getKeys()
        .where((k) => k.startsWith('sa_') && !k.startsWith('sa_assign_'))
        .map((k) => k.substring(3))
        .toList()
      ..sort();
    return saList;
  }

  /// I-delete ang SA account — permanente, dili na sila makalog-in
  /// I-clear usab ang tanan nga entries nga gi-assign kanila
  static Future<bool> deleteSA(String username) async {
    final prefs = await SharedPreferences.getInstance();

    // Tan-awa kung naay account
    if (!prefs.containsKey('sa_$username')) return false;

    // Tangtanga ang account — dili na sila makalog-in
    await prefs.remove('sa_$username');

    // I-clear ang tanan nga profile data sa deleted SA
    await prefs.remove('profile_img_$username');
    await prefs.remove('profile_gmail_$username');
    await prefs.remove('profile_phone_$username');
    await prefs.remove('profile_address_$username');
    await prefs.remove('profile_bio_$username');

    // I-unassign ang tanan nga entries nga gi-assign sa deleted SA
    for (int i = 0; i < allInstructors.length; i++) {
      if (allInstructors[i].assignedSA == username) {
        allInstructors[i].assignedSA = null;
      }
    }
    // I-save ang updated entries
    await PersistenceService.saveAttendance(allInstructors);

    return true;
  }

  /// I-change ang password sa SA
  static Future<bool> changePassword(
      String username, String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString('sa_$username');
    if (savedHash == null) return false;
    if (savedHash != _hashPassword(oldPassword)) return false;
    await prefs.setString('sa_$username', _hashPassword(newPassword));
    return true;
  }
}