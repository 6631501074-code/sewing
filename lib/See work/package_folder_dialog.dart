import 'package:flutter/material.dart';

Future<String?> showPackageFolderDialog(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
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
                'ชื่อโฟลเดอร์งานเหมา',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'ใส่ชื่อโฟลเดอร์เพื่อจัดการงานหลาย ๆ งานในที่เดียว',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'เช่น ชุดสูท สต๊อก 100 ชุด',
                  filled: true,
                  fillColor: const Color(0xFFF4F4F6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(ctx, name);
                  }
                },
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(ctx, name);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'สร้าง',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
