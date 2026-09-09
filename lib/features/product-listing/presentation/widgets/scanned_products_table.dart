import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/billing_cart_provider.dart';

/// Desktop & Tablet Product Listing table with manual Unit Price & GST editing.
class ScannedProductsTable extends ConsumerWidget {
  final VoidCallback onActionCompleted;

  const ScannedProductsTable({
    super.key,
    required this.onActionCompleted,
  });

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.4,
  );

  static const _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingCartProvider);
    final notifier = ref.read(billingCartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 820,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 36, child: Text('#', style: _headerStyle)),
                  Expanded(flex: 4, child: Text('Product & EAN', style: _headerStyle)),
                  SizedBox(width: 110, child: Text('Unit Price', style: _headerStyle, textAlign: TextAlign.right)),
                  SizedBox(width: 100, child: Text('GST %', style: _headerStyle, textAlign: TextAlign.center)),
                  SizedBox(width: 90, child: Text('MRP', style: _headerStyle, textAlign: TextAlign.right)),
                  SizedBox(width: 50, child: Text('', style: _headerStyle, textAlign: TextAlign.center)),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final isLastScanned = state.lastScannedProduct?.id == item.product.id;

                return _buildRow(
                  context: context,
                  index: index + 1,
                  item: item,
                  isDark: isDark,
                  isHighlighted: isLastScanned,
                  isSaved: state.savedProductIds.contains(item.product.id),
                  notifier: notifier,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required int index,
    required CartItem item,
    required bool isDark,
    required bool isHighlighted,
    required bool isSaved,
    required BillingCartNotifier notifier,
  }) {
    final p = item.product;
    final gstValue = _gstOptions.contains(p.gstRate) ? p.gstRate : _gstOptions.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isHighlighted
          ? (isDark
              ? const Color(0xFF15803D).withValues(alpha: 0.18)
              : const Color(0xFFDCFCE7).withValues(alpha: 0.6))
          : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      p.placeholderIcon,
                      size: 18,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSaved)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.cloud_done, size: 14, color: Color(0xFF16A34A)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          p.barcode,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Editable Unit Price
          SizedBox(
            width: 110,
            child: TextFormField(
              initialValue: p.sellingPrice > 0 ? p.sellingPrice.toStringAsFixed(2) : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                isDense: true,
                prefixText: '₹ ',
                hintText: '0.00',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onChanged: (val) {
                final price = double.tryParse(val.trim());
                if (price != null) {
                  notifier.updateUnitPrice(p.id, price);
                }
              },
              onFieldSubmitted: (_) => onActionCompleted(),
            ),
          ),
          const SizedBox(width: 8),
          // Editable GST dropdown
          SizedBox(
            width: 92,
            child: DropdownButtonFormField<double>(
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
          ),
          SizedBox(
            width: 90,
            child: Text(
              p.mrp > 0 ? '₹${p.mrp.toStringAsFixed(2)}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.redAccent.shade200,
                tooltip: 'Remove',
                onPressed: () {
                  notifier.removeItem(p.id);
                  onActionCompleted();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
