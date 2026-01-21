  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/services.dart';
  import 'package:intl/intl.dart';

  import 'jobs_repository.dart';
  import 'work_job.dart';

  class WorkJobDetailPage extends StatelessWidget {
    final String jobId; // docId
    const WorkJobDetailPage({super.key, required this.jobId});

    static const _text = Color(0xFF111827);
    static const _muted = Color(0xFF6B7280);
    static const _line = Color(0x0F111827);
    static const _bg = Color(0xFFFAFAFB);
    static const _card = Color(0xFFFFFFFF);
    static const _chip = Color(0xFFF6F7F9);
    static const _danger = Color(0xFFEF4444);

    @override
    Widget build(BuildContext context) {
      final repo = JobsRepository(FirebaseFirestore.instance);

      return StreamBuilder<DocumentSnapshot>(
        stream: repo.watchJob(jobId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(context, repo, null),
              body: const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
            );
          }
          if (!snap.hasData) {
            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(context, repo, null),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final job = WorkJob.fromDoc(snap.data!);
          String d(DateTime x) => DateFormat('dd/MM/yyyy').format(x);
          final name = job.customerName.isNotEmpty ? job.customerName : '-';
          final phone = job.customerPhone.isNotEmpty ? job.customerPhone : '-';

          return Scaffold(
            backgroundColor: _bg,
            appBar: _buildAppBar(context, repo, job),
            body: RefreshIndicator(
              onRefresh: () => repo.refreshJob(jobId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title.isNotEmpty
                              ? job.title
                              : (job.customerName.isNotEmpty ? job.customerName : '#${job.jobId}'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลูกค้า: $name  โทร: $phone',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: _muted),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(label: 'ประเภทงาน: ${workCategoryLabel(job.category)}'),
                            _Pill(label: 'วันนัดหมาย: ${d(job.appointmentDate)}'),
                            _Pill(label: 'วันรับชุด: ${d(job.pickupDate)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'ขนาดตัว / สัดส่วน',
                    style: TextStyle(fontWeight: FontWeight.w900, color: _text.withOpacity(0.85)),
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
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: _muted),
                                ),
                              ),
                              Text(
                                v.isEmpty ? '-' : v,
                                style: const TextStyle(fontWeight: FontWeight.w900, color: _text),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    AppBar _buildAppBar(BuildContext context, JobsRepository repo, WorkJob? job) {
      return AppBar(
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _text,
        title: const Text('รายละเอียดงาน', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: job == null
            ? null
            : [
                IconButton(
                  tooltip: 'ยืนยันงานเสร็จ',
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: job.status == JobStatus.done
                      ? null
                      : () => _confirmDone(context, repo, job),
                ),
                IconButton(
                  tooltip: 'แก้ไข',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _onEdit(context, repo, job),
                ),
                IconButton(
                  tooltip: 'ลบ',
                  icon: const Icon(Icons.delete_outline, color: _danger),
                  onPressed: () => _onDelete(context, repo, job),
                ),
              ],
      );
    }

    Future<void> _onEdit(BuildContext context, JobsRepository repo, WorkJob job) async {
      final result = await showDialog<_EditJobResult>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _EditJobDialog(job: job),
      );
      if (result == null) return;

      await repo.updateJob(job.id, {
        'title': result.title,
        'name': result.name,
        'customerName': result.name,
        'phone': result.phone,
        'customerPhone': result.phone,
        'category': result.category.name,
        'appointmentDate': Timestamp.fromDate(result.appointmentDate),
        'pickupDate': Timestamp.fromDate(result.pickupDate),
      });
    }

    Future<void> _onDelete(BuildContext context, JobsRepository repo, WorkJob job) async {
      final shouldDelete = await _confirmDelete(context, job);
      if (!shouldDelete) return;

      await repo.deleteJob(job.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }

    Future<bool> _confirmDelete(BuildContext context, WorkJob job) async {
      final displayName = job.customerName.isEmpty ? 'ลูกค้า' : job.customerName;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('ลบงานนี้?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            'ต้องการลบงานของ $displayName ใช่หรือไม่',
            style: const TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: _danger),
              child: const Text('ลบ'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    Future<void> _confirmDone(BuildContext context, JobsRepository repo, WorkJob job) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('ยืนยันงานเสร็จแล้ว?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            'ต้องการเปลี่ยนสถานะงานของ ${job.customerName.isEmpty ? 'ลูกค้า' : job.customerName} เป็นเสร็จแล้วใช่หรือไม่',
            style: const TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );

      if (result != true) return;

      await repo.updateJob(job.id, {'status': 'done'});
    }
  }

  class _EditJobResult {
    final String title;
    final String name;
    final String phone;
    final DateTime appointmentDate;
    final DateTime pickupDate;
    final WorkCategory category;

    _EditJobResult({
      required this.title,
      required this.name,
      required this.phone,
      required this.appointmentDate,
      required this.pickupDate,
      required this.category,
    });
  }

  class _EditJobDialog extends StatefulWidget {
    final WorkJob job;
    const _EditJobDialog({required this.job});

    @override
    State<_EditJobDialog> createState() => _EditJobDialogState();
  }

  class _EditJobDialogState extends State<_EditJobDialog> {
    static const _text = Color(0xFF111827);
    static const _muted = Color(0xFF6B7280);
    static const _line = Color(0x0F111827);
    static const _bg = Color(0xFFF7F8FA);
    static const _card = Color(0xFFFFFFFF);

    final _titleC = TextEditingController();
    final _nameC = TextEditingController();
    final _phoneC = TextEditingController();

    late DateTime _appointmentDate;
    late DateTime _pickupDate;
    late WorkCategory _category;

    @override
    void initState() {
      super.initState();
      _titleC.text = widget.job.title;
      _nameC.text = widget.job.customerName;
      _phoneC.text = widget.job.customerPhone;
      _appointmentDate = widget.job.appointmentDate;
      _pickupDate = widget.job.pickupDate;
      _category = widget.job.category;
    }

    @override
    void dispose() {
      _titleC.dispose();
      _nameC.dispose();
      _phoneC.dispose();
      super.dispose();
    }

    String _fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    Future<void> _pickAppointment() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _appointmentDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => _appointmentDate = picked);
    }

    Future<void> _pickPickup() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _pickupDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => _pickupDate = picked);
    }

    void _onSave() {
      final name = _nameC.text.trim();
      final phone = _phoneC.text.trim();
      if (name.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกชื่อลูกค้าและเบอร์โทร')),
        );
        return;
      }

      Navigator.pop(
        context,
        _EditJobResult(
          title: _titleC.text.trim(),
          name: name,
          phone: phone,
          appointmentDate: _appointmentDate,
          pickupDate: _pickupDate,
          category: _category,
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Dialog(
        backgroundColor: _card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'แก้ไขงาน',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _field(
                  label: 'ชื่องาน',
                  controller: _titleC,
                  hint: 'เช่น ตัดสูทคุณพ่อ',
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-z0-9\u0E00-\u0E7F\s\.\-'\(\)]"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  label: 'ชื่อลูกค้า',
                  controller: _nameC,
                  hint: 'ระบุชื่อลูกค้า',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-z\u0E00-\u0E7F\s\.\-']"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  label: 'เบอร์โทร',
                  controller: _phoneC,
                  hint: '08xxxxxxxx',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ประเภทงาน',
                    style: TextStyle(fontWeight: FontWeight.w900, color: _text.withOpacity(0.8)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _categoryChip(WorkCategory.daily, 'รายวัน'),
                    const SizedBox(width: 8),
                    _categoryChip(WorkCategory.package, 'แพ็กเกจ'),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        title: 'วันนัดหมาย',
                        value: _fmtDate(_appointmentDate),
                        onTap: _pickAppointment,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateTile(
                        title: 'วันรับชุด',
                        value: _fmtDate(_pickupDate),
                        onTap: _pickPickup,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _muted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _text,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _field({
      required String label,
      required TextEditingController controller,
      required String hint,
      TextInputType? keyboardType,
      TextCapitalization textCapitalization = TextCapitalization.none,
      List<TextInputFormatter>? inputFormatters,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: _text.withOpacity(0.75))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _muted),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _text.withOpacity(0.25)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      );
    }

    Widget _categoryChip(WorkCategory value, String label) {
      final selected = _category == value;
      return Expanded(
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          selected: selected,
          onSelected: (_) => setState(() => _category = value),
          selectedColor: Colors.black.withOpacity(0.06),
          backgroundColor: _bg,
          side: const BorderSide(color: _line),
        ),
      );
    }

    Widget _dateTile({
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_month_rounded, color: _text.withOpacity(0.55)),
            ],
          ),
        ),
      );
    }
  }

  class _Card extends StatelessWidget {
    final Widget child;
    const _Card({required this.child});

    static const _line = Color(0x0F111827);

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
    }
  }

  class _Pill extends StatelessWidget {
    final String label;
    const _Pill({required this.label});

    static const _bg = Color(0xFFF6F7F9);
    static const _line = Color(0x0F111827);
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
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: _text, fontSize: 12)),
      );
    }
  }
