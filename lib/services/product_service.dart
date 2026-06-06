import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Product>> productsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map(_productFromDocument).toList();
    });
  }

  Product _productFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final price = _readDouble(data['price']);
    final originalPrice = _readNullableDouble(
      _readFirstValue(data, const [
        'originalPrice',
        'originalprice',
        'original_price',
        'original price',
      ]),
    );
    final imagePath = _normalizeImagePath(
      _readFirstValue(data, const [
        'imagePath',
        'imagepath',
        'image_path',
        'image path',
        'image',
        'assetPath',
        'asset_path',
        'asset path',
        'path',
        'imageUrl',
        'imageURL',
      ]),
    );

    if (imagePath.isEmpty) {
      debugPrint('PRODUCT IMAGE PATH MISSING');
      debugPrint('Product document id: ${document.id}');
      debugPrint('Available fields: ${data.keys.join(', ')}');
    }

    return Product(
      id: document.id,
      name: _readString(data['name'], fallback: 'Unnamed Product'),
      description: _readString(data['description']),
      price: originalPrice ?? price,
      discountedPrice: price,
      category: _normalizeCategory(data['category']),
      brand: _readString(data['brand']),
      imagePath: imagePath,
      stockQuantity: _readInt(
        _readFirstValue(data, const [
          'quantity',
          'stockQuantity',
          'stockquantity',
          'stock_quantity',
          'stock',
        ]),
      ),
      sizes: _readStringList(data['sizes']),
      featured: data['featured'] == true,
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }

  Object? _readFirstValue(Map<String, dynamic> data, List<String> keys) {
    final normalizedDataKeys = {
      for (final key in data.keys) _normalizeFieldName(key): key,
    };

    for (final key in keys) {
      final dataKey = data.containsKey(key)
          ? key
          : normalizedDataKeys[_normalizeFieldName(key)];
      if (dataKey == null) {
        continue;
      }

      final value = data[dataKey];
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String _normalizeFieldName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  double _readDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  double? _readNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .map((size) => size.trim())
          .where((size) => size.isNotEmpty)
          .toList();
    }
    return const [];
  }

  DateTime _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _normalizeCategory(Object? value) {
    final category = _readString(value).toLowerCase();

    const categories = {
      'jersey': 'Jersey',
      'jerseys': 'Jersey',
      'socks': 'Socks',
      'trainers': 'Trainers',
      'accessories': 'Accessories',
    };

    return categories[category] ?? _readString(value);
  }

  String _normalizeImagePath(Object? value) {
    var path = _readString(value).replaceAll(r'\', '/');

    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('assets/')) {
      path = path.substring('assets/'.length);
    }

    return path;
  }
}
