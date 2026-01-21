import 'package:flutter/material.dart';
import 'package:sewing/Homepage/Homepage.dart';
import 'package:sewing/Voice/mic_page.dart';
import 'package:sewing/See work/WorkQueuePage.dart';
import 'package:sewing/Dashboard/dashboard.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({super.key});

  @override
  State<Navigationbar> createState() => _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int _index = 0;

  final List<Widget> _pages = const [
    Homepage(),
    MiccPage(),
    WorkQueuePage(),
    DashboardPage(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ สลับหน้าแบบไม่ rebuild หน้าทั้งหมด
      body: IndexedStack(index: _index, children: _pages),

      // ✅ แถบล่าง ขอบมน
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white, // ✅ พื้นหลังขาว
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.black .withOpacity(0.3), // ✅ กรอบบางสีฟ้า
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // เงาเบา ๆ
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  isActive: _index == 0,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.mic_rounded,
                  isActive: _index == 1,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.task_alt_rounded,
                  isActive: _index == 2,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  isActive: _index == 3,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  isActive: _index == 4,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => setState(() => _index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ ปุ่มไอคอนแต่ละอัน + เส้นบนหัว (เมื่อ active)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ เส้นสีฟ้าด้านบน (เฉพาะ active)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),

            Icon(icon, color: color, size: 26),
          ],
        ),
      ),
    );
  }
}

//
// ✅ หน้า Placeholder (สร้างหน้าใหม่ไว้ให้ก่อน)
// คุณค่อยเอาโค้ดหน้าจริงมาแทนทีหลังได้
//

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("History Page"));
  }
}
