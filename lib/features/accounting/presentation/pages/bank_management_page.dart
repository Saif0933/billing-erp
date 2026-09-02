import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../widgets/add_bank_account_dialog.dart';
import '../widgets/bank_accounts_table.dart';
import '../widgets/bank_balance_overview_card.dart';
import '../widgets/bank_category_tabs.dart';
import '../widgets/bank_metric_cards.dart';
import '../widgets/bank_quick_actions_card.dart';
import '../widgets/bank_recent_transactions_card.dart';
import '../widgets/bank_search_filter_bar.dart';

class BankManagementPage extends ConsumerWidget {
  const BankManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Bank Accounts');
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
              // Page Header: Bank Accounts + [ + Add Bank Account ▾ ] Button
              _buildPageHeader(context, isDark),
              const SizedBox(height: 16),

              // 4 KPI Metric Cards (5 Total Accounts, ₹18,75,430.50 Total Balance, ₹17,92,310.50 Cleared, ₹83,120 Uncleared)
              const BankMetricCards(),
              const SizedBox(height: 16),

              // Category Tabs (All Accounts, Current Accounts, Savings Accounts, Credit Accounts, Inactive Accounts)
              const BankCategoryTabs(),
              const SizedBox(height: 12),

              // Search & Filter Toolbar (Search + Filters + More)
              const BankSearchFilterBar(),
              const SizedBox(height: 12),

              // Bank Accounts Data Table & Pagination
              const BankAccountsTable(),
              const SizedBox(height: 16),

              // Balance Overview Card & Recent Transactions Card (Side-by-side on desktop, stacked on mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 750;

                  if (isSmall) {
                    return Column(
                      children: const [
                        BankBalanceOverviewCard(),
                        SizedBox(height: 16),
                        BankRecentTransactionsCard(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 5, child: BankBalanceOverviewCard()),
                      SizedBox(width: 16),
                      Expanded(flex: 5, child: BankRecentTransactionsCard()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quick Actions Card (Add Bank Account, Bank Reconciliation, Import Statement, Cheque Register, Account Reports)
              const BankQuickActionsCard(),
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
        // Left: Green Bank Icon + Title + Subtitle
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 24,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bank Accounts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage all your bank accounts and view balances',
                      style: TextStyle(
                        fontSize: 12,
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

        // Right: [ + Add Bank Account ▾ ] Green filled button
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: PopupMenuButton<String>(
            onSelected: (val) {
              AddBankAccountDialog.show(context);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'current',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF15803D)),
                    SizedBox(width: 8),
                    Text('Add Current Account', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'savings',
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('Add Savings Account', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'overdraft',
                child: Row(
                  children: [
                    Icon(Icons.credit_card_outlined, size: 16, color: Color(0xFF9333EA)),
                    SizedBox(width: 8),
                    Text('Add Overdraft Account', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Add Bank Account',
                    style: TextStyle(
                      fontSize: 12.5,
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
