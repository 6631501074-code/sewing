import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'jobs_repository.dart';
import 'work_job.dart';
import 'work_job_detail_page.dart';

class WorkHistoryPage extends StatefulWidget {
  const WorkHistoryPage({super.key});

  @override
  State<WorkHistoryPage> createState() => _WorkHistoryPageState();
}

class _WorkHistoryPageState extends State<WorkHistoryPage> {
  final _repo = JobsRepository(FirebaseFirestore.instance);
  final _searchC = TextEditingController();

  String _q = '';
  WorkCategory? _categoryFilter;

  static const _text = Color(0xFF111827);

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
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SearchBox(
              controller: _searchC,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _CategoryFilter(
              selected: _categoryFilter,
              onChanged: (value) => setState(() => _categoryFilter = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _repo.watchDoneJobs(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var jobs = snap.data!.docs
                    .map((d) => WorkJob.fromDoc(d))
                    .where((j) => j.status == JobStatus.done)
                    .toList();

                if (_categoryFilter != null) {
                  jobs = jobs
                      .where((j) => j.category == _categoryFilter)
                      .toList();
                }

                if (_q.isNotEmpty) {
                  jobs = jobs.where((j) => _matchesQuery(j, _q)).toList();
                }

                if (jobs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีประวัติงาน'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _HistoryJobCard(
                      job: job,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkJobDetailPage(jobId: job.id),
                          ),
                        );
                      },
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
        hintText: 'ค้นหา History',
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

class _CategoryFilter extends StatelessWidget {
  final WorkCategory? selected;
  final ValueChanged<WorkCategory?> onChanged;

  const _CategoryFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'ทั้งหมด',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'งานรายวัน',
          selected: selected == WorkCategory.daily,
          onTap: () => onChanged(WorkCategory.daily),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'งานเหมา',
          selected: selected == WorkCategory.package,
          onTap: () => onChanged(WorkCategory.package),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111827) : const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14111827)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryJobCard extends StatelessWidget {
  final WorkJob job;
  final VoidCallback onTap;

  const _HistoryJobCard({required this.job, required this.onTap});

  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0x14111827);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(job.pickupDate);

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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33047857)),
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF047857)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title.isNotEmpty ? job.title : '#${job.jobId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  Text(
                    '${workCategoryLabel(job.category)} • เสร็จแล้ว • วันรับ: $date',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
