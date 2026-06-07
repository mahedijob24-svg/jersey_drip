import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.role,
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
    this.createdAt,
    this.updatedAt,
  });

  final String role;
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final String city;
  final String postalCode;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: _readString(data['uid']),
      name: _readString(data['name']),
      email: _readString(data['email']),
      phoneNumber: _readString(data['phoneNumber']),
      address: _readString(data['address']),
      city: _readString(data['city']),
      postalCode: _readString(data['postalCode']),
      country: _readString(data['country']),
      role: _readString(data['role']).isEmpty ? 'user' : data['role'],
      createdAt: _readDateString(data['createdAt']),
      updatedAt: _readDateString(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  UserProfile copyWith({
    String? name,
    String? role,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(Object? value) => value as String? ?? '';

  static DateTime? _readDateString(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
