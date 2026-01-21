import 'package:flutter/material.dart';

enum TaskStatus { urgent, doing, overdue, done }

class TaskCard extends StatelessWidget {
  final String title;      // ชื่องาน
  final String tailorName; // ชื่อคนตัด
  final TaskStatus status; // สถานะ
  final String imagePath;  // รูป
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.tailorName,
    required this.status,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusUi = _statusStyle(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // รูป
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.checkroom_rounded, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ข้อมูลงาน
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tailorName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // สถานะ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusUi.bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusUi.text,
                style: TextStyle(
                  color: statusUi.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusUI _statusStyle(TaskStatus s) {
    switch (s) {
      case TaskStatus.urgent:
        return _StatusUI("Urgent", const Color(0xFFFFE5E5), const Color(0xFFCC1F1F));
      case TaskStatus.doing:
        return _StatusUI("Doing", const Color(0xFFE6F0FF), const Color(0xFF1E63D5));
      case TaskStatus.overdue:
        return _StatusUI("Overdue", const Color(0xFFFFF3E0), const Color(0xFFB45309));
      case TaskStatus.done:
        return _StatusUI("Done", const Color(0xFFE7F8EF), const Color(0xFF168A47));
    }
  }
}

class _StatusUI {
  final String text;
  final Color bg;
  final Color fg;
  _StatusUI(this.text, this.bg, this.fg);
}
