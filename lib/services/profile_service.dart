import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserProfile> getOrCreateCurrentUserProfile() async {
    final user = _requireCurrentUser();
    final docRef = _usersCollection.doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data() ?? {};
      final profile = UserProfile.fromFirestore(data);

      await _backfillMissingIdentityFields(profile, user, data);

      return profile.copyWith(
        email: user.email ?? profile.email,
        name: profile.name.isNotEmpty
            ? profile.name
            : user.displayName ?? profile.name,
      );
    }

    final now = DateTime.now();

    final profile = UserProfile(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phoneNumber: '',
      address: '',
      city: '',
      postalCode: '',
      country: '',

      // ✅ ALWAYS DEFAULT ROLE
      role: 'user',

      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(profile.toFirestore());
    return profile;
  }

  Stream<UserProfile> currentUserProfileStream() async* {
    final profile = await getOrCreateCurrentUserProfile();
    yield profile;

    final user = _requireCurrentUser();

    yield* _usersCollection.doc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? profile.toFirestore();
      final currentProfile = UserProfile.fromFirestore(data);

      return currentProfile.copyWith(email: user.email ?? currentProfile.email);
    });
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String phoneNumber,
    required String address,
    required String city,
    required String postalCode,
    required String country,
  }) async {
    final user = _requireCurrentUser();
    final docRef = _usersCollection.doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await getOrCreateCurrentUserProfile();
    }
    final existingRole = snapshot.data()?['role'] ?? 'user';

    await docRef.set({
      'uid': user.uid,
      'name': name.trim(),
      'email': user.email ?? '',
      'phoneNumber': phoneNumber.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'role': existingRole,

      'postalCode': postalCode.trim(),
      'country': country.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> _backfillMissingIdentityFields(
    UserProfile profile,
    User user,
    Map<String, dynamic> data,
  ) async {
    final updates = <String, dynamic>{};

    if (profile.uid.isEmpty) updates['uid'] = user.uid;
    if (profile.email != user.email && user.email != null) {
      updates['email'] = user.email;
    }
    if (profile.name.isEmpty && user.displayName != null) {
      updates['name'] = user.displayName;
    }

    if (!data.containsKey('phoneNumber')) updates['phoneNumber'] = '';
    if (!data.containsKey('address')) updates['address'] = '';
    if (!data.containsKey('city')) updates['city'] = '';
    if (!data.containsKey('postalCode')) updates['postalCode'] = '';
    if (!data.containsKey('country')) updates['country'] = '';

    if (!data.containsKey('role')) {
      updates['role'] = 'user';
    }

    if (!data.containsKey('createdAt')) {
      updates['createdAt'] = DateTime.now().toIso8601String();
    }

    if (!data.containsKey('updatedAt')) {
      updates['updatedAt'] = DateTime.now().toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _usersCollection
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));
    }
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user is available.',
      );
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }
}
