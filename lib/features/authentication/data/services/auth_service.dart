import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/auth_user.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        return null;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return null;
      }

      final data = userDoc.data();

      if (data == null || data['active'] != true) {
        await _auth.signOut();
        return null;
      }

      final role = data['role'] as String? ?? 'family_member';
      final emailAddress =
          data['email'] as String? ?? firebaseUser.email ?? '';

      return AuthUser(
        uid: firebaseUser.uid,
        email: emailAddress,
        role: role,
        name: _nameFromEmail(emailAddress),
      );
    } on FirebaseAuthException {
      return null;
    } on FirebaseException {
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _nameFromEmail(String email) {
    final username = email.split('@').first.trim();

    if (username.isEmpty) {
      return email;
    }

    return username
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
    )
        .join(' ');
  }
}