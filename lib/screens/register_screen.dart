// ============================================================
// lib/screens/register_screen.dart
// UPDATED:
//   • "New Password" renamed to "Password"
//   • Email field added above Password (with format validation)
//   • Email stored in SQLite via AuthService.registerSA()
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController(); // NEW
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _emailFocus   = FocusNode(); // NEW
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  bool _passVisible    = false;
  bool _confirmVisible = false;
  bool _isLoading      = false;

  static const _green = Color(0xFF1B5E20);

  bool _isValidUsername(String u) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9 .]*$').hasMatch(u);

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _doRegister() async {
    final username = _userCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (username.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange);
      return;
    }
    if (!_isValidUsername(username)) {
      _showSnackBar(
          'Name must start with a letter. Numbers-only not allowed.',
          Colors.red);
      return;
    }
    if (username.length < 6) {
      _showSnackBar('Full name must be 6 characters and above.', Colors.red);
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address.', Colors.red);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be 6 characters and above.', Colors.red);
      return;
    }
    if (password != confirm) {
      _showSnackBar('Passwords do not match!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final ok = await AuthService.registerSA(
      username,
      password,
      email: email,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _showSnackBar('Account registered successfully!', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackBar('Username already exists or is not allowed.', Colors.red);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 5, left: 2),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      );

  @override
  Widget build(BuildContext context) {
    final isDark =
        ThemeService.themeMode.value == ThemeMode.dark;
    final labelColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SA Registration'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Full Name ──────────────────────────────
            _label('Full Name'),
            TextField(
              controller: _userCtrl,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
              decoration: const InputDecoration(
                hintText: 'e.g. Ace F. Dumandagan',
                border: OutlineInputBorder(),
                counterText: '',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            _hint(
                'Must be at least 6 characters and start with a letter.'),
            const SizedBox(height: 18),

            // ── Email (NEW) ────────────────────────────
            _label('Email Address'),
            TextField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              maxLength: 60,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passFocus),
              decoration: const InputDecoration(
                hintText: 'e.g. yourname@gmail.com',
                border: OutlineInputBorder(),
                counterText: '',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            _hint('Must be a valid email address.'),
            const SizedBox(height: 18),

            // ── Password (renamed from "New Password") ─
            _label('Password'),
            TextField(
              controller: _passCtrl,
              focusNode: _passFocus,
              obscureText: !_passVisible,
              textInputAction: TextInputAction.next,
              maxLength: 50,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                border: const OutlineInputBorder(),
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_passVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _passVisible = !_passVisible),
                ),
              ),
            ),
            _hint('Must be at least 6 characters.'),
            const SizedBox(height: 18),

            // ── Confirm Password ───────────────────────
            _label('Confirm Password'),
            TextField(
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              obscureText: !_confirmVisible,
              textInputAction: TextInputAction.done,
              maxLength: 50,
              onSubmitted: (_) => _doRegister(),
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                border: const OutlineInputBorder(),
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_confirmVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _confirmVisible = !_confirmVisible),
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: _green),
                onPressed: _isLoading ? null : _doRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Register Account',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}