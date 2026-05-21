// ============================================================
// lib/main.dart
// UPDATED: Global theme system (Light / Dark) with smooth
//          animated transitions. ThemeService persists choice.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted theme before building the widget tree
  await ThemeService.load();

  // ── Supabase (fill in your own values) ───────────────────
  await Supabase.initialize(
    url:     'https://YOUR_PROJECT_ID.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const TCGCApp());
}

class TCGCApp extends StatelessWidget {
  const TCGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds only when themeMode changes,
    // keeping the rest of the widget tree stable.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (_, mode, __) => AnimatedTheme(
        data: mode == ThemeMode.dark
            ? ThemeService.dark
            : ThemeService.light,
        duration: const Duration(milliseconds: 300),
        child: MaterialApp(
          title: 'TCGC Monitoring',
          debugShowCheckedModeBanner: false,
          theme:      ThemeService.light,
          darkTheme:  ThemeService.dark,
          themeMode:  mode,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}