import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'jobs_repository.dart';
import 'work_job.dart';
import 'work_job_detail_page.dart';

class WorkQueuePage extends StatefulWidget {
  const WorkQueuePage({super.key});

  @override
  State<WorkQueuePage> createState() => _WorkQueuePageState();
}

class _WorkQueuePageState extends State<WorkQueuePage> {
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0x14111827);

  final _repo = JobsRepository(FirebaseFirestore.instance);
  final _searchC = TextEditingController();

  String _q = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _text,
        title: const Text('รายการงาน', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          // ✅ Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SearchBox(
              controller: _searchC,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),

          // ✅ List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _repo.watchActiveJobs(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                var jobs = docs.map((d) => WorkJob.fromDoc(d)).toList();

                // ✅ filter by search (name OR jobId OR title)
                if (_q.isNotEmpty) {
                  jobs = jobs.where((j) {
                    final name = j.customerName.toLowerCase();
                    final id = j.jobId.toLowerCase();
                    final title = j.title.toLowerCase();
                    return name.contains(_q) || id.contains(_q) || title.contains(_q);
                  }).toList();
                }

                // ✅ group by pickup date (ตัดเวลา)
                final grouped = _groupByDate(jobs);

                if (grouped.isEmpty) {
                  return const Center(child: Text('ไม่พบรายการ'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    final day = entry.key;
                    final items = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DayHeader(date: day),
                        const SizedBox(height: 10),
                        ...items.map((j) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _JobCard(
                                job: j,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkJobDetailPage(jobId: j.id),
                                    ),
                                  );
                                },
                              ),
                            )),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<DateTime, List<WorkJob>>> _groupByDate(List<WorkJob> jobs) {
    final map = <DateTime, List<WorkJob>>{};
    for (final j in jobs) {
      final d = DateTime(j.pickupDate.year, j.pickupDate.month, j.pickupDate.day);
      map.putIfAbsent(d, () => []).add(j);
    }
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  static const _bg = Color(0xFFF4F4F6);
  static const _line = Color(0x14111827);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'ค้นหา ชื่อ หรือ ID งาน',
        hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: _bg,
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.25)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final text = DateFormat('EEE, dd MMM', 'en_US').format(date);
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final WorkJob job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0x14111827);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            _GarmentAvatar(garmentType: job.garmentType),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title + id
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title.isNotEmpty ? job.title : '#${job.jobId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(category: job.category),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // customer name + phone
                  Text(
                    '${job.customerName} • ${job.customerPhone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // tailor + status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tailor: ${job.customerName.isEmpty ? '-' : job.customerName}', // ถ้าคุณมี field tailorName ให้เปลี่ยนเป็น tailorName
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _muted.withOpacity(0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _StatusChip(status: job.status),
                    ],
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

class _GarmentAvatar extends StatelessWidget {
  final String garmentType;
  const _GarmentAvatar({required this.garmentType});

  static const _line = Color(0x14111827);

  @override
  Widget build(BuildContext context) {
    // ✅ ใช้รูปแทน: ใส่ asset ของคุณเอง
    // ตัวอย่าง:
    // assets/icons/pants.png
    // assets/icons/shirt.png
    final isPants = garmentType.toLowerCase().contains('pants');

    final assetPath = isPants
        ? 'assets/icons/pants.png'
        : 'assets/icons/shirt.png';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.checkroom_rounded, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final WorkCategory category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = workCategoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final JobStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == JobStatus.done) return const SizedBox.shrink();

    late final String label;
    late final Color fg;
    late final Color bg;
    late final Color border;

    switch (status) {
      case JobStatus.urgent:
        label = 'Urgent';
        fg = const Color(0xFFB42318);
        bg = const Color(0xFFFFF1F1);
        border = const Color(0x33B42318);
        break;
      case JobStatus.doing:
        label = 'Doing';
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFF0F6FF);
        border = const Color(0x331D4ED8);
        break;
      case JobStatus.done:
        label = 'Done';
        fg = const Color(0xFF047857);
        bg = const Color(0xFFECFDF5);
        border = const Color(0x33047857);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: fg),
      ),
    );
  }
}
