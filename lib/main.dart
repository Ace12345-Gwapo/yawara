// ============================================================
// lib/main.dart
// UPDATED: Initialize Supabase before runApp
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Supabase ───────────────────────────────────
  // Replace the two strings below with your project's values.
  // Go to: Supabase Dashboard → Project Settings → API
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_ID.supabase.co',   // ← change this
    anonKey: 'YOUR_ANON_KEY',                      // ← change this
  );

  runApp(const TCGCApp());
}

class TCGCApp extends StatelessWidget {
  const TCGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCGC Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}