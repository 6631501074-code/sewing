import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { urgent, doing, done }
enum WorkCategory { daily, package }

JobStatus jobStatusFrom(String s) {
  switch (s) {
    case 'urgent':
      return JobStatus.urgent;
    case 'doing':
      return JobStatus.doing;
    case 'done':
      return JobStatus.done;
    default:
      return JobStatus.doing;
  }
}

WorkCategory workCategoryFrom(String s) {
  switch (s) {
    case 'daily':
      return WorkCategory.daily;
    case 'package':
      return WorkCategory.package;
    default:
      return WorkCategory.daily;
  }
}

String workCategoryLabel(WorkCategory c) =>
    c == WorkCategory.daily ? 'งานรายวัน' : 'งานเหมา';

class WorkJob {
  final String id; // docId
  final String jobId; // เช่น A102 (optional)
  final String title;
  final String customerName;
  final String customerPhone;
  final WorkCategory category;
  final String garmentType; // เก็บเป็น string ง่ายต่อ firestore
  final DateTime appointmentDate;
  final DateTime pickupDate;
  final JobStatus status;
  final Map<String, dynamic> measures;

  WorkJob({
    required this.id,
    required this.jobId,
    required this.title,
    required this.customerName,
    required this.customerPhone,
    required this.category,
    required this.garmentType,
    required this.appointmentDate,
    required this.pickupDate,
    required this.status,
    required this.measures,
  });

  factory WorkJob.fromDoc(DocumentSnapshot doc) {
  final data = (doc.data() as Map<String, dynamic>? ?? {});
  final Timestamp? ap = data['appointmentDate'];
  final Timestamp? pu = data['pickupDate'];

  return WorkJob(
    id: doc.id,
    jobId: (data['jobId'] ?? doc.id).toString(),

    // ✅ title อาจไม่มี ให้ fallback
    title: (data['title'] ?? '').toString(),

    // ✅ รองรับทั้ง customerName และ name
    customerName: (data['customerName'] ?? data['name'] ?? '').toString(),

    // ✅ รองรับทั้ง customerPhone และ phone
    customerPhone: (data['customerPhone'] ?? data['phone'] ?? '').toString(),

    category: workCategoryFrom((data['category'] ?? 'daily').toString()),
    garmentType: (data['garmentType'] ?? 'pantsOfficial').toString(),
    appointmentDate: (ap?.toDate()) ?? DateTime.now(),
    pickupDate: (pu?.toDate()) ?? DateTime.now(),
    status: jobStatusFrom((data['status'] ?? 'doing').toString()),
    measures: Map<String, dynamic>.from(data['measures'] ?? const {}),
  );
}
}