import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sewing/services/local_notification_service.dart';
import 'garment_dialog.dart';
import 'save_customer_dialog.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<String> createJob({
    required CustomerSaveResult customer,
    required Map<String, String> measures,
    required GarmentType garmentType,
    String status = 'doing', // urgent | doing | done
    String? packageFolderId,
  }) async {
    final pickupKey = _dateKey(customer.pickupDate);
    final autoId = _db.collection('jobs').doc().id;
    final docId = '${pickupKey}_${autoId.substring(0, 8)}';
    final doc = _db.collection('jobs').doc(docId);
    final packageName = customer.packageName.trim();
    final explicitFolderId = (packageFolderId ?? '').trim();
    final customerFolderId = customer.packageFolderId.trim();
    final resolvedPackageFolderId = customer.category == WorkCategory.package
        ? explicitFolderId.isNotEmpty
              ? explicitFolderId
              : customerFolderId.isNotEmpty
              ? customerFolderId
              : _safeFolderId(packageName)
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
      'packageFolderId': resolvedPackageFolderId,
      'garmentType': garmentType.name, // pantsOfficial / shirt / ...

      'measures': measures,
      'notes': customer.notes,

      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(doc, payload);

    if (customer.category == WorkCategory.package) {
      final folderRef = _db
          .collection('jobFolders')
          .doc(resolvedPackageFolderId);
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
    await LocalNotificationService.instance.showJobCreated(
      jobId: docId,
      title: title,
      pickupDate: customer.pickupDate,
    );
    await LocalNotificationService.instance.schedulePickupReminder(
      jobId: docId,
      title: title,
      pickupDate: customer.pickupDate,
    );

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

  // ✅ สร้างโฟลเดอร์งานเหมา
  Future<String> createPackageFolder(String folderName) async {
    final name = folderName.trim();
    final folderId = _safeFolderId(name);
    final folderRef = _db.collection('jobFolders').doc(folderId);

    await folderRef.set({
      'name': name,
      'category': 'package',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return folderId;
  }
}
