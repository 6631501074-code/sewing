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
    final userRef = _db.collection('users').doc(username);
    final existing = await userRef.get();
    if (existing.exists) {
      throw StateError('USER_EXISTS');
    }

    final salt = _randomSalt();
    final hash = _hashPassword(password, salt);

    await userRef.set({
      'username': username,
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
