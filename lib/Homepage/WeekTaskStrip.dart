import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sewing/See work/work_job_detail_page.dart';
import 'package:sewing/session/user_session.dart';

import 'DayTaskInfo.dart';
import 'mock_tasks.dart';
import 'task_card.dart';
import 'task_section.dart';

class WeekTaskStrip extends StatefulWidget {
  const WeekTaskStrip({super.key});

  @override
  State<WeekTaskStrip> createState() => _WeekTaskStripState();
}

class _WeekTaskStripState extends State<WeekTaskStrip> {
  final ScrollController _scrollController = ScrollController();
  static const double itemWidth = 54;
  static const double spacing = 10;

  late final DateTime _startDate;
  late DateTime _selectedDate;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = today.subtract(const Duration(days: 3));
    _selectedDate = today;
    _loadUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final centerOffset =
          (itemWidth + spacing) * 3 - (screenWidth / 2.5) + (itemWidth / 2.5);

      _scrollController.jumpTo(
        centerOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  Future<void> _loadUser() async {
    final user = await UserSession.getUsername();
    if (!mounted) return;
    setState(() => _userId = user);
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(7, (i) => _startDate.add(Duration(days: i)));

    return SizedBox(
      height: 88,
      child: StreamBuilder<List<TaskItem>>(
        stream: _userId == null
            ? const Stream.empty()
            : watchHomepageTasks(FirebaseFirestore.instance, userId: _userId!),
        builder: (context, snap) {
          final tasks = snap.data ?? const <TaskItem>[];
          final byDate = _groupByDate(tasks);

          return ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final date = dates[index];
              final dayTasks = byDate[_normalizeDate(date)] ?? const <TaskItem>[];
              final status = _dayStatus(dayTasks);
              final selected = _isSameDate(date, _selectedDate);

              return DayTaskInfo(
                date: date,
                status: status,
                isSelected: selected,
                onTap: () {
                  setState(() => _selectedDate = date);
                  _openDayTasks(context, date, dayTasks);
                },
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<TaskItem>> _groupByDate(List<TaskItem> tasks) {
    final map = <DateTime, List<TaskItem>>{};
    for (final t in tasks) {
      final d = _normalizeDate(t.pickupDate);
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }

  DayStatus _dayStatus(List<TaskItem> tasks) {
    if (tasks.isEmpty) return DayStatus.none;
    if (tasks.any((t) => t.status == TaskStatus.overdue)) return DayStatus.overdue;
    if (tasks.any((t) => t.status == TaskStatus.urgent)) return DayStatus.urgent;
    if (tasks.any((t) => t.status == TaskStatus.doing)) return DayStatus.normal;
    return DayStatus.done;
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openDayTasks(
    BuildContext context,
    DateTime date,
    List<TaskItem> tasks,
  ) async {
    final title = DateFormat('EEE, dd MMM', 'th_TH').format(date);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'ไม่มีงานในวันนี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = tasks[index];
                        return TaskCard(
                          title: t.title,
                          tailorName: t.tailorName,
                          status: t.status,
                          imagePath: t.imagePath,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkJobDetailPage(jobId: t.jobId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
