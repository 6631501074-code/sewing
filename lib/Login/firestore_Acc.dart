import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class FirestoreAccountService {
  final FirebaseFirestore _db;
  FirestoreAccountService(this._db);

  Future<void> createUser({
    required String username,
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    final normalized = _normalizeUsername(username);
    final userRef = _db.collection('users').doc(normalized);
    final existing = await userRef.get();
    if (existing.exists) {
      throw StateError('USER_EXISTS');
    }

    final salt = _randomSalt();
    final hash = _hashPassword(password, salt);

    await userRef.set({
      'username': normalized,
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'passwordHash': hash,
      'passwordSalt': salt,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser({
    required String username,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? photoUrl,
  }) async {
    if (username.trim().isEmpty) {
      throw ArgumentError('username');
    }

    final data = <String, dynamic>{
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null && name.isNotEmpty) data['name'] = name;
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;
    if (photoUrl != null && photoUrl.isNotEmpty) data['photoUrl'] = photoUrl;

    if (password != null && password.isNotEmpty) {
      final salt = _randomSalt();
      final hash = _hashPassword(password, salt);
      data['passwordHash'] = hash;
      data['passwordSalt'] = salt;
    }

    await _db.collection('users').doc(username).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<String?> verifyUser({
    required String username,
    required String password,
  }) async {
    final normalized = _normalizeUsername(username);
    var doc = await _db.collection('users').doc(normalized).get();

    if (!doc.exists) {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      doc = query.docs.first;
    }

    final data = (doc.data() as Map<String, dynamic>? ?? {});
    final hash = (data['passwordHash'] ?? '').toString();
    final salt = (data['passwordSalt'] ?? '').toString();
    if (hash.isEmpty || salt.isEmpty) return null;
    final ok = _hashPassword(password, salt) == hash;
    return ok ? doc.id : null;
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt|$password');
    return sha256.convert(bytes).toString();
  }

  String _randomSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }
}
