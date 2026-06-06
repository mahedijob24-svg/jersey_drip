class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountedPrice;
  final String category;
  final String brand;
  final String imagePath;
  final int stockQuantity;
  final List<String> sizes;
  final bool featured;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.category,
    required this.brand,
    required this.imagePath,
    required this.stockQuantity,
    required this.sizes,
    required this.featured,
    required this.createdAt,
  });
}
