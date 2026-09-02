import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_statements_provider.dart';

class StatementReportCards extends ConsumerWidget {
  const StatementReportCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(financialStatementFilterProvider);
    final notifier = ref.read(financialStatementFilterProvider.notifier);
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
            // Card 1: Profit & Loss Statement
            SizedBox(
              width: cardWidth,
              child: _buildReportCard(
                icon: Icons.description_outlined,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                title: 'Profit & Loss Statement',
                subtitle: 'View your income and expenses performance',
                btnBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFF0FDF4),
                btnColor: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                isSelected: filter.reportType == FinancialReportType.profitAndLoss,
                onTap: () => notifier.setReportType(FinancialReportType.profitAndLoss, 'Profit & Loss Statement'),
                isDark: isDark,
              ),
            ),

            // Card 2: Balance Sheet
            SizedBox(
              width: cardWidth,
              child: _buildReportCard(
                icon: Icons.balance_outlined,
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Balance Sheet',
                subtitle: 'View your assets, liabilities and equity position',
                btnBg: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.4) : const Color(0xFFF0F9FF),
                btnColor: const Color(0xFF0284C7),
                isSelected: filter.reportType == FinancialReportType.balanceSheet,
                onTap: () => notifier.setReportType(FinancialReportType.balanceSheet, 'Balance Sheet'),
                isDark: isDark,
              ),
            ),

            // Card 3: Cash Flow Statement
            SizedBox(
              width: cardWidth,
              child: _buildReportCard(
                icon: Icons.payments_outlined,
                iconBg: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                title: 'Cash Flow Statement',
                subtitle: 'Track cash inflows and outflows',
                btnBg: isDark ? const Color(0xFF581C87).withValues(alpha: 0.4) : const Color(0xFFFAF5FF),
                btnColor: const Color(0xFF9333EA),
                isSelected: filter.reportType == FinancialReportType.cashFlow,
                onTap: () => notifier.setReportType(FinancialReportType.cashFlow, 'Cash Flow Statement'),
                isDark: isDark,
              ),
            ),

            // Card 4: Statement of Changes in Equity
            SizedBox(
              width: cardWidth,
              child: _buildReportCard(
                icon: Icons.bar_chart_rounded,
                iconBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                title: 'Statement of Changes in Equity',
                subtitle: 'View changes in equity over time',
                btnBg: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.4) : const Color(0xFFFFF7ED),
                btnColor: const Color(0xFFEA580C),
                isSelected: filter.reportType == FinancialReportType.equityChanges,
                onTap: () => notifier.setReportType(FinancialReportType.equityChanges, 'Statement of Changes in Equity'),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color btnBg,
    required Color btnColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF059669) : const Color(0xFF15803D))
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF15803D).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // View Report Button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Report',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: btnColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 13, color: btnColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
