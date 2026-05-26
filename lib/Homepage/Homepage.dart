import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sewing/See work/jobs_repository.dart';
import 'package:sewing/See work/work_job.dart';
import 'package:sewing/See work/work_job_detail_page.dart';

import 'DailyChallengeCard.dart';
import 'WeekTaskStrip.dart';
import 'task_card.dart' as home_task;
import 'task_section.dart';

class Homepage extends StatefulWidget {
  final VoidCallback? onOpenWorkQueue;

  const Homepage({super.key, this.onOpenWorkQueue});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final String name = "Preecha S.";
  final ScrollController _taskScroll = ScrollController();
  final TextEditingController _searchC = TextEditingController();
  final _repo = JobsRepository(FirebaseFirestore.instance);

  double _titleOpacity = 1.0;
  late DateTime _selectedDate;
  String _q = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

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
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayText = DateFormat('dd MMM', 'th_TH').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _repo.watchQueueJobs(),
          builder: (context, snap) {
            final allJobs = snap.hasData
                ? snap.data!.docs.map((d) => WorkJob.fromDoc(d)).toList()
                : <WorkJob>[];
            final activeJobs = allJobs
                .where(
                  (j) =>
                      j.status == JobStatus.urgent ||
                      j.status == JobStatus.doing ||
                      j.status == JobStatus.confirming,
                )
                .toList();
            final selectedJobs = _filteredJobsForSelectedDay(activeJobs);
            final taskItems = _toTaskItems(selectedJobs);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(name: name, todayText: todayText),
                  const SizedBox(height: 18),
                  DailyChallengeCard(pendingCount: activeJobs.length),
                  const SizedBox(height: 18),
                  WeekTaskStrip(
                    selectedDate: _selectedDate,
                    jobs: activeJobs,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SearchBox(
                    controller: _searchC,
                    onChanged: (v) =>
                        setState(() => _q = v.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _titleOpacity,
                          child: Text(
                            _sameDay(_selectedDate, DateTime.now())
                                ? 'งานวันนี้'
                                : DateFormat(
                                    'EEE, dd MMM',
                                    'th_TH',
                                  ).format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onOpenWorkQueue,
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text('ดูทั้งหมด'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _TaskBody(
                      loading: !snap.hasData && !snap.hasError,
                      error: snap.hasError,
                      date: _selectedDate,
                      taskItems: taskItems,
                      onTaskTap: (task) {
                        if (task.id.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkJobDetailPage(jobId: task.id),
                          ),
                        );
                      },
                      controller: _taskScroll,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<WorkJob> _filteredJobsForSelectedDay(List<WorkJob> jobs) {
    var filtered = jobs
        .where((j) => _sameDay(j.pickupDate, _selectedDate))
        .toList();

    if (_q.isNotEmpty) {
      filtered = filtered.where((j) => _matchesQuery(j, _q)).toList();
    }

    filtered.sort((a, b) {
      final statusCompare = _statusWeight(
        a.status,
      ).compareTo(_statusWeight(b.status));
      if (statusCompare != 0) return statusCompare;
      return a.pickupDate.compareTo(b.pickupDate);
    });

    return filtered;
  }

  List<TaskItem> _toTaskItems(List<WorkJob> jobs) {
    return jobs.asMap().entries.map((entry) {
      final index = entry.key;
      final job = entry.value;
      return TaskItem(
        id: job.id,
        title: job.title.isNotEmpty ? job.title : '#${job.jobId}',
        tailorName:
            '${workCategoryLabel(job.category)} • ${job.customerName} • ${job.customerPhone}',
        status: _toHomeTaskStatus(job.status),
        imagePath: 'asset/img/user.png',
        priorityLabel: index == 0 && jobs.length > 1 ? 'ต้องทำก่อน' : '',
      );
    }).toList();
  }

  home_task.TaskStatus _toHomeTaskStatus(JobStatus status) {
    switch (status) {
      case JobStatus.urgent:
        return home_task.TaskStatus.urgent;
      case JobStatus.confirming:
        return home_task.TaskStatus.confirming;
      case JobStatus.done:
        return home_task.TaskStatus.done;
      case JobStatus.doing:
        return home_task.TaskStatus.doing;
    }
  }

  int _statusWeight(JobStatus status) {
    switch (status) {
      case JobStatus.urgent:
        return 0;
      case JobStatus.doing:
        return 1;
      case JobStatus.confirming:
        return 2;
      case JobStatus.done:
        return 3;
    }
  }

  bool _matchesQuery(WorkJob job, String q) {
    final text = [
      job.title,
      job.jobId,
      job.customerName,
      job.customerPhone,
      job.packageName,
      workCategoryLabel(job.category),
    ].join(' ').toLowerCase();
    return text.contains(q);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final String todayText;

  const _TopBar({required this.name, required this.todayText});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                "สวัสดี, $name",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "วันนี้ $todayText",
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
          child: IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'ค้นหางาน ชื่อลูกค้า หรือเบอร์โทร',
        hintStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F4F6),
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x14111827)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x33111827)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _TaskBody extends StatelessWidget {
  final bool loading;
  final bool error;
  final DateTime date;
  final List<TaskItem> taskItems;
  final ValueChanged<TaskItem> onTaskTap;
  final ScrollController controller;

  const _TaskBody({
    required this.loading,
    required this.error,
    required this.date,
    required this.taskItems,
    required this.onTaskTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error) {
      return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
    }
    if (taskItems.isEmpty) {
      return const Center(child: Text('ไม่พบงานในช่วงนี้'));
    }

    return ListView(
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        TaskSection(date: date, tasks: taskItems, onTaskTap: onTaskTap),
        const SizedBox(height: 16),
      ],
    );
  }
}
