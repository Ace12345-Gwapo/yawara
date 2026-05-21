// ============================================================
// lib/config/app_config.dart
// NEW: Single source of truth for all configuration values.
//
// HOW TO SET UP:
//   1. Go to your Supabase Dashboard → Project Settings → API
//   2. Copy your Project URL  → paste into supabaseUrl
//   3. Copy your anon/public key → paste into supabaseAnonKey
//   4. Change adminUsername / adminPassword to your own values
//
// ⚠️  Add this file to .gitignore if your repo is public:
//      echo "lib/config/app_config.dart" >> .gitignore
// ============================================================

class AppConfig {
  AppConfig._(); // prevent instantiation

  // ── Supabase ──────────────────────────────────────────────
  // Example: 'https://abcdefghijkl.supabase.co'
  static const String supabaseUrl = 'https://vqhtmgssiuacztrntina.supabase.co';

  // Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseAnonKey = 'sb_publishable_9QsMKGDRyEH5NARd4DBIRw_vUScdVqq';

  // ── Admin account ─────────────────────────────────────────
  // Change these before deploying!
  static const String adminUsername = 'admin';
  static const String adminPassword = 'your_secure_admin_password';

  // ── App metadata ──────────────────────────────────────────
  static const String appName = 'TCGC Monitoring';
}