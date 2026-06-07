class AdminDashboardStats {
  final int totalProducts;
  final int totalOrders;
  final int deliveredOrders;
  final double totalRevenue;
  final int lowStockCount;
  final int outOfStockCount;

  AdminDashboardStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.totalRevenue,
    required this.lowStockCount,
    required this.outOfStockCount,
  });
}
