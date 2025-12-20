import 'package:flutter/material.dart';
import 'DayTaskInfo.dart'; // ที่มี enum TaskStatus และ DayTaskInfo

class WeekTaskStrip extends StatefulWidget {
  const WeekTaskStrip({super.key});

  @override
  State<WeekTaskStrip> createState() => _WeekTaskStripState();
}

class _WeekTaskStripState extends State<WeekTaskStrip> {
  late final List<Map<String, dynamic>> mock;
  late int selectedIndex;

  final ScrollController _scrollController = ScrollController();

  static const double itemWidth = 54;
  static const double spacing = 10;

  @override
  void initState() {
    super.initState();

    // ✅ ตัดเวลาให้เป็น 00:00
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ✅ วันนี้อยู่ตรงกลาง (index 3)
    selectedIndex = 3;
    final start = today.subtract(const Duration(days: 3));

    mock = List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      final status = (i == 3)
          ? TaskStatus.urgent
          : (i % 2 == 0 ? TaskStatus.normal : TaskStatus.none);

      return {
        "date": d,
        "status": status,
      };
    });

    // ✅ เลื่อนมาให้วันนี้อยู่กลางจอหลัง build เสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final centerOffset =
          (itemWidth + spacing) * selectedIndex - (screenWidth / 2.5) + (itemWidth / 2.5);

      _scrollController.jumpTo(
        centerOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mock.length,
        separatorBuilder: (_, __) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          return DayTaskInfo(
            date: mock[index]["date"] as DateTime,
            status: mock[index]["status"] as TaskStatus,
            isSelected: selectedIndex == index,
            onTap: () => setState(() => selectedIndex = index),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
