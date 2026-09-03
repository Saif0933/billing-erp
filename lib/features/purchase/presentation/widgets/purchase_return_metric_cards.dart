import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_return_provider.dart';

class PurchaseReturnMetricCards extends ConsumerWidget {
  const PurchaseReturnMetricCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(purchaseReturnMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 24) / 4;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Card 1: Total Returns Count
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Debit Notes',
                value: '${metrics.totalReturnsCount}',
                valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                subtitle: 'All Recorded Returns',
                icon: Icons.assignment_return_outlined,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                isDark: isDark,
              ),
            ),

            // Card 2: Total Return Value
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Return Value',
                value: '₹${_formatCurrency(metrics.totalReturnValue)}',
                valueColor: const Color(0xFF15803D),
                subtitle: 'Gross Value Returned',
                icon: Icons.currency_rupee,
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),

            // Card 3: Adjusted Against Bills
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Adjusted in Bills',
                value: '₹${_formatCurrency(metrics.adjustedAgainstBills)}',
                valueColor: const Color(0xFF0D9488),
                subtitle: 'Offset Against Payables',
                icon: Icons.check_circle_outline,
                iconBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                iconColor: const Color(0xFF0D9488),
                isDark: isDark,
              ),
            ),

            // Card 4: Pending Approvals/Refunds
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Pending / Refunds',
                value: '₹${_formatCurrency(metrics.pendingRefunds)}',
                valueColor: const Color(0xFFEA580C),
                subtitle: 'Awaiting Settlement',
                icon: Icons.hourglass_top_rounded,
                iconBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    if (whole.length <= 3) {
      return '$whole.$dec';
    }

    final lastThree = whole.substring(whole.length - 3);
    final otherNumbers = whole.substring(0, whole.length - 3);

    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedOther,$lastThree.$dec';
  }
}
