// ============================================================
// lib/screens/profile_screen.dart
// REWRITTEN:
//   • All SharedPreferences removed — SQLite via AuthService
//   • Data auto-loads in initState (no manual button needed)
//   • Supports dark/light theme colors
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _gmailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl     = TextEditingController();
  final _emailCtrl   = TextEditingController();

  final _gmailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus     = FocusNode();

  static const _green = Color(0xFF1B5E20);

  bool _isSaved        = false;
  bool _isPickingImage = false;
  bool _isLoading      = true;
  Uint8List? _imageBytes;

  final ImagePicker _picker = ImagePicker();

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Auto-load immediately — no manual trigger needed
    _loadProfile();
    _gmailCtrl.addListener(()   => setState(() => _isSaved = false));
    _phoneCtrl.addListener(()   => setState(() => _isSaved = false));
    _addressCtrl.addListener(() => setState(() => _isSaved = false));
    _bioCtrl.addListener(()     => setState(() => _isSaved = false));
    _emailCtrl.addListener(()   => setState(() => _isSaved = false));
  }

  // ── Load from SQLite via AuthService ─────────────────────

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final gmail   = await AuthService.loadProfileField(widget.username, 'gmail');
    final phone   = await AuthService.loadProfileField(widget.username, 'phone');
    final address = await AuthService.loadProfileField(widget.username, 'address');
    final bio     = await AuthService.loadProfileField(widget.username, 'bio');
    final email   = await AuthService.loadProfileField(widget.username, 'email');
    final imgB64  = await AuthService.loadProfileImage(widget.username);

    if (!mounted) return;

    // Temporarily remove listeners so setting text doesn't flip _isSaved
    _gmailCtrl.text   = gmail   ?? '';
    _phoneCtrl.text   = phone   ?? '';
    _addressCtrl.text = address ?? '';
    _bioCtrl.text     = bio     ?? '';
    _emailCtrl.text   = email   ?? '';

    Uint8List? bytes;
    if (imgB64 != null && imgB64.isNotEmpty) {
      try { bytes = base64Decode(imgB64); } catch (_) {}
    }

    setState(() {
      _imageBytes = bytes;
      _isSaved    = true; // nothing changed yet
      _isLoading  = false;
    });
  }

  // ── Save to SQLite via AuthService ────────────────────────

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    await AuthService.saveProfileField(
        widget.username, 'gmail', _gmailCtrl.text.trim());
    await AuthService.saveProfileField(
        widget.username, 'phone', _phoneCtrl.text.trim());
    await AuthService.saveProfileField(
        widget.username, 'address', _addressCtrl.text.trim());
    await AuthService.saveProfileField(
        widget.username, 'bio', _bioCtrl.text.trim());
    await AuthService.saveProfileField(
        widget.username, 'email', _emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isSaved = true);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  // ── Image picker ──────────────────────────────────────────

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _isPickingImage = false);
        return;
      }
      final bytes  = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        setState(() => _isPickingImage = false);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Image is empty. Try another.'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      await AuthService.saveProfileImage(widget.username, base64Encode(bytes));
      if (!mounted) return;
      setState(() {
        _imageBytes     = bytes;
        _isPickingImage = false;
      });
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Photo updated!'),
            backgroundColor: _green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickingImage = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  String _getInitials() {
    final parts = widget.username
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : 'SA';
  }

  @override
  void dispose() {
    _gmailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    _emailCtrl.dispose();
    _gmailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 18),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isPickingImage ? null : _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _green.withValues(alpha: 0.12),
                                  border: Border.all(
                                      color:
                                          _green.withValues(alpha: 0.3),
                                      width: 2),
                                ),
                                child: ClipOval(
                                  child: _isPickingImage
                                      ? const Center(
                                          child:
                                              CircularProgressIndicator())
                                      : _imageBytes != null
                                          ? Image.memory(_imageBytes!,
                                              fit: BoxFit.cover,
                                              width: 110,
                                              height: 110)
                                          : Center(
                                              child: Text(
                                                _getInitials(),
                                                style: const TextStyle(
                                                    fontSize: 38,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: _green),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(widget.username,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _green.withValues(alpha: 0.2)),
                          ),
                          child: const Text('Student Assistant',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _green)),
                        ),
                        const SizedBox(height: 6),
                        Text('Tap photo to change',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500])),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text('Personal Information',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),

                  _fieldLabel('Bio'),
                  TextField(
                    controller: _bioCtrl,
                    focusNode: _bioFocus,
                    maxLength: 150,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_gmailFocus),
                    decoration: const InputDecoration(
                      hintText: 'Tell something about yourself',
                      border: OutlineInputBorder(),
                      counterStyle: TextStyle(fontSize: 12),
                    ),
                  ),

                  _fieldLabel('Email Address'),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_gmailFocus),
                    decoration: const InputDecoration(
                      hintText: 'e.g. yourname@gmail.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      counterText: '',
                    ),
                  ),

                  _fieldLabel('Gmail / Contact'),
                  TextField(
                    controller: _gmailCtrl,
                    focusNode: _gmailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_phoneFocus),
                    decoration: const InputDecoration(
                      hintText: 'e.g. yourname@gmail.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.alternate_email),
                      counterText: '',
                    ),
                  ),

                  _fieldLabel('Phone Number'),
                  TextField(
                    controller: _phoneCtrl,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_addressFocus),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 09123456789',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                  ),

                  _fieldLabel('Address'),
                  TextField(
                    controller: _addressCtrl,
                    focusNode: _addressFocus,
                    maxLength: 100,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveProfile(),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Iligan City, Lanao del Norte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 28),

                  AnimatedOpacity(
                    opacity: _isSaved ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaved ? null : _saveProfile,
                        icon: Icon(
                          _isSaved ? Icons.check : Icons.save_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          _isSaved ? 'Profile Updated' : 'Save Profile',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}