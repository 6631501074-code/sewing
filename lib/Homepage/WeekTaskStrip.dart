import 'package:flutter/material.dart';
import 'package:sewing/See work/work_job.dart';

import 'DayTaskInfo.dart';

class WeekTaskStrip extends StatefulWidget {
  final DateTime selectedDate;
  final List<WorkJob> jobs;
  final ValueChanged<DateTime> onDateSelected;

  const WeekTaskStrip({
    super.key,
    required this.selectedDate,
    required this.jobs,
    required this.onDateSelected,
  });

  @override
  State<WeekTaskStrip> createState() => _WeekTaskStripState();
}

class _WeekTaskStripState extends State<WeekTaskStrip> {
  late final List<DateTime> days;

  final ScrollController _scrollController = ScrollController();

  static const double itemWidth = 54;
  static const double spacing = 10;

  @override
  void initState() {
    super.initState();
    final today = _dayOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 3));
    days = List.generate(7, (i) => start.add(Duration(days: i)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDay();
    });
  }

  @override
  void didUpdateWidget(covariant WeekTaskStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(widget.selectedDate, oldWidget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerSelectedDay();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final date = days[index];
          return DayTaskInfo(
            date: date,
            status: _statusFor(date),
            isSelected: _sameDay(widget.selectedDate, date),
            onTap: () => widget.onDateSelected(date),
          );
        },
      ),
    );
  }

  TaskStatus _statusFor(DateTime date) {
    final dayJobs = widget.jobs.where((j) {
      final active =
          j.status == JobStatus.urgent ||
          j.status == JobStatus.doing ||
          j.status == JobStatus.confirming;
      return active && _sameDay(j.pickupDate, date);
    }).toList();

    if (dayJobs.any((j) => j.status == JobStatus.urgent)) {
      return TaskStatus.urgent;
    }
    if (dayJobs.isNotEmpty) {
      return TaskStatus.normal;
    }
    return TaskStatus.none;
  }

  void _centerSelectedDay() {
    if (!_scrollController.hasClients) return;
    final selectedIndex = days.indexWhere(
      (d) => _sameDay(d, widget.selectedDate),
    );
    if (selectedIndex < 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset =
        (itemWidth + spacing) * selectedIndex -
        (screenWidth / 2.5) +
        (itemWidth / 2.5);

    _scrollController.jumpTo(
      centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
