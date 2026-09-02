import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../widgets/statement_data_table.dart';
import '../widgets/statement_filter_bar.dart';
import '../widgets/statement_profit_trend_card.dart';
import '../widgets/statement_quick_actions_card.dart';
import '../widgets/statement_report_cards.dart';
import '../widgets/statement_summary_card.dart';

class FinancialReportsPage extends ConsumerWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Financial Statements');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header: Financial Statements + [ Generate Report ▾ ]
              _buildPageHeader(context, isDark),
              const SizedBox(height: 16),

              // 4 Report Cards (Profit & Loss, Balance Sheet, Cash Flow, Equity Changes)
              const StatementReportCards(),
              const SizedBox(height: 16),

              // Filter Bar (Report Type, Date Range, Compare With, Filters)
              const StatementFilterBar(),
              const SizedBox(height: 16),

              // Statement Comparison Data Table Card
              const StatementDataTable(),
              const SizedBox(height: 16),

              // Financial Summary & Profit Trend Cards (Side-by-side on desktop, stacked on mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 750;

                  if (isSmall) {
                    return Column(
                      children: const [
                        StatementSummaryCard(),
                        SizedBox(height: 16),
                        StatementProfitTrendCard(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 5, child: StatementSummaryCard()),
                      SizedBox(width: 16),
                      Expanded(flex: 5, child: StatementProfitTrendCard()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quick Actions Card (Custom Report, Schedule Report, Export to Excel, Print Report, Save Layout)
              const StatementQuickActionsCard(),
              const SizedBox(height: 24),

              // Copyright Footer
              Center(
                child: Text(
                  '© 2026 Tax Bunny Retail Store. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Title + Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Financial Statements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Generate and analyze your business financial statements',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Right: [ Generate Report ▾ ] Green filled button
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: PopupMenuButton<String>(
            onSelected: (val) {},
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'pnl',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: Color(0xFF15803D)),
                    SizedBox(width: 8),
                    Text('Generate P&L Report', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bs',
                child: Row(
                  children: [
                    Icon(Icons.balance_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('Generate Balance Sheet', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cf',
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: Color(0xFF9333EA)),
                    SizedBox(width: 8),
                    Text('Generate Cash Flow', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D), // Green filled button
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF15803D).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Generate Report',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
