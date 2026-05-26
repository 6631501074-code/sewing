import 'package:flutter/material.dart';

enum GarmentType { none, shirt, pantsOfficial }

String garmentTypeLabel(GarmentType type) {
  switch (type) {
    case GarmentType.shirt:
      return 'เสื้อ';
    case GarmentType.pantsOfficial:
      return 'กางเกงราชการ';
    case GarmentType.none:
      return 'ยังไม่ได้เลือกประเภท';
  }
}

Future<GarmentType?> showGarmentDialog(BuildContext context) {
  return showDialog<GarmentType>(
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
                'เลือกประเภท',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),

              // ✅ เสื้อ
              _GarmentBigCard(
                title: 'เสื้อ',
                assetPath: 'asset/img/img4.png',
                enabled: true,
                badgeText: 'พร้อม',
                onTap: () => Navigator.pop(ctx, GarmentType.shirt),
              ),

              const SizedBox(height: 12),

              // ✅ กางเกง (ใช้งานได้)
              _GarmentBigCard(
                title: 'กางเกงราชการ',
                assetPath: 'asset/img/img3.png',
                enabled: true,
                badgeText: 'พร้อม',
                onTap: () => Navigator.pop(ctx, GarmentType.pantsOfficial),
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
                    'ปิด',
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

class _GarmentBigCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool enabled;
  final String badgeText;
  final VoidCallback? onTap;

  const _GarmentBigCard({
    required this.title,
    required this.assetPath,
    required this.enabled,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF4F4F6);
    final border = Colors.black.withOpacity(enabled ? 0.08 : 0.05);
    final titleColor = enabled ? Colors.black : Colors.black.withOpacity(0.35);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ รูปใหญ่
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ ข้อความใต้รูป + badge มินิมอล
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(enabled ? 0.08 : 0.06),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(enabled ? 0.65 : 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
