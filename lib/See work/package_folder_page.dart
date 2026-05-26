import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:sewing/Voice/garment_dialog.dart';
import 'package:sewing/Voice/mic_page.dart';

import 'jobs_repository.dart';
import 'package_pdf_exporter.dart';
import 'work_job.dart';
import 'work_job_detail_page.dart';

class PackageFolderPage extends StatefulWidget {
  final String folderId;
  final String folderName;

  const PackageFolderPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<PackageFolderPage> createState() => _PackageFolderPageState();
}

class _PackageFolderPageState extends State<PackageFolderPage> {
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  final _repo = JobsRepository(FirebaseFirestore.instance);
  bool _exporting = false;

  Future<void> _showCreateJobInFolder() async {
    final garmentType = await showGarmentDialog(context);
    if (!mounted || garmentType == null || garmentType == GarmentType.none) {
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MiccPage(
          packageFolderId: widget.folderId,
          packageFolderName: widget.folderName,
          initialGarmentType: garmentType,
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final snap = await _repo.getPackageFolderJobs(widget.folderId);
      final jobs = _activeJobsFromDocs(snap.docs);
      final shirtCount = jobs
          .where(
            (job) => packageJobMatchesGarment(job, PackageExportGarment.shirt),
          )
          .length;
      final pantsCount = jobs
          .where(
            (job) => packageJobMatchesGarment(job, PackageExportGarment.pants),
          )
          .length;

      if (!mounted) return;
      if (shirtCount == 0 && pantsCount == 0) {
        _toast('ไม่มีรายการสำหรับดาวน์โหลด');
        return;
      }

      final type = await _showDownloadTypeDialog(
        shirtCount: shirtCount,
        pantsCount: pantsCount,
      );
      if (!mounted || type == null) return;

      final selectedJobs = jobs
          .where((job) => packageJobMatchesGarment(job, type))
          .toList();

      if (selectedJobs.isEmpty) {
        _toast('ไม่มีรายการ${packageExportGarmentLabel(type)}');
        return;
      }

      setState(() => _exporting = true);
      final bytes = await buildPackageJobsPdf(
        folderName: widget.folderName,
        garmentType: type,
        jobs: selectedJobs,
      );
      await Printing.sharePdf(bytes: bytes, filename: _pdfFileName(type));
    } catch (e) {
      if (!mounted) return;
      _toast('ดาวน์โหลด PDF ไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<PackageExportGarment?> _showDownloadTypeDialog({
    required int shirtCount,
    required int pantsCount,
  }) {
    return showDialog<PackageExportGarment>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เลือกประเภท PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DownloadChoiceTile(
              title: 'เสื้อ',
              count: shirtCount,
              onTap: shirtCount == 0
                  ? null
                  : () => Navigator.pop(ctx, PackageExportGarment.shirt),
            ),
            const SizedBox(height: 8),
            _DownloadChoiceTile(
              title: 'กางเกง',
              count: pantsCount,
              onTap: pantsCount == 0
                  ? null
                  : () => Navigator.pop(ctx, PackageExportGarment.pants),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  List<WorkJob> _activeJobsFromDocs(List<QueryDocumentSnapshot> docs) {
    final jobs =
        docs
            .map((doc) => WorkJob.fromDoc(doc))
            .where(
              (job) =>
                  job.status == JobStatus.doing ||
                  job.status == JobStatus.urgent,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return jobs;
  }

  String _pdfFileName(PackageExportGarment type) {
    final folder = widget.folderName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|#]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final label = packageExportGarmentLabel(type);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${folder}_${label}_$stamp.pdf';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _text,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'งานเหมา',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              widget.folderName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _muted,
              ),
            ),
          ],
        ),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'ดาวน์โหลด PDF',
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download_rounded),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _repo.watchPackageFolderJobs(widget.folderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = _activeJobsFromDocs(snap.data!.docs);
          final shirts = jobs
              .where(
                (job) =>
                    packageJobMatchesGarment(job, PackageExportGarment.shirt),
              )
              .toList();
          final pants = jobs
              .where(
                (job) =>
                    packageJobMatchesGarment(job, PackageExportGarment.pants),
              )
              .toList();

          if (shirts.isEmpty && pants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีงาน',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กดปุ่มบวกเพื่อเพิ่มงาน',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (shirts.isNotEmpty) ...[
                _PackageTableSection(
                  title: 'เสื้อ',
                  type: PackageExportGarment.shirt,
                  jobs: shirts,
                  onOpenJob: _openJobDetail,
                ),
                const SizedBox(height: 16),
              ],
              if (pants.isNotEmpty)
                _PackageTableSection(
                  title: 'กางเกง',
                  type: PackageExportGarment.pants,
                  jobs: pants,
                  onOpenJob: _openJobDetail,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateJobInFolder,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _openJobDetail(WorkJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkJobDetailPage(jobId: job.id)),
    );
  }
}

class _DownloadChoiceTile extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;

  const _DownloadChoiceTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ListTile(
      enabled: enabled,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: const Color(0xFFF4F4F6),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(enabled ? '$count รายการ' : 'ไม่มีรายการ'),
      trailing: const Icon(Icons.picture_as_pdf_rounded),
      onTap: onTap,
    );
  }
}

class _PackageTableSection extends StatelessWidget {
  final String title;
  final PackageExportGarment type;
  final List<WorkJob> jobs;
  final ValueChanged<WorkJob> onOpenJob;

  const _PackageTableSection({
    required this.title,
    required this.type,
    required this.jobs,
    required this.onOpenJob,
  });

  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0x14111827);

  @override
  Widget build(BuildContext context) {
    final keys = packageMeasureKeys(type);
    final headers = ['ลำดับ', 'ชื่อ', ...keys, 'รายละเอียด'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: _text,
                ),
              ),
            ),
            Text(
              '${jobs.length} รายการ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: _muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF4F4F6),
                ),
                columnSpacing: 14,
                horizontalMargin: 12,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 72,
                columns: headers
                    .map(
                      (header) => DataColumn(
                        label: Text(
                          header,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: jobs.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final job = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(_cell(index.toString(), width: 42)),
                      DataCell(
                        _cell(
                          job.customerName.isEmpty ? '-' : job.customerName,
                          width: 120,
                          align: TextAlign.left,
                        ),
                        onTap: () => onOpenJob(job),
                      ),
                      ...keys.map(
                        (key) => DataCell(
                          _cell(packageMeasureValue(job, key), width: 58),
                          onTap: () => onOpenJob(job),
                        ),
                      ),
                      DataCell(
                        _cell(
                          job.notes.isEmpty ? '-' : job.notes,
                          width: 180,
                          align: TextAlign.left,
                        ),
                        onTap: () => onOpenJob(job),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    required double width,
    TextAlign align = TextAlign.center,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _text,
          fontSize: 13,
        ),
      ),
    );
  }
}
