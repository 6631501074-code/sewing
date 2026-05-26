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
    final pickupKey = _dateKey(customer.pickupDate);
    final autoId = _db.collection('jobs').doc().id;
    final docId = '${pickupKey}_${autoId.substring(0, 8)}';
    final doc = _db.collection('jobs').doc(docId);
    final packageName = customer.packageName.trim();
    final packageFolderId = customer.category == WorkCategory.package
        ? _safeFolderId(packageName)
        : '';
    final title =
        customer.category == WorkCategory.package && packageName.isNotEmpty
        ? packageName
        : '${_garmentLabel(garmentType)} - ${customer.name}';

    final payload = {
      'jobId': docId,
      'title': title,
      'name': customer.name,
      'phone': customer.phone,
      'customerName': customer.name,
      'customerPhone': customer.phone,
      'deposit': customer.deposit,

      // แนะนำเก็บเป็น Timestamp (query/sort ง่าย)
      'appointmentDate': Timestamp.fromDate(customer.appointmentDate),
      'pickupDate': Timestamp.fromDate(customer.pickupDate),

      'category': customer.category.name, // daily / package
      'packageName': packageName,
      'packageFolderId': packageFolderId,
      'garmentType': garmentType.name, // pantsOfficial / shirt / ...

      'measures': measures,

      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(doc, payload);

    if (customer.category == WorkCategory.package) {
      final folderRef = _db.collection('jobFolders').doc(packageFolderId);
      batch.set(folderRef, {
        'name': packageName,
        'category': customer.category.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(folderRef.collection('jobs').doc(docId), {
        ...payload,
        'sourceJobPath': doc.path,
      });
    }

    await batch.commit();

    return doc.id;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
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

  String _garmentLabel(GarmentType type) {
    switch (type) {
      case GarmentType.pantsOfficial:
        return 'กางเกงราชการ';
      case GarmentType.shirt:
        return 'เสื้อ';
      case GarmentType.none:
        return 'งานตัดเย็บ';
    }
  }
}
