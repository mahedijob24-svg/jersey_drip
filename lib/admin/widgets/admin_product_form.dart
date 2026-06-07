import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';

class AdminProductForm extends ConsumerStatefulWidget {
  const AdminProductForm({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends ConsumerState<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  final List<TextEditingController> _imageControllers = [];
  final List<_SizeEntry> _sizes = [];
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product?.discountedPrice.toStringAsFixed(0) ?? '',
    );
    _originalPriceController = TextEditingController(
      text: product?.price.toStringAsFixed(0) ?? '',
    );
    _active = product?.isActive ?? true;

    final images = product?.images ?? [];
    if (images.isNotEmpty) {
      for (final url in images) {
        _imageControllers.add(TextEditingController(text: url));
      }
    } else {
      _imageControllers.add(TextEditingController());
    }

    if (product != null && product.sizes.isNotEmpty) {
      for (final entry in product.sizes.entries) {
        _sizes.add(
          _SizeEntry(
            labelController: TextEditingController(text: entry.key),
            priceController: TextEditingController(
              text: entry.value.price.toString(),
            ),
            stockController: TextEditingController(
              text: entry.value.stock.toString(),
            ),
          ),
        );
      }
    } else {
      _sizes.add(
        _SizeEntry(
          labelController: TextEditingController(),
          priceController: TextEditingController(),
          stockController: TextEditingController(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    for (final controller in _imageControllers) {
      controller.dispose();
    }
    for (final row in _sizes) {
      row.labelController.dispose();
      row.priceController.dispose();
      row.stockController.dispose();
    }
    super.dispose();
  }

  void _addSizeRow() {
    setState(() {
      _sizes.add(
        _SizeEntry(
          labelController: TextEditingController(),
          priceController: TextEditingController(),
          stockController: TextEditingController(),
        ),
      );
    });
  }

  void _removeSizeRow(int index) {
    if (_sizes.length <= 1) return;
    setState(() {
      _sizes[index].dispose();
      _sizes.removeAt(index);
    });
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length <= 1) return;
    setState(() {
      _imageControllers[index].dispose();
      _imageControllers.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final originalPrice =
        int.tryParse(_originalPriceController.text.trim()) ?? 0;
    final images = _imageControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final sizes = <String, Map<String, Object>>{};
    for (final entry in _sizes) {
      final sizeLabel = entry.labelController.text.trim();
      if (sizeLabel.isEmpty) continue;
      final sizePrice =
          int.tryParse(entry.priceController.text.trim()) ?? price;
      final stock = int.tryParse(entry.stockController.text.trim()) ?? 0;
      sizes[sizeLabel] = {'price': sizePrice, 'stock': stock};
    }

    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one size with stock.'),
        ),
      );
      return;
    }

    final productData = <String, Object>{
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imagePath': images.isNotEmpty ? images.first : '',
      'images': images,
      'sizes': sizes,
      'isActive': _active,
    };

    setState(() => _saving = true);
    try {
      if (widget.product == null) {
        await ref.read(adminServiceProvider).addProduct(productData);
      } else {
        await ref
            .read(adminServiceProvider)
            .updateProduct(widget.product!.id, productData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product created.' : 'Product updated.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Category is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? 'Valid price required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _originalPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Original Price',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? 'Valid original price required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Text('Active status', style: AppTextStyles.label),
                    const SizedBox(width: AppSpacing.sm),
                    Switch(
                      value: _active,
                      activeColor: AppColors.accent,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Images',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._buildImageFields(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add image field'),
                  onPressed: _addImageField,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sizes',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._buildSizeRows(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add size'),
                  onPressed: _addSizeRow,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _saving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.product == null
                              ? 'Create product'
                              : 'Save product',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImageFields() {
    return List.generate(_imageControllers.length, (index) {
      final controller = _imageControllers[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Image URL ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Image URL required' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_imageControllers.length > 1)
              IconButton(
                onPressed: () => _removeImageField(index),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildSizeRows() {
    return List.generate(_sizes.length, (index) {
      final item = _sizes[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: item.labelController,
                decoration: const InputDecoration(
                  labelText: 'Size',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Size label required'
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: item.priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    int.tryParse(value ?? '') == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: item.stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    int.tryParse(value ?? '') == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_sizes.length > 1)
              IconButton(
                onPressed: () => _removeSizeRow(index),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      );
    });
  }
}

class _SizeEntry {
  _SizeEntry({
    required this.labelController,
    required this.priceController,
    required this.stockController,
  });

  final TextEditingController labelController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}
