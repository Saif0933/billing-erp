import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/billing_cart_provider.dart';

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
                    Text(
                      'EAN: ${p.barcode}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
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
