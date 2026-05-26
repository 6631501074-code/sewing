import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'jobs_repository.dart';
import 'work_job.dart';
import 'work_job_detail_page.dart';

class WorkConfirmationPage extends StatefulWidget {
  const WorkConfirmationPage({super.key});

  @override
  State<WorkConfirmationPage> createState() => _WorkConfirmationPageState();
}

class _WorkConfirmationPageState extends State<WorkConfirmationPage> {
  final _repo = JobsRepository(FirebaseFirestore.instance);
  final _saving = <String>{};

  static const _text = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _text,
        title: const Text(
          'ยืนยันการทำงาน',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _repo.watchConfirmationJobs(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snap.data!.docs
              .map((d) => WorkJob.fromDoc(d))
              .where((j) => j.status == JobStatus.confirming)
              .toList();

          if (jobs.isEmpty) {
            return const Center(child: Text('ยังไม่มีงานที่รอยืนยัน'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final isSaving = _saving.contains(job.id);

              return _ConfirmJobCard(
                job: job,
                isSaving: isSaving,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkJobDetailPage(jobId: job.id),
                    ),
                  );
                },
                onDone: isSaving
                    ? null
                    : () async {
                        setState(() => _saving.add(job.id));
                        try {
                          await _repo.markDone(job.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ส่งงานเข้า History แล้ว'),
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ยืนยันงานไม่สำเร็จ')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _saving.remove(job.id));
                          }
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConfirmJobCard extends StatelessWidget {
  final WorkJob job;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback? onDone;

  const _ConfirmJobCard({
    required this.job,
    required this.isSaving,
    required this.onTap,
    required this.onDone,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title.isNotEmpty ? job.title : '#${job.jobId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const _PendingPill(),
              ],
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
              'วันรับ: $date',
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onDone,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  isSaving ? 'กำลังยืนยัน...' : 'ยืนยันว่างานนี้เสร็จแล้ว',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x3392400E)),
      ),
      child: const Text(
        'รอยืนยัน',
        style: TextStyle(
          color: Color(0xFF92400E),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
