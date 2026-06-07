import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';
import '../services/user_role_service.dart';
import '../models/admin_dashboard_stats.dart';
import '../models/user_role.dart';

final adminServiceProvider = Provider((ref) => AdminService());
final roleServiceProvider = Provider((ref) => UserRoleService());

final dashboardProvider = StreamProvider<AdminDashboardStats>((ref) {
  return ref.read(adminServiceProvider).getDashboardStatsStream();
});

final ordersProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('orders').snapshots();
});

final usersProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots();
});

final roleProvider = StreamProvider<UserRole>((ref) {
  return ref.read(roleServiceProvider).watchRole();
});
