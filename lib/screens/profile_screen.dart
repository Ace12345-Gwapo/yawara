// ============================================================
// lib/screens/profile_screen.dart
// FIX: Helper texts replaced with normal readable Text widgets
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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

  final _gmailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus     = FocusNode();

  static const _green = Color(0xFF1B5E20);
  bool _isSaved       = false;
  bool _isPickingImage = false;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _gmailCtrl.addListener(()   => setState(() => _isSaved = false));
    _phoneCtrl.addListener(()   => setState(() => _isSaved = false));
    _addressCtrl.addListener(() => setState(() => _isSaved = false));
    _bioCtrl.addListener(()     => setState(() => _isSaved = false));
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedBase64 = prefs.getString('profile_img_${widget.username}');
    setState(() {
      _gmailCtrl.text =
          prefs.getString('profile_gmail_${widget.username}') ?? '';
      _phoneCtrl.text =
          prefs.getString('profile_phone_${widget.username}') ?? '';
      _addressCtrl.text =
          prefs.getString('profile_address_${widget.username}') ?? '';
      _bioCtrl.text =
          prefs.getString('profile_bio_${widget.username}') ?? '';
      if (savedBase64 != null && savedBase64.isNotEmpty) {
        try {
          _imageBytes = base64Decode(savedBase64);
        } catch (_) {
          _imageBytes = null;
        }
      }
    });
  }

  void _saveProfile() async {
    FocusScope.of(context).unfocus();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'profile_gmail_${widget.username}', _gmailCtrl.text.trim());
    await prefs.setString(
        'profile_phone_${widget.username}', _phoneCtrl.text.trim());
    await prefs.setString(
        'profile_address_${widget.username}', _addressCtrl.text.trim());
    await prefs.setString(
        'profile_bio_${widget.username}', _bioCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        if (!mounted) return;
        setState(() => _isPickingImage = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image is empty. Please try another.'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      final base64Str = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_img_${widget.username}', base64Str);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _isPickingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Photo updated!'),
            backgroundColor: Color(0xFF1B5E20)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  String _getInitials() {
    final parts = widget.username
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return 'SA';
  }

  @override
  void dispose() {
    _gmailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    _gmailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 18),
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
      backgroundColor: const Color(0xFFF1F5F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile avatar ───────────────────────────
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
                                color: _green.withValues(alpha: 0.3),
                                width: 2),
                          ),
                          child: ClipOval(
                            child: _isPickingImage
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      )
                                    : Center(
                                        child: Text(
                                          _getInitials(),
                                          style: const TextStyle(
                                              fontSize: 38,
                                              fontWeight: FontWeight.bold,
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
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.username,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _green.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'Student Assistant',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _green),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // FIX: Normal text
                  Text(
                    'Tap photo to change',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 4),
            const Text(
              'Personal Information',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),

            // FIX: No more helperText — just the fields with clean hints
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

            _fieldLabel('Gmail Address'),
            TextField(
              controller: _gmailCtrl,
              focusNode: _gmailFocus,
              keyboardType: TextInputType.emailAddress,
              maxLength: 60,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_phoneFocus),
              decoration: const InputDecoration(
                hintText: 'e.g. yourname@gmail.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
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
                        color: Colors.white, fontWeight: FontWeight.bold),
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