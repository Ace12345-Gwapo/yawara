// ============================================================
// lib/screens/register_screen.dart
// FIX: Normal readable text below fields instead of small helperText
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();
  bool _passVisible    = false;
  bool _confirmVisible = false;
  bool _isLoading      = false;

  static const _green = Color(0xFF1B5E20);

  bool _isValidUsername(String u) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9 .]*$').hasMatch(u);

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _doRegister() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange);
      return;
    }
    if (!_isValidUsername(username)) {
      _showSnackBar('Must start with a letter. Numbers-only not allowed.', Colors.red);
      return;
    }
    if (username.length < 6) {
      _showSnackBar('Full name must be 6 characters and above.', Colors.red);
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
    final ok = await AuthService.registerSA(username, password);
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
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)),
      ),
    );
  }

  // FIX: Normal-sized hint text below field (not tiny helperText)
  Widget _fieldHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 2),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _fieldLabel('Full Name'),
            TextField(
              controller: _userCtrl,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passFocus),
              decoration: const InputDecoration(
                hintText: 'e.g. Ace F. Dumandagan',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            // FIX: Normal text, not tiny helper text
            _fieldHint('Must be at least 6 characters and must start with a letter.'),
            const SizedBox(height: 18),

            _fieldLabel('New Password'),
            TextField(
              controller: _passCtrl,
              focusNode: _passFocus,
              obscureText: !_passVisible,
              textInputAction: TextInputAction.next,
              maxLength: 50,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
              decoration: InputDecoration(
                hintText: 'e.g. mypassword123',
                border: const OutlineInputBorder(),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                      _passVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _passVisible = !_passVisible),
                ),
              ),
            ),
            _fieldHint('Must be at least 6 characters.'),
            const SizedBox(height: 18),

            _fieldLabel('Confirm Password'),
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
                suffixIcon: IconButton(
                  icon: Icon(_confirmVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _confirmVisible = !_confirmVisible),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _green),
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
          ],
        ),
      ),
    );
  }
}