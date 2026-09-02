import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_journal_provider.dart';

class JournalMetricCards extends ConsumerWidget {
  const JournalMetricCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(generalJournalDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 24) / 4;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Card 1: Total Journals (84)
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.note_alt_outlined,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                label: 'Total Journals',
                labelColor: const Color(0xFF16A34A),
                value: '${summary.totalJournals}',
                valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                subtitle: 'This Month',
                isDark: isDark,
              ),
            ),

            // Card 2: Total Debit (₹12,45,300.00)
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.currency_rupee,
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                label: 'Total Debit (₹)',
                labelColor: const Color(0xFF0284C7),
                value: '₹${_formatCurrency(summary.totalDebit)}',
                valueColor: const Color(0xFF0284C7),
                subtitle: 'This Month',
                isDark: isDark,
              ),
            ),

            // Card 3: Total Credit (₹12,45,300.00)
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.currency_rupee,
                iconBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                label: 'Total Credit (₹)',
                labelColor: const Color(0xFFDC2626),
                value: '₹${_formatCurrency(summary.totalCredit)}',
                valueColor: const Color(0xFFDC2626),
                subtitle: 'This Month',
                isDark: isDark,
              ),
            ),

            // Card 4: Out of Balance (0)
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.balance,
                iconBg: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                label: 'Out of Balance',
                labelColor: const Color(0xFF9333EA),
                value: '${summary.outOfBalanceCount}',
                valueColor: const Color(0xFF7E22CE),
                subtitle: 'This Month',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String value,
    required Color valueColor,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          // Top Icon & Label Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
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
