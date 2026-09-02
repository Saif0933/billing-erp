import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_ledger_provider.dart';

class LedgerInsightsCard extends ConsumerWidget {
  const LedgerInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(generalLedgerDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isBalanced = summary.isBalanced;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryNarrow = constraints.maxWidth < 340;

          if (isVeryNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isBalanced
                      ? 'Your total transactions are balanced.\nKeep up the good work!'
                      : 'Difference of ₹${summary.closingBalance.toStringAsFixed(2)} detected between debits and credits.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBadge(isBalanced, isDark),
              ],
            );
          }

          return Row(
            children: [
              // Left Bar Chart Icon in light green box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 24,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 12),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBalanced
                          ? 'Your total transactions are balanced.\nKeep up the good work!'
                          : 'Difference of ₹${summary.closingBalance.toStringAsFixed(2)} detected between debits and credits.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right Status Badge: ✔ Balanced (Debits = Credits)
              _buildBadge(isBalanced, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(bool isBalanced, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isBalanced
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBalanced
              ? (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
              : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.error_outline,
                size: 15,
                color: isBalanced
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                    : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
              ),
              const SizedBox(width: 5),
              Text(
                isBalanced ? 'Balanced' : 'Unbalanced',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isBalanced
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                      : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isBalanced ? 'Debits = Credits' : 'Review Postings',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isBalanced
                  ? (isDark ? const Color(0xFF34D399).withValues(alpha: 0.8) : const Color(0xFF16A34A))
                  : (isDark ? const Color(0xFFF87171).withValues(alpha: 0.8) : const Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
