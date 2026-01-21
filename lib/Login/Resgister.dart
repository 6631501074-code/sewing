import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sewing/Login/firestore_Acc.dart';
import 'package:sewing/Login/Login.dart';

class Resgister extends StatefulWidget {
  const Resgister({super.key});

  @override
  State<Resgister> createState() => _ResgisterState();
}

class _ResgisterState extends State<Resgister> {
  final _usernameC = TextEditingController();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _usernameC.dispose();
    _nameC.dispose();
    _phoneC.dispose();
    _passwordC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameC.text.trim();
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    final password = _passwordC.text.trim();
    final confirm = _confirmC.text.trim();

    if (username.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    if (password != confirm) {
      _showMessage('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _saving = true);

    try {
      final service =
          FirestoreAccountService(FirebaseFirestore.instance);

      await service.createUser(
        username: username,
        name: name,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      _showMessage('สมัครสมาชิกสำเร็จ');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } on StateError catch (e) {
      if (e.message == 'USER_EXISTS') {
        _showMessage('มีผู้ใช้นี้ในระบบแล้ว');
      } else {
        _showMessage('บันทึกไม่สำเร็จ');
      }
    } catch (_) {
      _showMessage('บันทึกไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('asset/img/img1.png'),
                  const SizedBox(height: 8),

                  const Text(
                    'Sewing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Santa',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Register Screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _usernameC,
                    decoration: _inputDecoration('เลขผู้ใช้'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameC,
                    decoration: _inputDecoration('ชื่อ'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _phoneC,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('เบอร์โทร'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordC,
                    obscureText: true,
                    decoration: _inputDecoration('รหัสผ่าน'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmC,
                    obscureText: true,
                    decoration: _inputDecoration('ยืนยันรหัสผ่าน'),
                  ),

                  const SizedBox(height: 30),

                  // ===== ปุ่มสมัคร (แก้แล้ว) =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        minimumSize:
                            const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _saving
                            ? 'กำลังบันทึก...'
                            : 'สมัครสมาชิก',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
