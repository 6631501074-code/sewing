import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sewing/services/local_notification_service.dart';

class JobsRepository {
  final FirebaseFirestore _db;
  JobsRepository(this._db);

  Stream<QuerySnapshot> watchQueueJobs() {
    return _db.collection('jobs').orderBy('pickupDate').snapshots();
  }

  Stream<QuerySnapshot> watchConfirmationJobs() {
    return _db.collection('jobs').orderBy('pickupDate').snapshots();
  }

  Stream<QuerySnapshot> watchDoneJobs() {
    return _db
        .collection('jobs')
        .orderBy('pickupDate', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getJob(String docId) {
    return _db.collection('jobs').doc(docId).get();
  }

  Future<void> moveToConfirmation(String docId) {
    return _updateJobEverywhere(docId, {
      'status': 'confirming',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markDone(String docId) {
    return _updateJobEverywhere(docId, {
      'status': 'done',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) async {
      final snap = await getJob(docId);
      final data = (snap.data() as Map<String, dynamic>? ?? {});
      final title = (data['title'] ?? data['jobId'] ?? docId).toString();
      await LocalNotificationService.instance.showJobCompleted(
        jobId: docId,
        title: title,
      );
    });
  }

  Future<void> _updateJobEverywhere(
    String docId,
    Map<String, dynamic> values,
  ) async {
    final jobRef = _db.collection('jobs').doc(docId);
    final snap = await jobRef.get();
    final data = snap.data() ?? {};
    final packageFolderId = (data['packageFolderId'] ?? '').toString().trim();

    final batch = _db.batch();
    batch.update(jobRef, values);

    if (packageFolderId.isNotEmpty) {
      final folderRef = _db.collection('jobFolders').doc(packageFolderId);
      batch.set(
        folderRef.collection('jobs').doc(docId),
        values,
        SetOptions(merge: true),
      );
      batch.set(folderRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<String> createPackageFolder(String folderName) async {
    final name = folderName.trim();
    final folderId = _safeFolderId(name);
    await _db.collection('jobFolders').doc(folderId).set({
      'name': name,
      'category': 'package',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return folderId;
  }

  // ✅ ดูรายการโฟลเดอร์งานเหมา
  Stream<QuerySnapshot> watchPackageFolders() {
    return _db
        .collection('jobFolders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ✅ ดูรายการงานในโฟลเดอร์งานเหมา
  Stream<QuerySnapshot> watchPackageFolderJobs(String folderId) {
    return _db
        .collection('jobFolders')
        .doc(folderId)
        .collection('jobs')
        .orderBy('pickupDate')
        .snapshots();
  }

  // ✅ ได้ข้อมูลโฟลเดอร์
  Future<DocumentSnapshot> getPackageFolder(String folderId) {
    return _db.collection('jobFolders').doc(folderId).get();
  }

  String _safeFolderId(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[/\\#?]'), '-')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty
        ? 'package_${DateTime.now().millisecondsSinceEpoch}'
        : cleaned;
  }
}
