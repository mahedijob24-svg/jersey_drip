import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/admin_service.dart';
import '../services/user_role_service.dart';

final adminServiceProvider = Provider((ref) => AdminService());
final roleServiceProvider = Provider((ref) => UserRoleService());

final dashboardProvider = StreamProvider<AdminDashboardStats>((ref) {
  return ref.read(adminServiceProvider).getDashboardStatsStream();
});

final recentOrdersProvider = StreamProvider<List<AppOrder>>((ref) {
  return ref.read(adminServiceProvider).watchOrders(limit: 5);
});

final ordersProvider = StreamProvider<List<AppOrder>>((ref) {
  return ref.read(adminServiceProvider).watchOrders();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.read(adminServiceProvider).watchProducts();
});

final usersProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.read(adminServiceProvider).watchUsers();
});

final roleProvider = StreamProvider<UserRole>((ref) {
  return ref.read(roleServiceProvider).watchRole();
});
