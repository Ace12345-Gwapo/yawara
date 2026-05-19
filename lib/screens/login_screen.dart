// ============================================================
// lib/screens/login_screen.dart
// FIX: "New SA?" is plain text, only "Register here" is tappable/blue
// ============================================================

import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _passVisible = false;
  bool _isLoading = false;

  static const _green = Color(0xFF1B5E20);

  bool _isValidUsername(String u) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9 .]*$').hasMatch(u);

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _doLogin() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange);
      return;
    }

    if (username.toLowerCase() != 'admin') {
      if (!_isValidUsername(username)) {
        _showSnackBar('Invalid name. Must start with a letter.', Colors.red);
        return;
      }
      if (username.length < 6) {
        _showSnackBar('Name must be 6 characters and above.', Colors.red);
        return;
      }
      if (password.length < 6) {
        _showSnackBar('Password must be 6 characters and above.', Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);
    final role = await AuthService.login(username, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (role != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) =>
              DashboardScreen(userRole: role, username: username),
        ),
      );
    } else {
      _showSnackBar('Account not found or incorrect password.', Colors.red);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Card(
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/tcgc.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school,
                                  size: 50, color: _green),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'TCGC MONITORING',
                          style: TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 25),

                      _fieldLabel('Student Assistant Full Name'),
                      TextField(
                        controller: _userCtrl,
                        textInputAction: TextInputAction.next,
                        maxLength: 30,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passFocus),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 18),

                      _fieldLabel('Password'),
                      TextField(
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        obscureText: !_passVisible,
                        textInputAction: TextInputAction.done,
                        maxLength: 50,
                        onSubmitted: (_) => _doLogin(),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          border: const OutlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(_passVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _passVisible = !_passVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _green),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('LOGIN',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),

                      // FIX: "New SA?" is plain text. Only "Register here" is tappable.
                      const SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New SA? ',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151)),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => const RegisterScreen()),
                              ),
                              child: const Text(
                                'Register here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}