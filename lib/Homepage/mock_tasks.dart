import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_card.dart';
import 'task_section.dart';

Stream<List<TaskItem>> watchHomepageTasks(FirebaseFirestore db, {required String userId}) {
  return db
      .collection('jobs')
      .where('ownerId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final items = snap.docs.map(_taskItemFromDoc).toList();
        items.sort((a, b) => a.pickupDate.compareTo(b.pickupDate));
        return items;
      });
}

TaskItem _taskItemFromDoc(DocumentSnapshot doc) {
  final data = (doc.data() as Map<String, dynamic>? ?? {});
  final String title = (data['title'] ?? '').toString();
  final String jobId = (data['jobId'] ?? doc.id).toString();
  final String name = (data['customerName'] ?? data['name'] ?? '').toString();
  final String statusRaw = (data['status'] ?? 'doing').toString();
  final Timestamp? pickupTs = data['pickupDate'];
  final DateTime pickupDate = pickupTs?.toDate() ?? DateTime.now();

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final bool isOverdue = pickupDate.isBefore(today) && statusRaw != 'done';

  final String garmentType = (data['garmentType'] ?? '').toString();
  final bool isPants = garmentType.toLowerCase().contains('pants');
  final String imagePath = isPants ? 'assets/icons/pants.png' : 'assets/icons/shirt.png';

  final displayTitle = title.isNotEmpty
      ? title
      : (name.isNotEmpty ? name : '#$jobId');

  return TaskItem(
    jobId: doc.id,
    title: displayTitle,
    tailorName: 'Customer: ${name.isEmpty ? '-' : name}',
    status: _taskStatusFrom(statusRaw, isOverdue),
    imagePath: imagePath,
    pickupDate: pickupDate,
  );
}

TaskStatus _taskStatusFrom(String s, bool overdue) {
  if (overdue) return TaskStatus.overdue;
  switch (s) {
    case 'urgent':
      return TaskStatus.urgent;
    case 'done':
      return TaskStatus.done;
    case 'doing':
    default:
      return TaskStatus.doing;
  }
}
