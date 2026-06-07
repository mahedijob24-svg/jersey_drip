import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';

class UserRoleService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<UserRole> watchRole() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(UserRole.user);
    }

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      final role = doc.data()?['role'] ?? 'user';
      return UserRole.fromString(role);
    });
  }

  Future<UserRole> fetchRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final role = doc.data()?['role'] ?? 'user';
    return UserRole.fromString(role);
  }
}
