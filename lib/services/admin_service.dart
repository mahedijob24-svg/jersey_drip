import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_dashboard_stats.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AdminDashboardStats> getDashboardStatsStream() {
    return _db
        .collection('orders')
        .snapshots()
        .map((orderSnap) async {
          final productSnap = await _db
              .collection('products')
              .where('isActive', isEqualTo: true)
              .get();

          int totalProducts = productSnap.docs.length;
          int totalOrders = orderSnap.docs.length;
          int deliveredOrders = 0;
          double totalRevenue = 0;

          int lowStockCount = 0;
          int outOfStockCount = 0;

          for (var doc in orderSnap.docs) {
            final data = doc.data();

            final status = (data['status'] ?? '').toString().toLowerCase();

            if (status == 'delivered') {
              deliveredOrders++;

              final price = data['totalPrice'];

              if (price is int) {
                totalRevenue += price.toDouble();
              } else if (price is double) {
                totalRevenue += price;
              } else if (price is String) {
                totalRevenue += double.tryParse(price) ?? 0;
              }
            }
          }
          
          for (var doc in productSnap.docs) {
            final data = doc.data();

            final sizes = data['sizes'] as Map<String, dynamic>? ?? {};

            sizes.forEach((key, value) {
              final stock = (value['stock'] ?? 0) as int;

              if (stock == 0) {
                outOfStockCount++;
              } else if (stock <= 5) {
                lowStockCount++;
              }
            });
          }

          return AdminDashboardStats(
            totalProducts: totalProducts,
            totalOrders: totalOrders,
            deliveredOrders: deliveredOrders,
            totalRevenue: totalRevenue,
            lowStockCount: lowStockCount,
            outOfStockCount: outOfStockCount,
          );
        })
        .asyncMap((future) => future);
  }
}
