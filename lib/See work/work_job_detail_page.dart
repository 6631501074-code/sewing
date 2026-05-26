import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'jobs_repository.dart';
import 'work_job.dart';

class WorkJobDetailPage extends StatefulWidget {
  final String jobId; // docId
  final VoidCallback? onAccepted;

  const WorkJobDetailPage({super.key, required this.jobId, this.onAccepted});

  @override
  State<WorkJobDetailPage> createState() => _WorkJobDetailPageState();
}

class _WorkJobDetailPageState extends State<WorkJobDetailPage> {
  bool _saving = false;

  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final repo = JobsRepository(FirebaseFirestore.instance);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _text,
        title: const Text(
          'รายละเอียดงาน',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: repo.getJob(widget.jobId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('โหลดไม่สำเร็จ'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = WorkJob.fromDoc(snap.data!);

          String d(DateTime x) => DateFormat('dd/MM/yyyy').format(x);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title.isNotEmpty ? job.title : '#${job.jobId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${job.customerName} • ${job.customerPhone}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          label: 'หมวดหมู่: ${workCategoryLabel(job.category)}',
                        ),
                        _Pill(label: 'สถานะ: ${jobStatusLabel(job.status)}'),
                        _Pill(label: 'วันนัด: ${d(job.appointmentDate)}'),
                        _Pill(label: 'วันรับ: ${d(job.pickupDate)}'),
                        if (job.packageName.isNotEmpty)
                          _Pill(label: 'งานเหมา: ${job.packageName}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'ค่าที่วัด',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _text.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 8),

              _Card(
                child: Column(
                  children: job.measures.entries.map((e) {
                    final v = (e.value ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _muted,
                              ),
                            ),
                          ),
                          Text(
                            v.isEmpty ? '-' : v,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              if (job.status == JobStatus.doing ||
                  job.status == JobStatus.urgent)
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await repo.moveToConfirmation(job.id);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              widget.onAccepted?.call();
                            } catch (_) {
                              if (!context.mounted) return;
                              setState(() => _saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ย้ายงานไม่สำเร็จ'),
                                ),
                              );
                            }
                          },
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add_check_rounded),
                    label: Text(_saving ? 'กำลังบันทึก...' : 'จะทำรายการนี้'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  static const _line = Color(0x14111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  static const _bg = Color(0xFFF4F4F6);
  static const _line = Color(0x14111827);
  static const _text = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: _text,
          fontSize: 12,
        ),
      ),
    );
  }
}
