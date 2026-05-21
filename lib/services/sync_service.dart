import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/schedule.dart';
import 'local_database.dart';
import 'supabase_service.dart';

class SyncService {

  static Future<bool> isOnline() async {
    try {
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is ConnectivityResult) {
        return result != ConnectivityResult.none;
      }
      if (result is List<ConnectivityResult>) {
        return result.isNotEmpty &&
            result.any((r) => r != ConnectivityResult.none);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> syncAll() async {
    if (!await isOnline()) return 'Offline — sync skipped';
    if (!await SupabaseService.isReachable()) return 'Cannot reach server';

    int schedSynced = 0, histSynced = 0, usersSynced = 0;
    final errors = <String>[];

    try { schedSynced = await _syncSchedules(); } catch (e) { errors.add('Schedules: $e'); }
    try { histSynced  = await _syncHistory();   } catch (e) { errors.add('History: $e');   }
    try { usersSynced = await _syncUsers();     } catch (e) { errors.add('Users: $e');     }

    if (errors.isNotEmpty) {
      debugPrint('[SyncService] errors: ${errors.join('; ')}');
      return 'Partial sync — ${errors.join('; ')}';
    }
    return 'Synced $schedSynced schedules, $histSynced history, $usersSynced users';
  }

  static Future<int> _syncSchedules() async {
    final pending = await LocalDatabase.getPendingSchedules();
    if (pending.isEmpty) return 0;

    final toDelete = pending.where((s) => s.syncStatus == SyncStatus.deleted).toList();
    final toUpsert = pending.where((s) => s.syncStatus != SyncStatus.deleted).toList();

    if (toUpsert.isNotEmpty) {
      final maps = toUpsert
          .where((s) => s.id != null)
          .map((s) => s.toSupabaseMap())
          .toList();
      if (maps.isNotEmpty) {
        final ok = await SupabaseService.upsert('schedules', maps, onConflict: 'id');
        if (ok) {
          for (final s in toUpsert) {
            if (s.id != null) await LocalDatabase.markSynced(s.id!);
          }
        }
      }
    }
    for (final s in toDelete) {
      if (s.id == null) continue;
      await SupabaseService.delete('schedules', 'id', s.id!);
      await LocalDatabase.deleteSchedule(s.id!);
    }
    return pending.length;
  }

  static Future<int> _syncHistory() async {
    final pending = await LocalDatabase.getPendingHistory();
    if (pending.isEmpty) return 0;

    final maps = pending.map((row) {
      final m = Map<String, dynamic>.from(row);
      m.remove('sync_status');
      return m;
    }).toList();

    final ok = await SupabaseService.upsert('history', maps, onConflict: 'id');
    if (ok) {
      await LocalDatabase.markHistorySynced(
          pending.map((r) => r['id'] as int).toList());
    }
    return pending.length;
  }

  static Future<int> _syncUsers() async {
    final pending = await LocalDatabase.getPendingUsers();
    if (pending.isEmpty) return 0;

    for (final user in pending) {
      final username = user['username'] as String;
      final payload  = <String, dynamic>{
        'username': username,
        'email':    user['email'],
        'gmail':    user['gmail'],
        'phone':    user['phone'],
        'address':  user['address'],
        'bio':      user['bio'],
      }..removeWhere((_, v) => v == null);

      final ok = await SupabaseService.upsert(
          'users', [payload], onConflict: 'username');
      if (ok) await LocalDatabase.markUserSynced(username);
    }
    return pending.length;
  }

  static Future<List<ClassSchedule>> pullSchedules() async {
    if (!await isOnline()) return [];
    try {
      final rows = await SupabaseService.select(
        'schedules',
        queryParams: ['order=id.asc'],
      );

      final schedules = <ClassSchedule>[];
      for (final row in rows) {
        try {
          final map = Map<String, dynamic>.from(row);
          map['is_archived']    = (map['is_archived']    == true) ? 1 : 0;
          map['is_archived_sa'] = (map['is_archived_sa'] == true) ? 1 : 0;
          map['sync_status']    = SyncStatus.synced.name;

          final s = ClassSchedule.fromSqliteMap(map);
          await LocalDatabase.upsertSchedule(s);
          schedules.add(s);
        } catch (e) {
          debugPrint('[SyncService] row parse error: $e');
        }
      }
      return schedules;
    } catch (e) {
      debugPrint('[SyncService] pullSchedules error: $e');
      return [];
    }
  }

  static Future<void> pullUsersFromCloud() async {
    if (!await isOnline()) return;
    try {
      final rows = await SupabaseService.select(
        'users',
        columns: 'username,email,gmail,phone,address,bio',
        queryParams: ['username=neq.admin'],
      );

      for (final row in rows) {
        final username = row['username'] as String?;
        if (username == null || username.isEmpty) continue;
        final existing = await LocalDatabase.getUser(username);
        if (existing == null) {
          await LocalDatabase.upsertUser({
            'username':      username,
            'password_hash': '',
            'email':         row['email']   ?? '',
            'gmail':         row['gmail']   ?? '',
            'phone':         row['phone']   ?? '',
            'address':       row['address'] ?? '',
            'bio':           row['bio']     ?? '',
            'sync_status':   SyncStatus.synced.name,
          });
        }
      }
    } catch (e) {
      debugPrint('[SyncService] pullUsersFromCloud error: $e');
    }
  }

  static Future<void> deleteUserFromCloud(String username) async {
    try {
      await SupabaseService.delete('users', 'username', username);
    } catch (e) {
      debugPrint('[SyncService] deleteUserFromCloud error: $e');
    }
  }
}