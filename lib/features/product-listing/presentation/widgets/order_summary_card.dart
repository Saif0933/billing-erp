import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_cart_provider.dart';

/// Summary panel for Product Listing — Save all scanned products (EAN + details) to DB.
/// This is NOT a sale checkout.
class OrderSummaryCard extends ConsumerWidget {
  final VoidCallback onFocusRequested;

  const OrderSummaryCard({
    super.key,
    required this.onFocusRequested,
  });

  Future<void> _handleSave(BuildContext context, WidgetRef ref, BillingCartState state) async {
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan at least one product before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final ok = await ref.read(billingCartProvider.notifier).saveAllToDatabase();
    if (!context.mounted) return;

    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF15803D), size: 28),
              SizedBox(width: 10),
              Text('Products Saved'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${state.itemCount} product(s) saved to database.'),
              const SizedBox(height: 8),
              const Text(
                'EAN, unit price, GST and all details are now in the catalogue. You can sell these products from Sales.',
                style: TextStyle(fontSize: 13),
              ),
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
                onFocusRequested();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listing Summary',
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
                  '${state.itemCount} Products',
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
          _buildSummaryRow(
            label: 'Products to list',
            value: '${state.itemCount}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Pending save',
            value: '${state.unsavedCount}',
            isDark: isDark,
            valueColor: state.unsavedCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Catalogue value',
            value: '₹${state.subtotal.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              'Enter unit price & GST for each product, then save. Listed products can be sold from Sales.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: state.items.isEmpty || state.isSaving
                ? null
                : () => _handleSave(context, ref, state),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(
              state.isSaving
                  ? 'Saving...'
                  : 'Save Products to Database (${state.itemCount})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.items.isEmpty
                ? null
                : () {
                    notifier.startNewInvoice();
                    onFocusRequested();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Clear Listing', style: TextStyle(fontSize: 12)),
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
