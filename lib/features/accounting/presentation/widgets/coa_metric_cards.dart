import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_of_accounts_provider.dart';

class CoaMetricCards extends ConsumerWidget {
  const CoaMetricCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(coaDataProvider);
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
            // Card 1: Total Accounts (156)
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                value: '${summary.totalAccounts}',
                title: 'Total Accounts',
                subtitle: 'Active Accounts',
                isDark: isDark,
              ),
            ),

            // Card 2: Groups (78)
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                icon: Icons.groups_rounded,
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                value: '${summary.groups}',
                title: 'Groups',
                subtitle: 'Account Groups',
                isDark: isDark,
              ),
            ),

            // Card 3: Ledger Accounts (96)
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                icon: Icons.menu_book_rounded,
                iconBg: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                value: '${summary.ledgerAccounts}',
                title: 'Ledger Accounts',
                subtitle: 'Under Groups',
                isDark: isDark,
              ),
            ),

            // Card 4: Total Balance (₹12,45,300.00)
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                icon: Icons.pie_chart_outline_rounded,
                iconBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                value: '₹${_formatCurrency(summary.totalBalance)}',
                title: 'Total Balance',
                subtitle: 'All Accounts',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),

          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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
