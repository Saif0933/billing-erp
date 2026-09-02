import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_ledger_provider.dart';

class LedgerSummarySection extends ConsumerWidget {
  const LedgerSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(generalLedgerDataProvider);
    final filter = ref.watch(generalLedgerFilterProvider);
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Summary (This Month) ⓘ  and  [ 01 May - 31 May 2026 ▾ ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '(This Month)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildDateDropdown(context, ref, filter.dateRangeLabel, isDark),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Metric Cards in horizontal scroll / flex
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final cardWidth = isSmall
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 24) / 4;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      icon: Icons.refresh_rounded,
                      iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      label: 'Total Debit',
                      value: '₹${_formatCurrency(summary.totalDebit)}',
                      valueColor: const Color(0xFF16A34A),
                      cardBg: isDark ? const Color(0xFF06281E) : const Color(0xFFF0FDF4),
                      borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      icon: Icons.arrow_upward_rounded,
                      iconBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      label: 'Total Credit',
                      value: '₹${_formatCurrency(summary.totalCredit)}',
                      valueColor: const Color(0xFFDC2626),
                      cardBg: isDark ? const Color(0xFF2C0B0E) : const Color(0xFFFEF2F2),
                      borderColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFEE2E2),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      label: 'Closing Balance',
                      value: '₹${_formatCurrency(summary.closingBalance)}',
                      valueColor: const Color(0xFF0284C7),
                      cardBg: isDark ? const Color(0xFF082F49) : const Color(0xFFF0F9FF),
                      borderColor: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      icon: Icons.description_outlined,
                      iconBg: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      label: 'Total Entries',
                      value: '${summary.totalEntries}',
                      valueColor: const Color(0xFF9333EA),
                      cardBg: isDark ? const Color(0xFF2E1065) : const Color(0xFFFAF5FF),
                      borderColor: isDark ? const Color(0xFF7E22CE) : const Color(0xFFE9D5FF),
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateDropdown(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (range != null) {
          final fmt =
              '${range.start.day.toString().padLeft(2, '0')} ${_monthName(range.start.month)} – ${range.end.day.toString().padLeft(2, '0')} ${_monthName(range.end.month)} ${range.end.year}';
          ref.read(generalLedgerFilterProvider.notifier).setDateRange(fmt, range);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0.00';
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

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
