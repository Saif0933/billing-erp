import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/billing_cart_provider.dart';
import 'product_supplier_field.dart';

/// Mobile card for a listed product with editable unit price & GST.
class ScannedProductCard extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onActionCompleted;

  const ScannedProductCard({
    super.key,
    required this.item,
    required this.onActionCompleted,
  });

  static const _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(billingCartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = item.product;
    final gstValue = _gstOptions.contains(p.gstRate) ? p.gstRate : _gstOptions.first;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Icon(p.placeholderIcon, size: 20, color: const Color(0xFF15803D)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'EAN: ${p.barcode}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                        if (p.variant.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.variant,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Quantity Stepper (Increase / Decrease)
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        notifier.decrementQuantity(p.id);
                        onActionCompleted();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        notifier.incrementQuantity(p.id);
                        onActionCompleted();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 11,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.redAccent.shade200,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  notifier.removeItem(p.id);
                  onActionCompleted();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ProductSupplierField(
            dense: true,
            supplierId: p.supplierId,
            supplierName: p.supplierName,
            onChanged: (sel) {
              notifier.updateSupplier(p.id, sel.id, sel.name);
              onActionCompleted();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit Price *',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: p.sellingPrice > 0 ? p.sellingPrice.toStringAsFixed(2) : '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '₹ ',
                        hintText: '0.00',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (val) {
                        final price = double.tryParse(val.trim());
                        if (price != null) notifier.updateUnitPrice(p.id, price);
                      },
                      onFieldSubmitted: (_) => onActionCompleted(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GST % *',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      initialValue: gstValue,
                      isDense: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      items: _gstOptions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.toInt()}%', style: const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateGstRate(p.id, val);
                          onActionCompleted();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
