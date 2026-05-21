import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import 'local_database.dart';
import 'persistence_service.dart';
import 'sync_service.dart';

class AuthService {
  static const String _adminUser = 'admin';
  static const String _adminPass = '123456';

  static String _hashPassword(String password) {
    return base64.encode(utf8.encode('tcgc_salt_$password'));
  }

  static Future<bool> registerSA(
    String username,
    String password, {
    String? email,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('[AuthService] registerSA error: $e');
      return false;
    }
  }

  static Future<String?> login(String username, String password) async {
    try {
      if (username.toLowerCase() == _adminUser && password == _adminPass) {
        await LocalDatabase.ensureAdminRow();
        return 'Admin';
      }

      var user = await LocalDatabase.getUser(username);

      if (user == null && await SyncService.isOnline()) {
        try {
          await SyncService.pullUsersFromCloud();
          user = await LocalDatabase.getUser(username);
        } catch (e) {
          debugPrint('[AuthService] cloud user pull error: $e');
        }
      }

      if (user == null) return null;
      if (user['password_hash'] == _hashPassword(password)) {
        return 'Student Assistant';
      }
      return null;
    } catch (e) {
      debugPrint('[AuthService] login error: $e');
      return null;
    }
  }

  static Future<List<String>> getSAList() async {
    try {
      final usernames = await LocalDatabase.getAllSAUsernames();
      usernames.sort();
      return usernames;
    } catch (e) {
      debugPrint('[AuthService] getSAList error: $e');
      return [];
    }
  }

  static Future<bool> deleteSA(String username) async {
    try {
      final existing = await LocalDatabase.getUser(username);
      if (existing == null) return false;
      await LocalDatabase.deleteUser(username);

      if (await SyncService.isOnline()) {
        try {
          await SyncService.deleteUserFromCloud(username);
        } catch (e) {
          debugPrint('[AuthService] cloud delete error: $e');
        }
      }

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
    } catch (e) {
      debugPrint('[AuthService] deleteSA error: $e');
      return false;
    }
  }

  static Future<bool> changePassword(
      String username, String oldPassword, String newPassword) async {
    try {
      final user = await LocalDatabase.getUser(username);
      if (user == null) return false;
      if (user['password_hash'] != _hashPassword(oldPassword)) return false;
      await LocalDatabase.updateUserField(
          username, 'password_hash', _hashPassword(newPassword));
      return true;
    } catch (e) {
      debugPrint('[AuthService] changePassword error: $e');
      return false;
    }
  }

  static Future<void> saveProfileField(
      String username, String field, String value) async {
    try {
      await LocalDatabase.updateUserField(username, field, value);
    } catch (e) {
      debugPrint('[AuthService] saveProfileField error: $e');
    }
  }

  static Future<String?> loadProfileField(
      String username, String field) async {
    try {
      final user = await LocalDatabase.getUser(username);
      if (user == null) return null;
      return user[field] as String?;
    } catch (e) {
      debugPrint('[AuthService] loadProfileField error: $e');
      return null;
    }
  }

  static Future<void> saveProfileImage(
      String username, String base64Image) async {
    try {
      final existing = await LocalDatabase.getUser(username);
      if (existing == null) {
        await LocalDatabase.upsertUser({
          'username':      username,
          'password_hash': '',
          'profile_img':   base64Image,
          'sync_status':   SyncStatus.synced.name,
        });
      } else {
        await LocalDatabase.updateUserField(username, 'profile_img', base64Image);
      }
    } catch (e) {
      debugPrint('[AuthService] saveProfileImage error: $e');
    }
  }

  static Future<String?> loadProfileImage(String username) async {
    return loadProfileField(username, 'profile_img');
  }
}