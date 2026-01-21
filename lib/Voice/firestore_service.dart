import 'package:cloud_firestore/cloud_firestore.dart';
import 'garment_dialog.dart';
import 'save_customer_dialog.dart';
import 'package:sewing/session/user_session.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<String> createJob({
    required CustomerSaveResult customer,
    required Map<String, String> measures,
    required GarmentType garmentType,
    String status = 'doing', // urgent | doing | done
  }) async {
    await _db.enableNetwork();
    final doc = _db.collection('jobs').doc();
    final ownerId = await UserSession.getUsername();
    await doc.set({
      'name': customer.name,
      'phone': customer.phone,
      'deposit': customer.deposit,

      // แนะนำเก็บเป็น Timestamp (query/sort ง่าย)
      'appointmentDate': Timestamp.fromDate(customer.appointmentDate),
      'pickupDate': Timestamp.fromDate(customer.pickupDate),

      'category': customer.category.name, // daily / package
      'garmentType': garmentType.name,    // pantsOfficial / shirt / ...

      'measures': measures,

      'status': status,
      if (ownerId != null) 'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Ensure the write reaches the server (avoid local-only cache).
    await doc.get(const GetOptions(source: Source.server));
    return doc.id;
  }
}
