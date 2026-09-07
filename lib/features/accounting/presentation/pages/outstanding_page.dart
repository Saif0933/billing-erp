import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/feedback.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/models/outstanding_dto.dart';
import '../providers/outstanding_provider.dart';

class OutstandingPage extends ConsumerStatefulWidget {
  const OutstandingPage({super.key});

  @override
  ConsumerState<OutstandingPage> createState() => _OutstandingPageState();
}

class _OutstandingPageState extends ConsumerState<OutstandingPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outstandingProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(outstandingProvider.notifier).setSearchQuery(val.trim());
      }
    });
  }

  void _onBucketTap(String bucketKey) {
    final currentBucket = ref.read(outstandingProvider).bucketFilter;
    if (currentBucket == bucketKey) {
      ref.read(outstandingProvider.notifier).setBucketFilter('ALL');
    } else {
      ref.read(outstandingProvider.notifier).setBucketFilter(bucketKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.outstanding)) {
      return const LockedFeaturePage(featureName: 'Outstanding Analysis');
    }

    final outstandingState = ref.watch(outstandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTab = outstandingState.selectedTab;
    final isServerData =
        outstandingState.summary != null && !outstandingState.isUsingLocalFallback;

    // KPI & Ageing metrics from active summary
    double totalOutstanding = 0.0;
    double dueToday = 0.0;
    double totalOverdue = 0.0;
    double b0To30 = 0.0;
    double b31To60 = 0.0;
    double b61To90 = 0.0;
    double b91Plus = 0.0;
    double netWorkingCapital = 0.0;

    if (outstandingState.summary != null) {
      final cat = selectedTab == 'Receivables'
          ? outstandingState.summary!.receivables
          : outstandingState.summary!.payables;

      totalOutstanding = cat.totalOutstanding;
      dueToday = cat.dueToday;
      totalOverdue = cat.totalOverdue;
      b0To30 = cat.ageingBuckets.bucket0To30;
      b31To60 = cat.ageingBuckets.bucket31To60;
      b61To90 = cat.ageingBuckets.bucket61To90;
      b91Plus = cat.ageingBuckets.bucket91Plus;
      netWorkingCapital = outstandingState.summary!.netWorkingCapital;
    }

    final items = outstandingState.items;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(outstandingProvider.notifier).loadData();
          },
          color: const Color(0xFF15803D),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Page Header (Title, Sync Badge, Refresh, Quick Action)
                _buildPageHeader(context, isDark, isServerData, selectedTab, outstandingState.isLoading),
                const SizedBox(height: 12),

                // Live fetching progress indicator
                if (outstandingState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF15803D),
                        backgroundColor: Color(0xFFDCFCE7),
                      ),
                    ),
                  ),

                // 2. Receivables vs Payables Switcher & Net Working Capital Pill
                _buildTabSelector(isDark, selectedTab, netWorkingCapital),
                const SizedBox(height: 16),

                // 3. 3 Dynamic KPI Cards (Total, Due Today, Overdue)
                _buildKpiSection(
                  totalOutstanding: totalOutstanding,
                  dueToday: dueToday,
                  totalOverdue: totalOverdue,
                  selectedTab: selectedTab,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 4. Interactive Ageing Analysis Schedule (Clickable Buckets with Active Indicators)
                _buildAgeingSection(
                  totalOutstanding: totalOutstanding,
                  b0To30: b0To30,
                  b31To60: b31To60,
                  b61To90: b61To90,
                  b91Plus: b91Plus,
                  activeBucket: outstandingState.bucketFilter,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 5. Search & Status Filter Toolbar
                _buildSearchFilterBar(
                  isDark: isDark,
                  selectedTab: selectedTab,
                  statusFilter: outstandingState.statusFilter,
                  bucketFilter: outstandingState.bucketFilter,
                ),
                const SizedBox(height: 12),

                // 6. Dynamic Itemized Outstanding Statement Table
                _buildOutstandingTable(items, isDark, selectedTab),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
    bool isDark,
    bool isServerData,
    String selectedTab,
    bool isLoading,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title + Sync Pill
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Outstanding Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Live Cloud vs Offline Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isServerData
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isServerData
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isServerData ? 'Live Sync' : 'Local Offline',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isServerData
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Track ageing receivables, payables and cashflow timelines',
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

        // Server Refresh Action
        IconButton(
          tooltip: 'Refresh from Server',
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  size: 20,
                ),
          onPressed: () {
            ref.read(outstandingProvider.notifier).loadData();
          },
        ),
        const SizedBox(width: 4),

        // Record Payment / Receipt Action Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 1,
          ),
          icon: Icon(
            selectedTab == 'Receivables' ? Icons.receipt_long : Icons.payment,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            selectedTab == 'Receivables' ? 'Record Receipt' : 'Record Payment',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            if (selectedTab == 'Receivables') {
              context.push('/receipts/new');
            } else {
              context.push('/payments/new');
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabSelector(bool isDark, String selectedTab, double netWorkingCapital) {
    return Row(
      children: [
        // Tab Pills
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTabOption(
                    label: 'Receivables (Customers)',
                    icon: Icons.trending_up,
                    isSelected: selectedTab == 'Receivables',
                    onTap: () {
                      ref.read(outstandingProvider.notifier).setTab('Receivables');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  _buildTabOption(
                    label: 'Payables (Suppliers)',
                    icon: Icons.trending_down,
                    isSelected: selectedTab == 'Payables',
                    onTap: () {
                      ref.read(outstandingProvider.notifier).setTab('Payables');
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Net Working Capital Insight
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance,
                size: 14,
                color: netWorkingCapital >= 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Net Working Capital',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '₹${_formatCurrency(netWorkingCapital)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: netWorkingCapital >= 0
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF15803D)
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection({
    required double totalOutstanding,
    required double dueToday,
    required double totalOverdue,
    required String selectedTab,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final cardWidth =
            isSmall ? constraints.maxWidth : (constraints.maxWidth - 16) / 3;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Card 1: Total Outstanding
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Outstanding Balance',
                value: '₹${_formatCurrency(totalOutstanding)}',
                valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                subtitle: selectedTab == 'Receivables'
                    ? 'Total Pending Customer Bills'
                    : 'Total Pending Supplier Bills',
                badgeText: 'Overall',
                badgeBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                badgeColor: const Color(0xFF0284C7),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),

            // Card 2: Due Today
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Due Today',
                value: '₹${_formatCurrency(dueToday)}',
                valueColor: const Color(0xFFD97706),
                subtitle: 'Maturing On Current Date',
                badgeText: 'Action Required',
                badgeBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                badgeColor: const Color(0xFFD97706),
                icon: Icons.schedule_outlined,
                iconColor: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),

            // Card 3: Total Overdue
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Total Overdue Balance',
                value: '₹${_formatCurrency(totalOverdue)}',
                valueColor: const Color(0xFFDC2626),
                subtitle: 'Exceeded Credit Terms',
                badgeText: 'Critical',
                badgeBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                badgeColor: const Color(0xFFDC2626),
                icon: Icons.error_outline,
                iconColor: const Color(0xFFDC2626),
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
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title + Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Value Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeingSection({
    required double totalOutstanding,
    required double b0To30,
    required double b31To60,
    required double b61To90,
    required double b91Plus,
    required String activeBucket,
    required bool isDark,
  }) {
    final hasBucketFilter = activeBucket != 'ALL';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ageing Analysis Schedule + Clear Filter Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Ageing Analysis Schedule',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(Click card to filter)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasBucketFilter)
                InkWell(
                  onTap: () {
                    ref.read(outstandingProvider.notifier).setBucketFilter('ALL');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close, size: 12, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Clear Bucket Filter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Based on Invoice Date',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Clickable Bucket Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;
              final bucketWidth = isSmall
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 24) / 4;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard(
                      title: '0 – 30 Days',
                      bucketKey: '0-30',
                      amount: b0To30,
                      total: totalOutstanding,
                      color: const Color(0xFF15803D),
                      isSelected: activeBucket == '0-30',
                      onTap: () => _onBucketTap('0-30'),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard(
                      title: '31 – 60 Days',
                      bucketKey: '31-60',
                      amount: b31To60,
                      total: totalOutstanding,
                      color: const Color(0xFFD97706),
                      isSelected: activeBucket == '31-60',
                      onTap: () => _onBucketTap('31-60'),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard(
                      title: '61 – 90 Days',
                      bucketKey: '61-90',
                      amount: b61To90,
                      total: totalOutstanding,
                      color: const Color(0xFFEA580C),
                      isSelected: activeBucket == '61-90',
                      onTap: () => _onBucketTap('61-90'),
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard(
                      title: '90+ Days',
                      bucketKey: '91+',
                      amount: b91Plus,
                      total: totalOutstanding,
                      color: const Color(0xFFDC2626),
                      isSelected: activeBucket == '91+',
                      onTap: () => _onBucketTap('91+'),
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

  Widget _buildBucketCard({
    required String title,
    required String bucketKey,
    required double amount,
    required double total,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final ratio = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + Percentage / Active tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? color
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 12, color: color),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Amount
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${_formatCurrency(amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Visual Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilterBar({
    required bool isDark,
    required String selectedTab,
    required String statusFilter,
    required String bucketFilter,
  }) {
    return Row(
      children: [
        // Search Input (Real-time debounced)
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: selectedTab == 'Receivables'
                    ? 'Search by Invoice #, Customer, Phone...'
                    : 'Search by Purchase #, Supplier, Phone...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(outstandingProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Status Filter Dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: statusFilter == 'ALL' || statusFilter == 'All' ? 'ALL' : statusFilter,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                DropdownMenuItem(value: 'OVERDUE', child: Text('Overdue')),
                DropdownMenuItem(value: 'DUE TODAY', child: Text('Due Today')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(outstandingProvider.notifier).setStatusFilter(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingTable(
    List<OutstandingItemDto> items,
    bool isDark,
    String selectedTab,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Horizontally Scrollable Table Canvas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 860,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 125, child: Text('Ref Code', style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Date', style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Due Date', style: _headerStyle)),
                        Expanded(child: Text('Party Name / Contact', style: _headerStyle)),
                        SizedBox(
                          width: 105,
                          child: Text('Bill Val (₹)', textAlign: TextAlign.right, style: _headerStyle),
                        ),
                        SizedBox(
                          width: 105,
                          child: Text('Balance (₹)', textAlign: TextAlign.right, style: _headerStyle),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text('Age', textAlign: TextAlign.center, style: _headerStyle),
                        ),
                        SizedBox(
                          width: 95,
                          child: Text('Status', textAlign: TextAlign.center, style: _headerStyle),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text('Action', textAlign: TextAlign.center, style: _headerStyle),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Data Rows
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 36,
                            color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No outstanding items found matching your filters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildTableRow(item, isDark, selectedTab);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  Widget _buildTableRow(
    OutstandingItemDto item,
    bool isDark,
    String selectedTab,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to document detail
        if (selectedTab == 'Receivables') {
          context.push('/sales/${item.id}');
        } else {
          context.push('/purchase/${item.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // Ref Code + Copy
            SizedBox(
              width: 125,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.refNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.refNumber));
                      AppFeedback.showSnackbar(context, message: '${item.refNumber} copied!');
                    },
                    child: Icon(
                      Icons.copy,
                      size: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Date
            SizedBox(
              width: 95,
              child: Text(
                '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),

            // Due Date
            SizedBox(
              width: 95,
              child: Text(
                '${item.dueDate.day.toString().padLeft(2, '0')}/${item.dueDate.month.toString().padLeft(2, '0')}/${item.dueDate.year}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),

            // Party Name + Phone (if available)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.partyName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.partyMobile != null && item.partyMobile!.trim().isNotEmpty)
                    Text(
                      item.partyMobile!,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),

            // Bill Amount
            SizedBox(
              width: 105,
              child: Text(
                '₹${_formatCurrency(item.amount)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),

            // Balance Due
            SizedBox(
              width: 105,
              child: Text(
                '₹${_formatCurrency(item.balance)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),

            // Age
            SizedBox(
              width: 85,
              child: Center(
                child: Text(
                  '${item.ageDays} d',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ),

            // Status Badge
            SizedBox(
              width: 95,
              child: Center(
                child: _buildTimelineBadge(item.statusLabel, isDark),
              ),
            ),

            // Action Menu
            SizedBox(
              width: 45,
              child: Center(
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val == 'view') {
                      if (selectedTab == 'Receivables') {
                        context.push('/sales/${item.id}');
                      } else {
                        context.push('/purchase/${item.id}');
                      }
                    } else if (val == 'reminder') {
                      Share.share(
                        'Payment Reminder: ${item.refNumber}\nParty: ${item.partyName}\nBalance Due: ₹${_formatCurrency(item.balance)}\nDue Date: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                      );
                    } else if (val == 'pay') {
                      if (selectedTab == 'Receivables') {
                        context.push('/receipts/new');
                      } else {
                        context.push('/payments/new');
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedTab == 'Receivables' ? 'View Invoice' : 'View Bill',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reminder',
                      child: Row(
                        children: const [
                          Icon(Icons.send_outlined, size: 15, color: Color(0xFF15803D)),
                          SizedBox(width: 8),
                          Text('Share Reminder', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pay',
                      child: Row(
                        children: [
                          Icon(
                            selectedTab == 'Receivables' ? Icons.receipt_long : Icons.payment,
                            size: 15,
                            color: const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedTab == 'Receivables' ? 'Receive Payment' : 'Pay Supplier',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBadge(String status, bool isDark) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);

    final normalized = status.toUpperCase();
    if (normalized == 'OVERDUE') {
      bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    } else if (normalized == 'DUE TODAY') {
      bg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      text = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    } else {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
      text = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    String result;
    if (whole.length <= 3) {
      result = '$whole.$dec';
    } else {
      final lastThree = whole.substring(whole.length - 3);
      final otherNumbers = whole.substring(0, whole.length - 3);

      final formattedOther = otherNumbers.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

      result = '$formattedOther,$lastThree.$dec';
    }

    return isNegative ? '-$result' : result;
  }
}
