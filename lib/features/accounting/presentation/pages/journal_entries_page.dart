import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../widgets/journal_balance_summary_card.dart';
import '../widgets/journal_category_tabs.dart';
import '../widgets/journal_entries_table.dart';
import '../widgets/journal_metric_cards.dart';
import '../widgets/journal_quick_actions_card.dart';
import '../widgets/journal_search_filter_bar.dart';
import '../widgets/new_journal_dialog.dart';

class JournalEntriesPage extends ConsumerWidget {
  const JournalEntriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'General Journal');
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
              // Page Header: General Journal + [ + New Journal ▾ ] Button
              _buildPageHeader(context, isDark),
              const SizedBox(height: 16),

              // 4 KPI Metric Cards (84 Total Journals, ₹12,45,300 Debit, ₹12,45,300 Credit, 0 Out of Balance)
              const JournalMetricCards(),
              const SizedBox(height: 16),

              // Search & Filter Bar (Search + Filters + Date Range + Type + Status + Reset)
              const JournalSearchFilterBar(),
              const SizedBox(height: 12),

              // Category Tabs (Journal List, Drafts, Recurring Journals, Journal Templates)
              const JournalCategoryTabs(),
              const SizedBox(height: 12),

              // Journal Entries Data Table & Pagination
              const JournalEntriesTable(),
              const SizedBox(height: 16),

              // Bottom Section: Balance Summary Card + Quick Actions Card
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 750;

                  if (isSmall) {
                    return Column(
                      children: const [
                        JournalBalanceSummaryCard(),
                        SizedBox(height: 16),
                        JournalQuickActionsCard(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 5, child: JournalBalanceSummaryCard()),
                      SizedBox(width: 16),
                      Expanded(flex: 5, child: JournalQuickActionsCard()),
                    ],
                  );
                },
              ),
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
                'General Journal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Record and manage day-to-day journal entries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Right: [ + New Journal ▾ ] Filled Green Button
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: PopupMenuButton<String>(
            onSelected: (val) {
              NewJournalDialog.show(context);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'standard',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF15803D)),
                    SizedBox(width: 8),
                    Text('Standard Journal', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'adjustment',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('Adjustment Journal', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recurring',
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 16, color: Color(0xFFEA580C)),
                    SizedBox(width: 8),
                    Text('Recurring Journal', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D), // Green filled button matching screenshot
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
                    'New Journal',
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
