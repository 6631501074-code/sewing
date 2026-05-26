import 'package:flutter/material.dart';
import 'package:sewing/Homepage/Homepage.dart';
import 'package:sewing/Voice/mic_page.dart';
import 'package:sewing/See work/WorkQueuePage.dart';
import 'package:sewing/See work/work_confirmation_page.dart';
import 'package:sewing/See work/work_history_page.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({super.key});

  @override
  State<Navigationbar> createState() => _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int _index = 0;
  int _micPickerRequest = 0;
  final List<int> _pageVersions = List<int>.filled(5, 0);

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.blueAccent;
    final pages = [
      Homepage(
        key: ValueKey('home-${_pageVersions[0]}'),
        onOpenWorkQueue: () => _selectPage(2),
      ),
      MiccPage(
        key: ValueKey('mic-${_pageVersions[1]}'),
        openPickerRequest: _micPickerRequest,
      ),
      WorkQueuePage(
        key: ValueKey('queue-${_pageVersions[2]}'),
        onOpenConfirmation: () => _selectPage(3),
      ),
      WorkConfirmationPage(key: ValueKey('confirm-${_pageVersions[3]}')),
      WorkHistoryPage(key: ValueKey('history-${_pageVersions[4]}')),
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      body: pages[_index],

      // ✅ แถบล่าง ขอบมน
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white, // ✅ พื้นหลังขาว
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x14111827), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'หน้าแรก',
                  isActive: _index == 0,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => _selectPage(0),
                ),
                _NavItem(
                  icon: Icons.mic_rounded,
                  label: 'วัดตัว',
                  isActive: _index == 1,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => _selectPage(1, openPicker: true),
                ),
                _NavItem(
                  icon: Icons.task_alt_rounded,
                  label: 'งาน',
                  isActive: _index == 2,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => _selectPage(2),
                ),
                _NavItem(
                  icon: Icons.fact_check_rounded,
                  label: 'ยืนยัน',
                  isActive: _index == 3,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => _selectPage(3),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'ประวัติ',
                  isActive: _index == 4,
                  activeColor: activeColor,
                  inactiveColor: const Color.fromARGB(255, 111, 110, 110),
                  onTap: () => _selectPage(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPage(int index, {bool openPicker = false}) {
    setState(() {
      _index = index;
      _pageVersions[index]++;
      if (openPicker) {
        _micPickerRequest++;
      }
    });
  }
}

// ✅ ปุ่มไอคอนแต่ละอัน + เส้นบนหัว (เมื่อ active)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
