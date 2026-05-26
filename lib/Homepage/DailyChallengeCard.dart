import 'package:flutter/material.dart';

class DailyChallengeCard extends StatelessWidget {
  final int pendingCount;

  const DailyChallengeCard({super.key, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14111827)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'งานวันนี้',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'เรียงตามงานด่วนและวันรับงาน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x14111827)),
                  ),
                  child: Text(
                    'ค้างอยู่ $pendingCount งาน',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: -120,
            bottom: -70,
            child: Image.asset(
              'asset/img/img2.png',
              height: 280,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
