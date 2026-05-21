// ============================================================
// lib/main.dart
// UPDATED: Supabase credentials read from AppConfig — no
//          hardcoded keys anywhere in this file.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const TCGCApp());
}

class TCGCApp extends StatelessWidget {
  const TCGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
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