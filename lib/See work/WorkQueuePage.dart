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

  enum _StatusFilter { all, doing, urgent, overdue, done }
  enum _CategoryFilter { all, daily, package }

  class _WorkQueuePageState extends State<WorkQueuePage> {
    static const _text = Color(0xFF111827);
    static const _muted = Color(0xFF6B7280);
    static const _line = Color(0x14111827);

    final _repo = JobsRepository(FirebaseFirestore.instance);
    final _searchC = TextEditingController();

    String _q = '';
    _StatusFilter _statusFilter = _StatusFilter.all;
    _CategoryFilter _categoryFilter = _CategoryFilter.all;

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
            // Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _StatusFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Doing', _StatusFilter.doing),
                    const SizedBox(width: 8),
                    _buildFilterChip('Urgent', _StatusFilter.urgent),
                    const SizedBox(width: 8),
                    _buildFilterChip('Overdue', _StatusFilter.overdue),
                    const SizedBox(width: 8),
                    _buildFilterChip('Done', _StatusFilter.done),
                    const SizedBox(width: 14),
                    _buildCategoryChip('รายวัน', _CategoryFilter.daily),
                    const SizedBox(width: 8),
                    _buildCategoryChip('งานเหมา', _CategoryFilter.package),
                  ],
                ),
              ),
            ),

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
                  debugPrint('JOBS COUNT = ${docs.length}');
                  var jobs = docs.map((d) => WorkJob.fromDoc(d)).toList();
                  jobs.sort((a, b) => a.pickupDate.compareTo(b.pickupDate));

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
                  jobs = _applyStatusFilter(jobs);
                  jobs = _applyCategoryFilter(jobs);
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
                          ...items.map((j) => Dismissible(
                                key: ValueKey(j.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => _confirmDelete(context, j),
                                onDismissed: (_) => _repo.deleteJob(j.id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0x33B42318)),
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Color(0xFFB42318)),
                                ),
                                child: Padding(
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

    List<WorkJob> _applyStatusFilter(List<WorkJob> jobs) {
      switch (_statusFilter) {
        case _StatusFilter.all:
          return jobs;
        case _StatusFilter.doing:
          return jobs
              .where((j) => j.status == JobStatus.doing && !_isOverdueDate(j.pickupDate, j.status))
              .toList();
        case _StatusFilter.urgent:
          return jobs
              .where((j) => j.status == JobStatus.urgent && !_isOverdueDate(j.pickupDate, j.status))
              .toList();
        case _StatusFilter.overdue:
          return jobs.where((j) => _isOverdueDate(j.pickupDate, j.status)).toList();
        case _StatusFilter.done:
          return jobs.where((j) => j.status == JobStatus.done).toList();
      }
    }

    List<WorkJob> _applyCategoryFilter(List<WorkJob> jobs) {
      switch (_categoryFilter) {
        case _CategoryFilter.all:
          return jobs;
        case _CategoryFilter.daily:
          return jobs.where((j) => j.category == WorkCategory.daily).toList();
        case _CategoryFilter.package:
          return jobs.where((j) => j.category == WorkCategory.package).toList();
      }
    }

    Widget _buildFilterChip(String label, _StatusFilter value) {
      final selected = _statusFilter == value;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: Colors.black.withOpacity(0.08),
        backgroundColor: const Color(0xFFF4F4F6),
        side: const BorderSide(color: _line),
      );
    }

    Widget _buildCategoryChip(String label, _CategoryFilter value) {
      final selected = _categoryFilter == value;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = selected ? _CategoryFilter.all : value),
        selectedColor: Colors.black.withOpacity(0.08),
        backgroundColor: const Color(0xFFF4F4F6),
        side: const BorderSide(color: _line),
      );
    }

    Future<bool> _confirmDelete(BuildContext context, WorkJob job) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ลบรายการนี้?'),
          content: Text('ต้องการลบงานของ ${job.customerName.isEmpty ? 'ลูกค้า' : job.customerName} ใช่ไหม'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
  }

  bool _isOverdueDate(DateTime pickupDate, JobStatus status) {
    if (status == JobStatus.done) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return pickupDate.isBefore(today);
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
      final pickupText = DateFormat('dd MMM').format(job.pickupDate);
      final isOverdue = _isOverdueDate(job.pickupDate, job.status);
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
                            job.title.isNotEmpty
                                ? job.title
                                : (job.customerName.isNotEmpty ? job.customerName : '#${job.jobId}'),
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

                    // pickup date + status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pickup: $pickupText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _muted.withOpacity(0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _StatusChip(status: job.status, isOverdue: isOverdue),
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
    final bool isOverdue;
    const _StatusChip({required this.status, required this.isOverdue});

    @override
    Widget build(BuildContext context) {
      late final String label;
      late final Color fg;
      late final Color bg;
      late final Color border;

      if (isOverdue) {
        label = 'Overdue';
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFFF3E0);
        border = const Color(0x33B45309);
      } else {
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
