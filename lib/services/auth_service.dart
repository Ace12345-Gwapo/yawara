// ============================================================
// lib/services/auth_service.dart
// UPDATED:
//   • Admin default password changed to '123456'
//   • Admin profile image stored in SQLite 'admin' row
//   • registerSA accepts optional email parameter
// ============================================================

import 'dart:convert';
import '../models/schedule.dart';
import 'local_database.dart';
import 'persistence_service.dart';

class AuthService {
  static const String _adminUser = 'admin';
  static const String _adminPass = '123456'; // updated default

  static String _hashPassword(String password) {
    return base64.encode(utf8.encode('tcgc_salt_$password'));
  }

  /// Register a new SA account.
  /// [email] is stored in the users table (optional but validated in UI).
  static Future<bool> registerSA(
    String username,
    String password, {
    String? email,
  }) async {
    if (username.toLowerCase() == _adminUser) return false;
    final existing = await LocalDatabase.getUser(username);
    if (existing != null) return false;

    await LocalDatabase.upsertUser({
      'username':      username,
      'password_hash': _hashPassword(password),
      'email':         email ?? '',
      'sync_status':   SyncStatus.pending.name,
    });
    return true;
  }

  /// Returns 'Admin', 'Student Assistant', or null.
  static Future<String?> login(String username, String password) async {
    if (username == _adminUser && password == _adminPass) {
      // Ensure admin row exists for profile storage
      await LocalDatabase.ensureAdminRow();
      return 'Admin';
    }

    final user = await LocalDatabase.getUser(username);
    if (user == null) return null;
    if (user['password_hash'] == _hashPassword(password)) {
      return 'Student Assistant';
    }
    return null;
  }

  static Future<List<String>> getSAList() async {
    final usernames = await LocalDatabase.getAllSAUsernames();
    usernames.sort();
    return usernames;
  }

  static Future<bool> deleteSA(String username) async {
    final existing = await LocalDatabase.getUser(username);
    if (existing == null) return false;
    await LocalDatabase.deleteUser(username);

    bool changed = false;
    for (final s in allInstructors) {
      if (s.assignedSA == username) {
        s.assignedSA = null;
        changed = true;
      }
    }
    if (changed) {
      await PersistenceService.saveAttendance(allInstructors);
    }
    return true;
  }

  static Future<bool> changePassword(
      String username, String oldPassword, String newPassword) async {
    final user = await LocalDatabase.getUser(username);
    if (user == null) return false;
    if (user['password_hash'] != _hashPassword(oldPassword)) return false;
    await LocalDatabase.updateUserField(
        username, 'password_hash', _hashPassword(newPassword));
    return true;
  }

  // ── Profile helpers (all via SQLite) ─────────────────────

  static Future<void> saveProfileField(
      String username, String field, String value) async {
    await LocalDatabase.updateUserField(username, field, value);
  }

  static Future<String?> loadProfileField(
      String username, String field) async {
    final user = await LocalDatabase.getUser(username);
    if (user == null) return null;
    return user[field] as String?;
  }

  static Future<void> saveProfileImage(
      String username, String base64Image) async {
    // Ensure the row exists (important for admin)
    final existing = await LocalDatabase.getUser(username);
    if (existing == null) {
      await LocalDatabase.upsertUser({
        'username':      username,
        'password_hash': '',
        'profile_img':   base64Image,
        'sync_status':   SyncStatus.synced.name,
      });
    } else {
      await LocalDatabase.updateUserField(
          username, 'profile_img', base64Image);
    }
  }

  static Future<String?> loadProfileImage(String username) async {
    return loadProfileField(username, 'profile_img');
  }
}