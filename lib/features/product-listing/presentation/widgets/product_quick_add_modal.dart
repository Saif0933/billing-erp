import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/product_listing_models.dart';
import '../providers/product_listing_provider.dart';

class ProductQuickAddModal extends ConsumerStatefulWidget {
  final ProductListingItem item;

  const ProductQuickAddModal({super.key, required this.item});

  static void show(BuildContext context, ProductListingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ProductQuickAddModal(item: item),
    );
  }

  @override
  ConsumerState<ProductQuickAddModal> createState() => _ProductQuickAddModalState();
}

class _ProductQuickAddModalState extends ConsumerState<ProductQuickAddModal> {
  int _quantity = 1;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _mrpController;
  late String _selectedCategory;
  bool _isEditingDetails = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.sellingPrice.toStringAsFixed(2));
    _mrpController = TextEditingController(text: widget.item.mrp.toStringAsFixed(2));
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  void _saveProductEdits() {
    final double? parsedPrice = double.tryParse(_priceController.text);
    final double? parsedMrp = double.tryParse(_mrpController.text);

    final updated = widget.item.copyWith(
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.item.name,
      sellingPrice: parsedPrice ?? widget.item.sellingPrice,
      mrp: parsedMrp ?? widget.item.mrp,
      category: _selectedCategory,
    );

    ref.read(productListingProvider.notifier).updateProduct(updated);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double currentPrice = double.tryParse(_priceController.text) ?? item.sellingPrice;
    final total = _quantity * currentPrice;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Thumbnail + Product Info / Name Field + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Icon(item.placeholderIcon, size: 28, color: item.iconColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditingDetails)
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Product Name',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nameController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Color(0xFF15803D)),
                                tooltip: 'Edit Product Name & Details',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _isEditingDetails = true),
                              ),
                            ],
                          ),
                        const SizedBox(height: 3),
                        Text(
                          'Barcode: ${item.barcode}  •  Stock: ${item.stock} ${item.unit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Price & Category Highlights / Editable Box
              if (_isEditingDetails)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF15803D)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mrpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'MRP (₹)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: ['Dairy', 'Snacks', 'Biscuits', 'Beverages', 'Home Care', 'Personal Care', 'Groceries', 'Scanned Items'].contains(_selectedCategory)
                            ? _selectedCategory
                            : 'Scanned Items',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                          DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                          DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                          DropdownMenuItem(value: 'Biscuits', child: Text('Biscuits')),
                          DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                          DropdownMenuItem(value: 'Home Care', child: Text('Home Care')),
                          DropdownMenuItem(value: 'Personal Care', child: Text('Personal Care')),
                          DropdownMenuItem(value: 'Scanned Items', child: Text('Scanned Items')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('MRP', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('₹ ${_mrpController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                      Container(height: 24, width: 1, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      Column(
                        children: [
                          Text('Selling Price', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('₹ ${_priceController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15803D))),
                        ],
                      ),
                      Container(height: 24, width: 1, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      Column(
                        children: [
                          Text('Category', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(_selectedCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Quantity Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Quantity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove, size: 18),
                        ),
                      ),
                      Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _quantity++);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15803D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Amount Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '₹ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons: [ Cancel ] + [ Save & Add to Invoice ]
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                    label: const Text('Add to Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () {
                      _saveProductEdits();
                      Navigator.pop(context);
                      AppFeedback.showSnackbar(
                        context,
                        message: 'Listed & Added $_quantity × ${_nameController.text} to invoice!',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
