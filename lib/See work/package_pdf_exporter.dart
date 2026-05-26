import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'work_job.dart';

enum PackageExportGarment { shirt, pants }

String packageExportGarmentLabel(PackageExportGarment type) {
  switch (type) {
    case PackageExportGarment.shirt:
      return 'เสื้อ';
    case PackageExportGarment.pants:
      return 'กางเกง';
  }
}

PackageExportGarment? packageExportGarmentFromJob(WorkJob job) {
  final value = job.garmentType.toLowerCase();
  if (value.contains('shirt')) return PackageExportGarment.shirt;
  if (value.contains('pants')) return PackageExportGarment.pants;
  return null;
}

bool packageJobMatchesGarment(WorkJob job, PackageExportGarment type) {
  return packageExportGarmentFromJob(job) == type;
}

List<String> packageMeasureKeys(PackageExportGarment type) {
  switch (type) {
    case PackageExportGarment.shirt:
      return const [
        'อก',
        'รอบเอว',
        'รอบชาย',
        'บ่า',
        'แขนยาว',
        'แขนกว้าง',
        'รอบศอก',
        'ต้นแขน',
        'เสื้อยาว',
        'บ่าหน้า',
        'บ่าหลัง',
        'ยาวหลัง',
      ];
    case PackageExportGarment.pants:
      return const ['เอว', 'สะโพก', 'เป้า', 'ต้นขา', 'ยาว', 'ขากว้าง'];
  }
}

String packageMeasureValue(WorkJob job, String key) {
  final value = job.measures[key]?.toString().trim() ?? '';
  return value.isEmpty ? '-' : value;
}

Future<Uint8List> buildPackageJobsPdf({
  required String folderName,
  required PackageExportGarment garmentType,
  required List<WorkJob> jobs,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('asset/font/THSarabunBold.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('asset/font/THSarabunBold.ttf'),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final keys = packageMeasureKeys(garmentType);
  final label = packageExportGarmentLabel(garmentType);
  final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  final headers = ['ลำดับ', 'ชื่อ', ...keys, 'รายละเอียด'];
  final rows = jobs.asMap().entries.map((entry) {
    final index = entry.key + 1;
    final job = entry.value;
    return [
      index.toString(),
      job.customerName.isEmpty ? '-' : job.customerName,
      ...keys.map((key) => packageMeasureValue(job, key)),
      job.notes.trim().isEmpty ? '-' : job.notes.trim(),
    ];
  }).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => [
        pw.Text('ตารางงานเหมา', style: pw.TextStyle(font: bold, fontSize: 22)),
        pw.SizedBox(height: 4),
        pw.Text(
          'ชื่อโฟลเดอร์: $folderName',
          style: pw.TextStyle(font: bold, fontSize: 16),
        ),
        pw.Text(
          'ประเภท: $label   จำนวน: ${jobs.length} รายการ   วันที่สร้าง: $generatedAt',
          style: const pw.TextStyle(fontSize: 13),
        ),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          headers: headers,
          data: rows,
          border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.6),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(font: bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 4,
          ),
          cellAlignment: pw.Alignment.center,
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            headers.length - 1: pw.Alignment.centerLeft,
          },
        ),
      ],
    ),
  );

  return doc.save();
}
