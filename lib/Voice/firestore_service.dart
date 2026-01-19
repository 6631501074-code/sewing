import 'package:cloud_firestore/cloud_firestore.dart';
import 'garment_dialog.dart';
import 'save_customer_dialog.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<String> createJob({
    required CustomerSaveResult customer,
    required Map<String, String> measures,
    required GarmentType garmentType,
    String status = 'doing', // urgent | doing | done
  }) async {
    final doc = await _db.collection('jobs').add({
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
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
}
