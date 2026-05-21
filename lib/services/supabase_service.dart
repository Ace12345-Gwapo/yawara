import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SupabaseService {
  static const String _base = '${AppConfig.supabaseUrl}/rest/v1';
  static const String _key  = AppConfig.supabaseAnonKey;

  static Map<String, String> get _readHeaders => {
    'apikey':        _key,
    'Authorization': 'Bearer $_key',
  };

  static Map<String, String> get _writeHeaders => {
    'apikey':        _key,
    'Authorization': 'Bearer $_key',
    'Content-Type':  'application/json',
    'Prefer':        'resolution=merge-duplicates,return=minimal',
  };

  static Map<String, String> get _deleteHeaders => {
    'apikey':        _key,
    'Authorization': 'Bearer $_key',
  };

  static Future<void> initialize() async {
    debugPrint('[SupabaseService] Ready (direct REST)');
  }

  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    List<String> queryParams = const [],
  }) async {
    try {
      final params = ['select=$columns', ...queryParams];
      final url    = Uri.parse('$_base/$table?${params.join('&')}');
      final res    = await http
          .get(url, headers: _readHeaders)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      debugPrint('[SupabaseService] SELECT $table ${res.statusCode}: ${res.body}');
      return [];
    } catch (e) {
      debugPrint('[SupabaseService] SELECT $table error: $e');
      return [];
    }
  }

  static Future<bool> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String? onConflict,
  }) async {
    if (rows.isEmpty) return true;
    try {
      final query = onConflict != null ? '?on_conflict=$onConflict' : '';
      final url   = Uri.parse('$_base/$table$query');
      final res   = await http
          .post(url, headers: _writeHeaders, body: jsonEncode(rows))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      debugPrint('[SupabaseService] UPSERT $table ${res.statusCode}: ${res.body}');
      return false;
    } catch (e) {
      debugPrint('[SupabaseService] UPSERT $table error: $e');
      return false;
    }
  }

  static Future<bool> delete(
      String table, String column, dynamic value) async {
    try {
      final url = Uri.parse(
          '$_base/$table?$column=eq.${Uri.encodeComponent(value.toString())}');
      final res = await http
          .delete(url, headers: _deleteHeaders)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      debugPrint('[SupabaseService] DELETE $table ${res.statusCode}: ${res.body}');
      return false;
    } catch (e) {
      debugPrint('[SupabaseService] DELETE $table error: $e');
      return false;
    }
  }

  static Future<bool> isReachable() async {
    try {
      final url = Uri.parse('$_base/schedules?select=id&limit=1');
      final res = await http
          .get(url, headers: _readHeaders)
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}