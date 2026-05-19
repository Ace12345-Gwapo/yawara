// Pun-a ang app — entry point sa tibuok sistema
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TCGCApp());
}

class TCGCApp extends StatelessWidget {
  const TCGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCGC Monitoring',
      debugShowCheckedModeBanner: false,
      // Gamiton ang Poppins font ug green nga tema
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}