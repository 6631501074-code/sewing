import 'package:cloud_firestore/cloud_firestore.dart';

class JobsRepository {
  final FirebaseFirestore _db;
  JobsRepository(this._db);

  Stream<QuerySnapshot> watchActiveJobs() {
    return _db
        .collection('jobs')
        .where('status', whereNotIn: ['done']) // ✅ กัน done ออก
        .orderBy('status') // (optional) ถ้าอยากให้ urgent มาก่อนในวันเดียวกัน
        .orderBy('pickupDate')
        .snapshots();
  }

  Future<DocumentSnapshot> getJob(String docId) {
    return _db.collection('jobs').doc(docId).get();
  }
}
