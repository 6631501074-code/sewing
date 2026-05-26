import 'package:cloud_firestore/cloud_firestore.dart';

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
    return _db.collection('jobs').doc(docId).update({
      'status': 'confirming',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markDone(String docId) {
    return _db.collection('jobs').doc(docId).update({
      'status': 'done',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
