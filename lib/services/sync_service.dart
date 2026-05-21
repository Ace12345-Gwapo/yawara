import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';
import 'local_database.dart';

class SyncService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static const _timeout = Duration(seconds: 12);

  static Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  static Future<String> syncAll() async {
    if (!await isOnline()) return 'Offline — sync skipped';

    int schedSynced = 0;
    int histSynced  = 0;
    int usersSynced = 0;
    final errors    = <String>[];

    try { schedSynced = await _syncSchedules(); }
    catch (e) { errors.add('Schedules: $e'); }

    try { histSynced = await _syncHistory(); }
    catch (e) { errors.add('History: $e'); }

    try { usersSynced = await _syncUsers(); }
    catch (e) { errors.add('Users: $e'); }

    if (errors.isNotEmpty) {
      return 'Partial sync — errors: ${errors.join('; ')}';
    }
    return 'Synced: $schedSynced schedules, $histSynced history, $usersSynced users';
  }

  static Future<int> _syncSchedules() async {
    final pending = await LocalDatabase.getPendingSchedules();
    if (pending.isEmpty) return 0;

    final toDelete = pending
        .where((s) => s.syncStatus == SyncStatus.deleted)
        .toList();
    final toUpsert = pending
        .where((s) => s.syncStatus != SyncStatus.deleted)
        .toList();

    if (toUpsert.isNotEmpty) {
      final maps = toUpsert
          .where((s) => s.id != null)
          .map((s) => s.toSupabaseMap())
          .toList();
      if (maps.isNotEmpty) {
        await _supabase.from('schedules').upsert(maps).timeout(_timeout);
        for (final s in toUpsert) {
          if (s.id != null) await LocalDatabase.markSynced(s.id!);
        }
      }
    }

    for (final s in toDelete) {
      if (s.id == null) continue;
      await _supabase
          .from('schedules')
          .delete()
          .eq('id', s.id!)
          .timeout(_timeout);
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

    await _supabase.from('history').upsert(maps).timeout(_timeout);

    final ids = pending.map((r) => r['id'] as int).toList();
    await LocalDatabase.markHistorySynced(ids);
    return pending.length;
  }

  static Future<int> _syncUsers() async {
    final pending = await LocalDatabase.getPendingUsers();
    if (pending.isEmpty) return 0;

    for (final user in pending) {
      final username = user['username'] as String;
      await _supabase.from('users').upsert({
        'username': username,
        'gmail':    user['gmail'],
        'phone':    user['phone'],
        'address':  user['address'],
        'bio':      user['bio'],
      }).timeout(_timeout);
      await LocalDatabase.markUserSynced(username);
    }
    return pending.length;
  }

  static Future<List<ClassSchedule>> pullSchedules() async {
    if (!await isOnline()) return [];

    try {
      final rows = await _supabase
          .from('schedules')
          .select()
          .order('id')
          .timeout(_timeout);

      final schedules = <ClassSchedule>[];
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        map['is_archived']    = (map['is_archived']    == true) ? 1 : 0;
        map['is_archived_sa'] = (map['is_archived_sa'] == true) ? 1 : 0;
        map['sync_status']    = SyncStatus.synced.name;

        final s = ClassSchedule.fromSqliteMap(map);
        await LocalDatabase.upsertSchedule(s);
        schedules.add(s);
      }
      return schedules;
    } catch (e) {
      debugPrint('[SyncService] pullSchedules error: $e');
      return [];
    }
  }

  static RealtimeChannel listenToSchedules(
      void Function(List<ClassSchedule> updated) onUpdate) {
    return _supabase
        .channel('schedules_changes')
        .onPostgresChanges(
          event:    PostgresChangeEvent.all,
          schema:   'public',
          table:    'schedules',
          callback: (_) async {
            try {
              final updated = await pullSchedules();
              onUpdate(updated);
            } catch (e) {
              debugPrint('[SyncService] realtime callback error: $e');
            }
          },
        )
        .subscribe();
  }
}