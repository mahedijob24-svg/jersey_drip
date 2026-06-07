import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  Stream<AdminDashboardStats> getDashboardStatsStream() {
    final orderSnapshots = _db.collection('orders').snapshots();
    final productSnapshots = _db.collection('products').snapshots();
    final userSnapshots = _db.collection('users').snapshots();

    return Stream.multi((controller) {
      QuerySnapshot? latestOrders;
      QuerySnapshot? latestProducts;
      QuerySnapshot? latestUsers;

      late final StreamSubscription<QuerySnapshot> orderSub;
      late final StreamSubscription<QuerySnapshot> productSub;
      late final StreamSubscription<QuerySnapshot> userSub;

      void emitStats() {
        if (latestOrders == null ||
            latestProducts == null ||
            latestUsers == null) {
          return;
        }
        try {
          final stats = _computeStats(
            latestOrders!,
            latestProducts!,
            latestUsers!,
          );
          controller.add(stats);
        } catch (error, stack) {
          controller.addError(error, stack);
        }
      }

      orderSub = orderSnapshots.listen((snapshot) {
        latestOrders = snapshot;
        emitStats();
      }, onError: controller.addError);

      productSub = productSnapshots.listen((snapshot) {
        latestProducts = snapshot;
        emitStats();
      }, onError: controller.addError);

      userSub = userSnapshots.listen((snapshot) {
        latestUsers = snapshot;
        emitStats();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await orderSub.cancel();
        await productSub.cancel();
        await userSub.cancel();
      };
    });
  }

  Stream<List<AppOrder>> watchOrders({int limit = 100}) {
    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(AppOrder.fromDocument).toList(growable: false);
    });
  }

  Stream<List<Product>> watchProducts() {
    return _productService.productsStream();
  }

  Stream<List<UserProfile>> watchUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc.data()))
          .toList(growable: false);
    });
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    final document = _db.collection('products').doc();
    final data = Map<String, dynamic>.from(productData)
      ..['createdAt'] = FieldValue.serverTimestamp();
    await document.set(data);
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final document = _db.collection('products').doc(productId);
    final data = Map<String, dynamic>.from(productData)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await document.update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  Future<void> updateProductActive(String productId, bool isActive) async {
    await _db.collection('products').doc(productId).update({
      'isActive': isActive,
    });
  }

  Future<void> updateProductSizeStock(
    String productId,
    String size,
    int stock,
  ) async {
    final document = _db.collection('products').doc(productId);
    final snapshot = await document.get();
    if (!snapshot.exists) {
      throw StateError('Product not found');
    }

    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final rawSizes = data['sizes'];
    if (rawSizes is! Map) {
      throw StateError('Product sizes are not available');
    }

    final updatedSizes = Map<String, dynamic>.from(rawSizes);
    final rawVariant = updatedSizes[size];
    if (rawVariant is! Map) {
      throw StateError('Size variant not found');
    }

    updatedSizes[size] = {
      ...Map<String, dynamic>.from(rawVariant),
      'stock': stock,
    };

    await document.update({'sizes': updatedSizes});
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  AdminDashboardStats _computeStats(
    QuerySnapshot orderSnap,
    QuerySnapshot productSnap,
    QuerySnapshot userSnap,
  ) {
    int totalProducts = 0;
    int totalOrders = orderSnap.docs.length;
    int deliveredOrders = 0;
    double totalRevenue = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    int totalUsers = userSnap.docs.length;

    for (var doc in orderSnap.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final status = (data['status'] ?? '').toString().toLowerCase();
      final paymentStatus = (data['paymentStatus'] ?? '')
          .toString()
          .toLowerCase();
      final totalPrice = data['totalPrice'];

      if (status == 'delivered') {
        deliveredOrders++;
      }

      if (paymentStatus == 'paid') {
        if (totalPrice is int) {
          totalRevenue += totalPrice.toDouble();
        } else if (totalPrice is double) {
          totalRevenue += totalPrice;
        } else if (totalPrice is String) {
          totalRevenue += double.tryParse(totalPrice) ?? 0;
        }
      }
    }

    for (var doc in productSnap.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final isActive = data['isActive'];
      if (isActive is bool && !isActive) {
        continue;
      }

      totalProducts++;
      final sizes = data['sizes'] as Map<String, dynamic>?;
      int totalStock = 0;
      bool hasSizes = false;
      bool allSizesEmpty = true;

      if (sizes != null) {
        for (var sizeEntry in sizes.entries) {
          final sizeData = sizeEntry.value as Map<String, dynamic>? ?? {};
          final rawStock = sizeData['stock'];
          final stock = rawStock is int
              ? rawStock
              : rawStock is double
              ? rawStock.toInt()
              : int.tryParse(rawStock?.toString() ?? '') ?? 0;
          hasSizes = true;
          totalStock += stock;
          if (stock > 0) {
            allSizesEmpty = false;
          }
        }
      }

      if (!hasSizes) {
        final rawQuantity = data['quantity'];
        totalStock = rawQuantity is int
            ? rawQuantity
            : rawQuantity is double
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;
        allSizesEmpty = totalStock <= 0;
      }

      if (allSizesEmpty) {
        outOfStockCount++;
      } else if (totalStock <= 5) {
        lowStockCount++;
      }
    }

    if (kDebugMode) {
      developer.log(
        'AdminDashboardStats computed',
        name: 'AdminService',
        error: {
          'totalProducts': totalProducts,
          'totalOrders': totalOrders,
          'deliveredOrders': deliveredOrders,
          'totalRevenue': totalRevenue,
          'lowStockCount': lowStockCount,
          'outOfStockCount': outOfStockCount,
          'totalUsers': totalUsers,
        },
      );
    }

    return AdminDashboardStats(
      totalProducts: totalProducts,
      totalOrders: totalOrders,
      deliveredOrders: deliveredOrders,
      totalRevenue: totalRevenue,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalUsers: totalUsers,
    );
  }
}
