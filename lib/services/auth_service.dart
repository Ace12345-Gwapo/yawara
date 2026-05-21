// ============================================================
// lib/services/auth_service.dart
// UPDATED: Admin credentials read from AppConfig — no
//          hardcoded strings in this file.
//          SA accounts stored in SQLite (local_database.dart).
//
// Public API is identical to the original — no screen changes needed.
// ============================================================

import 'dart:convert';
import '../config/app_config.dart';
import '../models/schedule.dart';
import 'local_database.dart';
import 'persistence_service.dart';

class AuthService {
  /// Hash password — same algorithm as original
  static String _hashPassword(String password) {
    return base64.encode(utf8.encode('tcgc_salt_$password'));
  }

  /// Register a new Student Assistant account
  static Future<bool> registerSA(String username, String password) async {
    // Block attempts to register as admin
    if (username.toLowerCase() == AppConfig.adminUsername.toLowerCase()) {
      return false;
    }

    // Check for existing account
    final existing = await LocalDatabase.getUser(username);
    if (existing != null) return false;

    await LocalDatabase.upsertUser({
      'username':      username,
      'password_hash': _hashPassword(password),
      'sync_status':   SyncStatus.pending.name,
    });
    return true;
  }

  /// Login — returns role string or null if credentials are invalid
  static Future<String?> login(String username, String password) async {
    // Admin check — credentials come from AppConfig, not hardcoded here
    if (username == AppConfig.adminUsername &&
        password == AppConfig.adminPassword) {
      return 'Admin';
    }

    final user = await LocalDatabase.getUser(username);
    if (user == null) return null;

    if (user['password_hash'] == _hashPassword(password)) {
      return 'Student Assistant';
    }
    return null;
  }

  /// Get list of all registered SA usernames (sorted)
  static Future<List<String>> getSAList() async {
    final usernames = await LocalDatabase.getAllSAUsernames();
    usernames.sort();
    return usernames;
  }

  /// Delete an SA account and unassign their schedules
  static Future<bool> deleteSA(String username) async {
    final existing = await LocalDatabase.getUser(username);
    if (existing == null) return false;

    await LocalDatabase.deleteUser(username);

    // Unassign from in-memory schedules and persist
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

  /// Change SA password
  static Future<bool> changePassword(
      String username, String oldPassword, String newPassword) async {
    final user = await LocalDatabase.getUser(username);
    if (user == null) return false;
    if (user['password_hash'] != _hashPassword(oldPassword)) return false;

    await LocalDatabase.updateUserField(
        username, 'password_hash', _hashPassword(newPassword));
    return true;
  }

  // ── Profile helpers ──────────────────────────────────────

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

  /// Save profile image as base64 string
  static Future<void> saveProfileImage(
      String username, String base64Image) async {
    await LocalDatabase.updateUserField(
        username, 'profile_img', base64Image);
  }

  static Future<String?> loadProfileImage(String username) async {
    return loadProfileField(username, 'profile_img');
  }
}