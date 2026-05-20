// ============================================================
// lib/services/sync_service.dart
// NEW: Pushes pending SQLite records to Supabase when online.
//
// Strategy (offline-first):
//   1. Every write goes to SQLite first (sync_status = pending).
//   2. On connectivity restored (or app foreground), call syncAll().
//   3. syncAll() pushes only pending rows — no full re-uploads.
//   4. On Supabase success, local row is marked synced.
//   5. On failure, row stays pending — will retry next sync.
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';
import 'local_database.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // ── Check if device is online ─────────────────────────────
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── Master sync entry point ───────────────────────────────
  /// Call this on app resume or when connectivity is restored.
  /// Returns a summary string for optional debug display.
  static Future<String> syncAll() async {
    if (!await isOnline()) return 'Offline — sync skipped';

    int schedSynced  = 0;
    int histSynced   = 0;
    int usersSynced  = 0;
    final errors     = <String>[];

    // 1. Sync schedules
    try {
      schedSynced = await _syncSchedules();
    } catch (e) {
      errors.add('Schedules: $e');
    }

    // 2. Sync history
    try {
      histSynced = await _syncHistory();
    } catch (e) {
      errors.add('History: $e');
    }

    // 3. Sync users
    try {
      usersSynced = await _syncUsers();
    } catch (e) {
      errors.add('Users: $e');
    }

    if (errors.isNotEmpty) {
      return 'Partial sync — errors: ${errors.join('; ')}';
    }
    return 'Synced: $schedSynced schedules, $histSynced history rows, $usersSynced users';
  }

  // ── Sync schedules ────────────────────────────────────────
  static Future<int> _syncSchedules() async {
    final pending = await LocalDatabase.getPendingSchedules();
    if (pending.isEmpty) return 0;

    // Separate soft-deleted vs upserts
    final toDelete = pending
        .where((s) => s.syncStatus == SyncStatus.deleted)
        .toList();
    final toUpsert = pending
        .where((s) => s.syncStatus != SyncStatus.deleted)
        .toList();

    // Upsert batch to Supabase
    if (toUpsert.isNotEmpty) {
      final maps = toUpsert
          .where((s) => s.id != null)
          .map((s) => s.toSupabaseMap())
          .toList();
      if (maps.isNotEmpty) {
        await _supabase.from('schedules').upsert(maps);
        for (final s in toUpsert) {
          if (s.id != null) await LocalDatabase.markSynced(s.id!);
        }
      }
    }

    // Hard-delete from Supabase
    for (final s in toDelete) {
      if (s.id == null) continue;
      await _supabase
          .from('schedules')
          .delete()
          .eq('id', s.id!);
      await LocalDatabase.deleteSchedule(s.id!);
    }

    return pending.length;
  }

  // ── Sync history ──────────────────────────────────────────
  static Future<int> _syncHistory() async {
    final pending = await LocalDatabase.getPendingHistory();
    if (pending.isEmpty) return 0;

    // Remove internal SQLite fields before pushing
    final maps = pending.map((row) {
      final m = Map<String, dynamic>.from(row);
      m.remove('sync_status');
      return m;
    }).toList();

    await _supabase.from('history').upsert(maps);

    final ids = pending
        .map((r) => r['id'] as int)
        .toList();
    await LocalDatabase.markHistorySynced(ids);

    return pending.length;
  }

  // ── Sync users ────────────────────────────────────────────
  static Future<int> _syncUsers() async {
    final pending = await LocalDatabase.getPendingUsers();
    if (pending.isEmpty) return 0;

    for (final user in pending) {
      final username = user['username'] as String;

      // Never push plain-visible password_hash to Supabase —
      // only push profile fields. Auth is handled by Supabase Auth
      // or your own auth strategy. Adapt as needed.
      await _supabase.from('users').upsert({
        'username': username,
        'gmail':    user['gmail'],
        'phone':    user['phone'],
        'address':  user['address'],
        'bio':      user['bio'],
        // profile_img intentionally omitted here to avoid large blobs;
        // use Supabase Storage for images if required.
      });
      await LocalDatabase.markUserSynced(username);
    }
    return pending.length;
  }

  // ── Pull schedules FROM Supabase (initial load / full refresh) ──
  /// Use on first install or when a new device logs in.
  /// Overwrites local SQLite with the cloud copy.
  static Future<List<ClassSchedule>> pullSchedules() async {
    if (!await isOnline()) return [];

    final rows = await _supabase
        .from('schedules')
        .select()
        .order('id');

    final schedules = <ClassSchedule>[];
    for (final row in rows) {
      // Convert Supabase bool → SQLite int
      final map = Map<String, dynamic>.from(row);
      map['is_archived']    = (map['is_archived']    == true) ? 1 : 0;
      map['is_archived_sa'] = (map['is_archived_sa'] == true) ? 1 : 0;
      map['sync_status']    = SyncStatus.synced.name;

      final s = ClassSchedule.fromSqliteMap(map);
      await LocalDatabase.upsertSchedule(s);
      schedules.add(s);
    }
    return schedules;
  }

  // ── Real-time listener helper ────────────────────────────
  /// Subscribe to live changes on the `schedules` table.
  /// Returns a RealtimeChannel — call `.unsubscribe()` to clean up.
  static RealtimeChannel listenToSchedules(
      void Function(List<ClassSchedule> updated) onUpdate) {
    return _supabase
        .channel('schedules_changes')
        .onPostgresChanges(
          event:  PostgresChangeEvent.all,
          schema: 'public',
          table:  'schedules',
          callback: (_) async {
            // On any remote change, pull fresh list and notify caller
            final updated = await pullSchedules();
            onUpdate(updated);
          },
        )
        .subscribe();
  }
}