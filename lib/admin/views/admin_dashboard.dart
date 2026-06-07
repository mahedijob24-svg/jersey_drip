import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import 'admin_order_detail.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key, required this.onNavigate});

  final void Function(int sectionIndex) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: dashboardAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Store overview', style: AppTextStyles.headingMedium),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _DashboardCard(
                      title: 'Revenue',
                      value: '\$${stats.totalRevenue.toStringAsFixed(2)}',
                      onTap: () => onNavigate(1),
                    ),
                    _DashboardCard(
                      title: 'Orders',
                      value: stats.totalOrders.toString(),
                      onTap: () => onNavigate(1),
                    ),
                    _DashboardCard(
                      title: 'Delivered',
                      value: stats.deliveredOrders.toString(),
                      onTap: () => onNavigate(1),
                    ),
                    _DashboardCard(
                      title: 'Products',
                      value: stats.totalProducts.toString(),
                      onTap: () => onNavigate(2),
                    ),
                    _DashboardCard(
                      title: 'Low Stock',
                      value: stats.lowStockCount.toString(),
                      onTap: () => onNavigate(3),
                    ),
                    _DashboardCard(
                      title: 'Out Of Stock',
                      value: stats.outOfStockCount.toString(),
                      onTap: () => onNavigate(3),
                    ),
                    _DashboardCard(
                      title: 'Users',
                      value: stats.totalUsers.toString(),
                      onTap: () => onNavigate(4),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Latest orders', style: AppTextStyles.headingMedium),
                    TextButton(
                      onPressed: () => onNavigate(1),
                      child: const Text('View all orders'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                recentOrdersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Text('No recent orders to display.');
                    }
                    return Column(
                      children: orders
                          .map((order) {
                            return _RecentOrderTile(order: order);
                          })
                          .toList(growable: false),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text(
                    'Unable to load latest orders: ${error.toString()}',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load dashboard statistics:\n${error.toString()}',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          order.orderId,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${order.paymentStatus} • ${order.status}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$${order.totalPrice}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${order.createdAt.toLocal()}'.split(' ').first,
              style: AppTextStyles.label,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminOrderDetail(order: order)),
          );
        },
      ),
    );
  }
}
