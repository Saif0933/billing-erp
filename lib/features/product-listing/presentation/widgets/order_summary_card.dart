import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_cart_provider.dart';

/// Production-grade Order Summary Card calculating real-time Subtotal,
/// Item & Bill Discounts, Taxable Base, GST Breakdown, and Grand Total.
class OrderSummaryCard extends ConsumerStatefulWidget {
  final VoidCallback onFocusRequested;

  const OrderSummaryCard({
    super.key,
    required this.onFocusRequested,
  });

  @override
  ConsumerState<OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends ConsumerState<OrderSummaryCard> {
  late TextEditingController _discountCtrl;
  bool _isEditingDiscount = false;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _handleCheckout(BillingCartState state) {
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one product before checkout.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF15803D), size: 28),
            SizedBox(width: 10),
            Text('Sale Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice ${state.invoiceNumber} recorded successfully.'),
            const SizedBox(height: 12),
            Text('Total Items: ${state.itemCount} (${state.totalQuantity} units)'),
            Text('Grand Total: ₹${state.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Local mock bill has been processed without server dependency.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(billingCartProvider.notifier).startNewInvoice();
              widget.onFocusRequested();
            },
            child: const Text('Start Next Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingCartProvider);
    final notifier = ref.read(billingCartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Summary Title + Item Counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.itemCount} Items (${state.totalQuantity} Qty)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Subtotal
          _buildSummaryRow(
            label: 'Subtotal (Gross)',
            value: '₹${state.subtotal.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // Discount Row (Editable)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Bill Discount',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => _isEditingDiscount = !_isEditingDiscount),
                    child: Icon(
                      _isEditingDiscount ? Icons.check_circle : Icons.edit_outlined,
                      size: 14,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              if (_isEditingDiscount)
                SizedBox(
                  width: 80,
                  height: 28,
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      final d = double.tryParse(val) ?? 0.0;
                      notifier.setBillDiscount(d);
                      setState(() => _isEditingDiscount = false);
                      widget.onFocusRequested();
                    },
                  ),
                )
              else
                Text(
                  '- ₹${state.totalDiscount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: state.totalDiscount > 0 ? Colors.redAccent : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Taxable Base Amount
          _buildSummaryRow(
            label: 'Taxable Amount',
            value: '₹${state.taxableAmount.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // GST Tax Breakdown
          _buildSummaryRow(
            label: 'Total GST Tax',
            value: '+ ₹${state.gstAmount.toStringAsFixed(2)}',
            isDark: isDark,
            valueColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Grand Total (Large Highlight)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '₹${state.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Checkout / Pay Button
          ElevatedButton.icon(
            onPressed: state.items.isEmpty ? null : () => _handleCheckout(state),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D), // Green
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              'Complete Sale (₹${state.grandTotal.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Start New Sale / Clear Bill Button
          OutlinedButton.icon(
            onPressed: state.items.isEmpty
                ? null
                : () {
                    notifier.startNewInvoice();
                    widget.onFocusRequested();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Clear / New Invoice', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
