import 'package:flutter/material.dart';

enum CreateJobResult { daily, package, cancelled }

Future<CreateJobResult?> showCreateJobDialog(BuildContext context) {
  return showDialog<CreateJobResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกประเภทงาน',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),

              // ✅ งานรายวัน
              _JobTypeCard(
                title: 'งานรายวัน',
                description: 'เพิ่มงานเดี่ยว',
                icon: Icons.note_add_rounded,
                onTap: () => Navigator.pop(ctx, CreateJobResult.daily),
              ),

              const SizedBox(height: 12),

              // ✅ งานเหมา
              _JobTypeCard(
                title: 'งานเหมา',
                description: 'สร้างโฟลเดอร์สำหรับงานเหมา',
                icon: Icons.folder_special_rounded,
                onTap: () => Navigator.pop(ctx, CreateJobResult.package),
              ),

              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _JobTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _JobTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14111827)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
