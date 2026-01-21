import 'package:flutter/material.dart';

class DailyChallengeCard extends StatelessWidget {
  final int totalTasks;
  const DailyChallengeCard({super.key, required this.totalTasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFB8ACFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // 🔹 ข้อความฝั่งซ้าย
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily\nchallenge',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Do your plan before 09:00 AM',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 รูปด้านขวา (ล้นกรอบ)
          Positioned(
            right: -160,
            bottom: -80,
            child: Image.asset(
              'asset/img/img2.png',
              height: 300,
              fit: BoxFit.contain,
            ),
          ),

          // ✅ Text 
          Positioned(
            left: 20,
            bottom: 20,
            child: Text(
              'งานทั้งหมด $totalTasks งาน',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
