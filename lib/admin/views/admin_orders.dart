import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import 'admin_order_detail.dart';

class AdminOrders extends ConsumerStatefulWidget {
  const AdminOrders({super.key});

  @override
  ConsumerState<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends ConsumerState<AdminOrders> {
  final _searchController = TextEditingController();
  String _status = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order management', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Search, filter, and update order status from a single place.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search orders',
                    hintText: 'Search by order ID or customer ID',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'processing',
                    child: Text('Processing'),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child: Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final searchValue = _searchController.text.trim().toLowerCase();
                final filteredOrders = orders
                    .where((order) {
                      if (_status != 'all' &&
                          order.status.toLowerCase() != _status) {
                        return false;
                      }
                      if (searchValue.isEmpty) return true;
                      return order.orderId.toLowerCase().contains(
                            searchValue,
                          ) ||
                          order.userId.toLowerCase().contains(searchValue);
                    })
                    .toList(growable: false);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders match the current search or filter.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _OrderCard(order: order);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load orders: ${error.toString()}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        title: Text(
          order.orderId,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text('User: ${order.userId}', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Payment: ${order.paymentStatus} • ${order.paymentMethod}',
              style: AppTextStyles.body,
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: order.status.toLowerCase() == 'delivered'
                    ? AppColors.success.withOpacity(0.15)
                    : order.status.toLowerCase() == 'cancelled'
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.status.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '\$${order.totalPrice}',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
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
