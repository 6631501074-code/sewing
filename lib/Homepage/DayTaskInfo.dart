import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TaskStatus { none, normal, urgent }

class DayTaskInfo extends StatelessWidget {
  final DateTime date;
  final TaskStatus status;
  final bool isSelected;
  final VoidCallback? onTap;

  const DayTaskInfo({
    super.key,
    required this.date,
    required this.status,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(date); // Mon Tue ...
    final dayNumber = DateFormat('d').format(date); // 21

    // สีจุดสถานะ
    final Color dotColor = switch (status) {
      TaskStatus.none => Colors.transparent,
      TaskStatus.normal => Colors.orange, // งานปกติ
      TaskStatus.urgent => Colors.red,     // งานด่วน
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 54,
        height: 78, // ✅ กำหนดสูงพอดี
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),

            // ✅ จุดสถานะ (ไม่มีเลข taskCount แล้ว)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
