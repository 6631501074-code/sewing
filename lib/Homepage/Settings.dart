import 'package:flutter/material.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // 🔴 สามจุด
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editProfile();
                  break;
                case 'password':
                  _changePassword();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('แก้ไขโปรไฟล์'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 18),
                    SizedBox(width: 8),
                    Text('เปลี่ยนรหัสผ่าน'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('asset/img/user.png'),
            ),
            SizedBox(height: 16),
            Text(
              'ผู้ดูแลระบบ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'admin@sewing.com',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ================== ACTIONS ==================

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไปหน้าแก้ไขโปรไฟล์')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไปหน้าเปลี่ยนรหัสผ่าน')),
    );
  }

  void _logout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ออกจากระบบ')),
    );

    // ตัวอย่างกลับไปหน้า Login
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const Login()),
    // );
  }
}
