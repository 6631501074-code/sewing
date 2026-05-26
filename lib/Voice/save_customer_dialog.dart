import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'garment_dialog.dart';
import 'thai_number_formatter.dart';

enum WorkCategory { daily, package }

String workCategoryLabel(WorkCategory c) {
  switch (c) {
    case WorkCategory.daily:
      return 'งานรายวัน';
    case WorkCategory.package:
      return 'งานเหมา';
  }
}

class CustomerSaveResult {
  final String name;
  final String phone;
  final double deposit;
  final DateTime appointmentDate;
  final DateTime pickupDate;
  final WorkCategory category;
  final String packageName;

  CustomerSaveResult({
    required this.name,
    required this.phone,
    required this.deposit,
    required this.appointmentDate,
    required this.pickupDate,
    required this.category,
    this.packageName = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'deposit': deposit,
    'appointmentDate': appointmentDate.toIso8601String(),
    'pickupDate': pickupDate.toIso8601String(),
    'category': category.name,
    'packageName': packageName,
  };
}

Future<CustomerSaveResult?> showSaveCustomerDialog({
  required BuildContext context,
  required GarmentType garmentType,
  required Map<String, String> measures,
}) {
  return showDialog<CustomerSaveResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) =>
        _SaveCustomerDialog(garmentType: garmentType, measures: measures),
  );
}

class _SaveCustomerDialog extends StatefulWidget {
  final GarmentType garmentType;
  final Map<String, String> measures;

  const _SaveCustomerDialog({
    required this.garmentType,
    required this.measures,
  });

  @override
  State<_SaveCustomerDialog> createState() => _SaveCustomerDialogState();
}

class _SaveCustomerDialogState extends State<_SaveCustomerDialog> {
  // ---- mini theme (ขาว/คลีน) ----
  static const _surface = Colors.white; // ✅ พื้นหลังขาว
  static const _fieldBg = Color(0xFFF7F7F8); // เทาอ่อนมาก (เหมือน iOS)
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0x1A111827);

  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _depositC = TextEditingController();
  final _packageNameC = TextEditingController();

  late DateTime _appointmentDate;
  late DateTime _pickupDate;

  WorkCategory _category = WorkCategory.daily;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _appointmentDate = DateTime(now.year, now.month, now.day);
    _pickupDate = _appointmentDate;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _depositC.dispose();
    _packageNameC.dispose();
    super.dispose();
  }

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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _onSave() {
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    final packageName = _packageNameC.text.trim();

    final depositStr = ThaiToArabicDigitsFormatter.to2dpOrEmpty(_depositC.text);
    final deposit = double.tryParse(depositStr.isEmpty ? '0' : depositStr) ?? 0;

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อและเบอร์โทร')));
      return;
    }

    if (_category == WorkCategory.package && packageName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่องานเหมา')));
      return;
    }

    Navigator.pop(
      context,
      CustomerSaveResult(
        name: name,
        phone: phone,
        deposit: deposit,
        appointmentDate: _appointmentDate,
        pickupDate: _pickupDate,
        category: _category,
        packageName: packageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'บันทึกลูกค้า (${garmentTypeLabel(widget.garmentType)})';

    return Dialog(
      backgroundColor: _surface, // ✅ ขาว
      surfaceTintColor: Colors.transparent, // กัน tint บน Material3
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: _text,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'หมวดหมู่',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _categoryPicker(),

              const SizedBox(height: 14),

              if (_category == WorkCategory.package) ...[
                _field(
                  label: 'ชื่องานเหมา',
                  controller: _packageNameC,
                  hint: 'เช่น เหมาชุดทีมร้าน A',
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 10),
              ],

              // ✅ ชื่อไทย: keyboard ไทย/ชื่อคน + allow ตัวอักษรไทย/เว้นวรรค/จุด/ขีด
              _field(
                label: 'ชื่อลูกค้า',
                controller: _nameC,
                hint: 'เช่น คุณเอ',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[ก-๙a-zA-Z\s\.\-']"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ เบอร์โทร: จำกัดตัวเลข/ไทยได้ (ค่อยแปลง) + จำกัดความยาว
              _field(
                label: 'เบอร์โทร',
                controller: _phoneC,
                hint: 'เช่น 08xxxxxxxx',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  ThaiToArabicDigitsFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              const SizedBox(height: 10),

              _field(
                label: 'ค่ามัดจำ',
                controller: _depositC,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThaiToArabicDigitsFormatter()],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      title: 'วันนัด',
                      value: _fmtDate(_appointmentDate),
                      onTap: _pickAppointment,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateTile(
                      title: 'วันมารับ',
                      value: _fmtDate(_pickupDate),
                      onTap: _pickPickup,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ค่าที่วัด',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _text.withOpacity(0.85),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _fieldBg, // ✅ เทาอ่อนมาก
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: widget.measures.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                            e.value.isEmpty ? '-' : e.value,
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
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(fontWeight: FontWeight.w900),
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
  }

  Widget _categoryPicker() {
    Widget chip(WorkCategory value, String text) {
      final selected = _category == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _category = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : _fieldBg, // ✅ ขาว/เทาอ่อน
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _text.withOpacity(0.18) : _border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? _text : _muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _fieldBg, // ✅ เบาลง
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          chip(WorkCategory.daily, 'งานรายวัน'),
          const SizedBox(width: 10),
          chip(WorkCategory.package, 'งานเหมา'),
        ],
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
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text.withOpacity(0.75),
          ),
        ),
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
            fillColor: _fieldBg, // ✅ เทาอ่อนมาก
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _text.withOpacity(0.25)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
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
          color: _fieldBg, // ✅ เทาอ่อนมาก
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
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
