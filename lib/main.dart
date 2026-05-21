import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.load();

  try {
    await Supabase.initialize(
      url:     AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[YAWARA] Supabase init timed out — running offline');
        return Supabase.instance;
      },
    );
  } catch (e) {
    debugPrint('[YAWARA] Supabase init error: $e — running offline');
  }

  runApp(const TCGCApp());
}

class TCGCApp extends StatelessWidget {
  const TCGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (_, mode, __) => AnimatedTheme(
        data: mode == ThemeMode.dark
            ? ThemeService.dark
            : ThemeService.light,
        duration: const Duration(milliseconds: 300),
        child: MaterialApp(
          title: AppConfig.appName,
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