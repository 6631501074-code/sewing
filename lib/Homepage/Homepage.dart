import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'DailyChallengeCard.dart';
import 'WeekTaskStrip.dart';
import 'task_section.dart';
import 'mock_tasks.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final String name = "Preecha S.";
  final ScrollController _taskScroll = ScrollController();
  double _titleOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    _taskScroll.addListener(() {
      final offset = _taskScroll.offset;
      final newOpacity = (1 - (offset / 40)).clamp(0.0, 1.0);
      if (newOpacity != _titleOpacity) {
        setState(() => _titleOpacity = newOpacity);
      }
    });
  }

  @override
  void dispose() {
    _taskScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayText = DateFormat('dd MMM.').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TOP BAR (ไม่เลื่อน) =====
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: const AssetImage('asset/img/user.png'),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Hello, $name",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Today $todayText",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ===== DAILY CHALLENGE (ไม่เลื่อน) =====
              const DailyChallengeCard(),

              const SizedBox(height: 18),

              // ===== WEEK STRIP (ไม่เลื่อน) =====
              const WeekTaskStrip(),

              const SizedBox(height: 18),

              // ===== TITLE (จางตามการเลื่อน task) =====
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _titleOpacity,
                child: const Text(
                  "Today's Task",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ ตรงนี้เท่านั้นที่ “เลื่อน”
              Expanded(
                child: ListView(
                  controller: _taskScroll,
                  padding: EdgeInsets.zero,
                  children: [
                    StreamBuilder<List<TaskItem>>(
                      stream: watchHomepageTasks(FirebaseFirestore.instance),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Text('Failed to load tasks');
                        }
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return TaskSection(date: DateTime.now(), tasks: snap.data!);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
