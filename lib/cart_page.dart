import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  late final Stream<List<CartItem>> _cartStream = _cartService.cartStream();

  String _formatPrice(int amount) {
    return '৳$amount';
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    try {
      await _cartService.updateQuantity(item.productId, quantity);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update cart item');
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _cartService.removeItem(item.productId);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to remove cart item');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.backgroundDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<CartItem>>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CartStateMessage(
              title: 'Unable to load cart',
              message: 'Please try again in a moment.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          final cartTotal = items.fold<int>(
            0,
            (total, item) => total + item.totalPrice,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  'Cart',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _CartStateMessage(
                        title: 'Your cart is empty',
                        message: 'Add products to see them here.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartItemTile(
                            item: item,
                            priceText: _formatPrice(item.price),
                            onDecrease: item.quantity == 1
                                ? null
                                : () =>
                                      _updateQuantity(item, item.quantity - 1),
                            onIncrease: () =>
                                _updateQuantity(item, item.quantity + 1),
                            onDelete: () => _removeItem(item),
                          );
                        },
                      ),
              ),
              _CartTotalBar(totalText: _formatPrice(cartTotal)),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.priceText,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final CartItem item;
  final String priceText;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 82,
              height: 82,
              color: AppColors.surfaceSoft,
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 34),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  priceText,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuantityControls(
                  quantity: item.quantity,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
        SizedBox(
          width: 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _QuantityButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceSoft,
          disabledBackgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.backgroundDark,
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CartTotalBar extends StatelessWidget {
  const _CartTotalBar({required this.totalText});

  final String totalText;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            totalText,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.backgroundDark,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartStateMessage extends StatelessWidget {
  const _CartStateMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
