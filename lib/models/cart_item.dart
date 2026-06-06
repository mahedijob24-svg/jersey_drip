import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.quantity,
    required this.totalPrice,
  });

  final String productId;
  final String name;
  final int price;
  final String imagePath;
  final int quantity;
  final int totalPrice;

  factory CartItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final productId = _readString(data['productId'], fallback: document.id);
    final price = _readInt(data['price']);
    final quantity = _readInt(data['quantity'], fallback: 1);

    return CartItem(
      productId: productId,
      name: _readString(data['name'], fallback: 'Cart item'),
      price: price,
      imagePath: _readString(data['imagePath']),
      quantity: quantity,
      totalPrice: _readInt(data['totalPrice'], fallback: price * quantity),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }
}
