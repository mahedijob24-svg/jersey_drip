import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jerseyapp/data/dummy_products.dart';

void main() {
  const allowedCategories = {'Jersey', 'Socks', 'Trainers', 'Accessories'};

  test('dummy products have valid categories and local images', () {
    expect(dummyProducts, isNotEmpty);

    for (final product in dummyProducts) {
      expect(
        product.category,
        isIn(allowedCategories),
        reason: '${product.name} has an invalid category',
      );
      expect(
        File(product.imagePath).existsSync(),
        isTrue,
        reason: '${product.name} image is missing at ${product.imagePath}',
      );
    }
  });

  test('each filterable category has at least one product', () {
    for (final category in allowedCategories) {
      expect(
        dummyProducts.where((product) => product.category == category),
        isNotEmpty,
        reason: '$category has no products',
      );
    }
  });
}
