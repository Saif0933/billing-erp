import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../widgets/coa_add_account_dialog.dart';
import '../widgets/coa_category_tabs.dart';
import '../widgets/coa_metric_cards.dart';
import '../widgets/coa_search_toolbar.dart';
import '../widgets/coa_summary_card.dart';
import '../widgets/coa_tree_table.dart';

class ChartOfAccountsPage extends ConsumerWidget {
  const ChartOfAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Chart of Accounts');
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
              // Page Header (Matching exact screenshot top)
              _buildPageHeader(context, isDark),
              const SizedBox(height: 16),

              // 4 KPI Metric Cards (156 Total Accounts, 78 Groups, 96 Ledger Accounts, ₹12,45,300.00)
              const CoaMetricCards(),
              const SizedBox(height: 16),

              // Search Input & Filters Toolbar
              const CoaSearchToolbar(),
              const SizedBox(height: 12),

              // Category Tabs (All Accounts, Assets, Liabilities, Equity, Income, Expenses)
              const CoaCategoryTabs(),
              const SizedBox(height: 12),

              // Hierarchical Tree Table
              const CoaTreeTable(),
              const SizedBox(height: 16),

              // Bottom Account Summary Card
              const CoaSummaryCard(),
              const SizedBox(height: 24),
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
        // Left: Green Tree Icon + Title + Subtitle
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 22,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chart of Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organize and manage all your ledger accounts',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Right: [ + Add Account ] Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(
              color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
              width: 1,
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          icon: Icon(
            Icons.add,
            size: 15,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
          ),
          label: Text(
            'Add Account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
          ),
          onPressed: () => CoaAddAccountDialog.show(context),
        ),
      ],
    );
  }
}
