import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sewing/Voice/garment_dialog.dart';
import 'package:sewing/Voice/mic_page.dart';

import 'jobs_repository.dart';
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

  Future<void> _showCreateJobInFolder() async {
    // เลือกประเภทเสื้อผ้า
    final garmentType = await showGarmentDialog(context);
    if (!mounted || garmentType == null || garmentType == GarmentType.none) {
      return;
    }

    // ไปหน้าวัดตัว พร้อมส่ง folderId สำหรับสร้างงานในโฟลเดอร์
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

          final docs = snap.data!.docs;
          final jobs = docs
              .map((d) => WorkJob.fromDoc(d))
              .where(
                (j) =>
                    j.status == JobStatus.doing || j.status == JobStatus.urgent,
              )
              .toList();

          if (jobs.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final j = jobs[index];
              final pickupDate = DateFormat('dd/MM/yyyy').format(j.pickupDate);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkJobDetailPage(jobId: j.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x14111827)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j.title.isNotEmpty ? j.title : j.jobId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: _text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${j.customerName} • $pickupDate',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: j.status == JobStatus.urgent
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                jobStatusLabel(j.status),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: j.status == JobStatus.urgent
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
}
