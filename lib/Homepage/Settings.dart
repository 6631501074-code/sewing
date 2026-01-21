import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewing/Login/Login.dart';
import 'package:sewing/Login/firestore_Acc.dart';
import 'package:sewing/session/user_session.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  final _usernameC = TextEditingController();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _saving = false;
  bool _uploading = false;
  String? _photoUrl;

  @override
  void dispose() {
    _usernameC.dispose();
    _nameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าโปรไฟล์'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFF3F4F6),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : const AssetImage('asset/img/user.png')),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: Text(_uploading ? 'กำลังอัปโหลดรูป...' : 'เปลี่ยนรูปโปรไฟล์'),
                ),
              ),
              const SizedBox(height: 12),

              _field(
                label: 'เลขผู้ใช้',
                controller: _usernameC,
                hint: 'รหัสผู้ใช้ในระบบ',
              ),
              const SizedBox(height: 10),
              _field(label: 'ชื่อ', controller: _nameC, hint: 'ชื่อที่แสดง'),
              const SizedBox(height: 10),
              _field(
                label: 'อีเมล',
                controller: _emailC,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _field(
                label: 'รหัสผ่านใหม่',
                controller: _passwordC,
                hint: '••••••••',
                obscureText: true,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _saving ? 'กำลังบันทึก...' : 'บันทึก',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadUser() async {
    final username = await UserSession.getUsername();
    if (!mounted) return;
    if (username != null) {
      _usernameC.text = username;
      final doc = await FirebaseFirestore.instance.collection('users').doc(username).get();
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      _nameC.text = (data['name'] ?? '').toString();
      _emailC.text = (data['email'] ?? '').toString();
      _photoUrl = (data['photoUrl'] ?? '').toString();
      setState(() {});
    }
  }
  Future<void> _saveProfile() async {
    final username = _usernameC.text.trim();
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();

    if (username.isEmpty) {
      _showMessage('กรุณากรอกเลขผู้ใช้');
      return;
    }

    setState(() => _saving = true);
    try {
      final service = FirestoreAccountService(FirebaseFirestore.instance);
      await service.updateUser(
        username: username,
        name: name.isEmpty ? null : name,
        email: email.isEmpty ? null : email,
        password: password.isEmpty ? null : password,
        photoUrl: _photoUrl,
      );
      await UserSession.setUsername(username);
      if (!mounted) return;
      _passwordC.clear();
      _showMessage('บันทึกข้อมูลแล้ว');
    } catch (_) {
      if (!mounted) return;
      _showMessage('บันทึกไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _logout() {
    UserSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  Future<void> _pickImage() async {
    final username = _usernameC.text.trim();
    if (username.isEmpty) {
      _showMessage('กรุณากรอกเลขผู้ใช้ก่อนอัปโหลดรูป');
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _profileImage = File(file.path);
      _uploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(username)
          .child('profile.jpg');
      await storageRef.putFile(_profileImage!);
      final url = await storageRef.getDownloadURL();
      _photoUrl = url;

      final service = FirestoreAccountService(FirebaseFirestore.instance);
      await service.updateUser(username: username, photoUrl: url);
    } catch (_) {
      _showMessage('อัปโหลดรูปไม่สำเร็จ');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F7F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
