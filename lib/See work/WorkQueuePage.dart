import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'jobs_repository.dart';
import 'work_job.dart';
import 'work_job_detail_page.dart';
import 'create_job_dialog.dart';
import 'package_folder_dialog.dart';
import 'package_folder_page.dart';
import 'package:sewing/Voice/mic_page.dart';

class WorkQueuePage extends StatefulWidget {
  final VoidCallback? onOpenConfirmation;

  const WorkQueuePage({super.key, this.onOpenConfirmation});

  @override
  State<WorkQueuePage> createState() => _WorkQueuePageState();
}

class _WorkQueuePageState extends State<WorkQueuePage> {
  static const _text = Color(0xFF111827);

  final _repo = JobsRepository(FirebaseFirestore.instance);
  final _searchC = TextEditingController();

  String _q = '';
  WorkCategory? _categoryFilter;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _handleCreateJob() async {
    final result = await showCreateJobDialog(context);
    if (!mounted || result == null) return;

    if (result == CreateJobResult.daily) {
      // ✅ งานรายวัน - ไปหน้าวัดตัว
      if (!mounted) return;
      // ใช้ Navigator.push เพื่อไปหน้าวัดตัวโดยตรง
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MiccPage()),
      );
    } else if (result == CreateJobResult.package) {
      // ✅ งานเหมา - ขอชื่อโฟลเดอร์
      if (!mounted) return;
      final folderName = await showPackageFolderDialog(context);
      if (!mounted || folderName == null) return;

      try {
        final folderId = await _repo.createPackageFolder(folderName);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PackageFolderPage(folderId: folderId, folderName: folderName),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('สร้างโฟลเดอร์ไม่สำเร็จ: $e')));
      }
    }
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
          'รายการงาน',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _CategoryFilter(
              selected: _categoryFilter,
              onChanged: (value) => setState(() => _categoryFilter = value),
            ),
          ),

          // ✅ List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _repo.watchQueueJobs(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final showFolders =
                    _categoryFilter == null ||
                    _categoryFilter == WorkCategory.package;
                final showDailyJobs =
                    _categoryFilter == null ||
                    _categoryFilter == WorkCategory.daily;

                var jobs = snap.data!.docs
                    .map((d) => WorkJob.fromDoc(d))
                    .where(
                      (j) =>
                          j.status == JobStatus.doing ||
                          j.status == JobStatus.urgent,
                    )
                    .where(
                      (j) => showDailyJobs && j.category == WorkCategory.daily,
                    )
                    .toList();

                if (_q.isNotEmpty) {
                  jobs = jobs.where((j) => _matchesJobQuery(j, _q)).toList();
                }

                if (!showFolders) {
                  return _buildQueueList(jobs: jobs, folders: const []);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _repo.watchPackageFolders(),
                  builder: (context, folderSnap) {
                    if (folderSnap.hasError) {
                      return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
                    }
                    if (!folderSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var folders = folderSnap.data!.docs
                        .map((d) => _PackageFolder.fromDoc(d))
                        .toList();

                    if (_q.isNotEmpty) {
                      folders = folders
                          .where(
                            (folder) => folder.name.toLowerCase().contains(_q),
                          )
                          .toList();
                    }

                    return _buildQueueList(jobs: jobs, folders: folders);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateJob,
        backgroundColor: Colors.blueAccent,
        tooltip: 'เพิ่มงานใหม่',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  bool _matchesJobQuery(WorkJob job, String q) {
    final text = [
      job.customerName,
      job.customerPhone,
      job.jobId,
      job.title,
      job.packageName,
      workCategoryLabel(job.category),
    ].join(' ').toLowerCase();
    return text.contains(q);
  }

  Widget _buildQueueList({
    required List<WorkJob> jobs,
    required List<_PackageFolder> folders,
  }) {
    final grouped = _groupByDate(jobs);

    if (folders.isEmpty && grouped.isEmpty) {
      return const Center(child: Text('ไม่พบรายการ'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        if (folders.isNotEmpty) ...[
          const _SectionHeader(label: 'โฟลเดอร์งานเหมา'),
          const SizedBox(height: 10),
          ...folders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PackageFolderCard(
                folder: folder,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackageFolderPage(
                        folderId: folder.id,
                        folderName: folder.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        ...grouped.map((entry) {
          final day = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(date: day),
              const SizedBox(height: 10),
              ...items.map(
                (j) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _JobCard(
                    job: j,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkJobDetailPage(
                            jobId: j.id,
                            onAccepted: widget.onOpenConfirmation,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          );
        }),
      ],
    );
  }

  List<MapEntry<DateTime, List<WorkJob>>> _groupByDate(List<WorkJob> jobs) {
    final map = <DateTime, List<WorkJob>>{};
    for (final j in jobs) {
      final d = DateTime(
        j.pickupDate.year,
        j.pickupDate.month,
        j.pickupDate.day,
      );
      map.putIfAbsent(d, () => []).add(j);
    }
    for (final items in map.values) {
      items.sort((a, b) {
        final statusCompare = _statusWeight(
          a.status,
        ).compareTo(_statusWeight(b.status));
        if (statusCompare != 0) return statusCompare;
        return a.pickupDate.compareTo(b.pickupDate);
      });
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
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

class _PackageFolder {
  final String id;
  final String name;

  const _PackageFolder({required this.id, required this.name});

  factory _PackageFolder.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return _PackageFolder(
      id: doc.id,
      name: (data['name'] ?? doc.id).toString(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _PackageFolderCard extends StatelessWidget {
  final _PackageFolder folder;
  final VoidCallback onTap;

  const _PackageFolderCard({required this.folder, required this.onTap});

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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x331D4ED8)),
              ),
              child: const Icon(
                Icons.folder_special_rounded,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _text,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เปิดรายการงานในโฟลเดอร์',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final text = DateFormat('EEE, dd MMM', 'th_TH').format(date);
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
    final detailText = job.packageName.isNotEmpty
        ? 'งานเหมา: ${job.packageName}'
        : workCategoryLabel(job.category);

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
                          detailText,
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
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.checkroom_rounded, color: Color(0xFF9CA3AF)),
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
        label = 'ด่วน';
        fg = const Color(0xFFB42318);
        bg = const Color(0xFFFFF1F1);
        border = const Color(0x33B42318);
        break;
      case JobStatus.doing:
        label = 'กำลังทำ';
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFF0F6FF);
        border = const Color(0x331D4ED8);
        break;
      case JobStatus.confirming:
        label = 'รอยืนยัน';
        fg = const Color(0xFF92400E);
        bg = const Color(0xFFFFFBEB);
        border = const Color(0x3392400E);
        break;
      case JobStatus.done:
        label = 'เสร็จแล้ว';
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
