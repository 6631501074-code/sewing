import 'package:cloud_firestore/cloud_firestore.dart';

class JobsRepository {
  final FirebaseFirestore _db;
  JobsRepository(this._db);

  Stream<QuerySnapshot> watchActiveJobs({String? userId}) {
    if (userId == null || userId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('jobs')
        .where('ownerId', isEqualTo: userId)
        .snapshots();
  }

  Stream<DocumentSnapshot> watchJob(String docId) {
    return _db.collection('jobs').doc(docId).snapshots();
  }

  Future<DocumentSnapshot> getJob(String docId) {
    return _db.collection('jobs').doc(docId).get();
  }

  Future<void> refreshJob(String docId) async {
    await _db.collection('jobs').doc(docId).get(const GetOptions(source: Source.server));
  }

  Future<void> deleteJob(String docId) {
    return _db.collection('jobs').doc(docId).delete();
  }

  Future<void> updateJob(String docId, Map<String, dynamic> data) {
    return _db.collection('jobs').doc(docId).update(data);
  }
}
