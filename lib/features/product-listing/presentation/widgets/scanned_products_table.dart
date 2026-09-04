import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/billing_cart_provider.dart';

/// Desktop & Tablet Scanned Products Data Table with inline quantity controls
/// and reactive tax/subtotal calculation.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingCartProvider);
    final notifier = ref.read(billingCartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 780,
        child: Column(
          children: [
            // Table Header Row
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
              child: Row(
                children: const [
                  SizedBox(width: 36, child: Text('#', style: _headerStyle)),
                  Expanded(flex: 4, child: Text('Product & Barcode', style: _headerStyle)),
                  SizedBox(width: 90, child: Text('Unit Price', style: _headerStyle, textAlign: TextAlign.right)),
                  SizedBox(width: 130, child: Text('Quantity', style: _headerStyle, textAlign: TextAlign.center)),
                  SizedBox(width: 90, child: Text('GST Rate', style: _headerStyle, textAlign: TextAlign.right)),
                  SizedBox(width: 100, child: Text('Total (₹)', style: _headerStyle, textAlign: TextAlign.right)),
                  SizedBox(width: 50, child: Text('Act', style: _headerStyle, textAlign: TextAlign.center)),
                ],
              ),
            ),

            // Table Rows
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
    required BillingCartNotifier notifier,
  }) {
    final p = item.product;

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
          // Index
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

          // Product Details (Name, Barcode, SKU)
          Expanded(
            flex: 4,
            child: Row(
              children: [
                // Product Icon / Thumbnail
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
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
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
                          const SizedBox(width: 6),
                          Text(
                            p.sku,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Unit Price & MRP
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹${p.sellingPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (p.mrp > p.sellingPrice)
                  Text(
                    '₹${p.mrp.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      decoration: TextDecoration.lineThrough,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),

          // Quantity Controls (− 1 +)
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrease Button
                InkWell(
                  onTap: () {
                    notifier.decrementQuantity(p.id);
                    onActionCompleted();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Icon(
                      item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                      size: 15,
                      color: item.quantity == 1 ? Colors.redAccent : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Current Qty Number
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Increase Button
                InkWell(
                  onTap: () {
                    notifier.incrementQuantity(p.id);
                    onActionCompleted();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D), // Green
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GST Rate & Amount
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${p.gstRate.toInt()}% GST',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                Text(
                  '₹${item.gstAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Line Total Amount
          SizedBox(
            width: 100,
            child: Text(
              '₹${item.totalAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),

          // Delete Action
          SizedBox(
            width: 50,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.redAccent.shade200,
                tooltip: 'Remove Item',
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
