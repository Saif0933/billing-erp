import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class OutstandingPage extends ConsumerStatefulWidget {
  const OutstandingPage({super.key});

  @override
  ConsumerState<OutstandingPage> createState() => _OutstandingPageState();
}

class _OutstandingPageState extends ConsumerState<OutstandingPage> {
  String _selectedTab = 'Receivables'; // 'Receivables' vs 'Payables'
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'OVERDUE', 'DUE TODAY', 'PENDING'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.outstanding)) {
      return const LockedFeaturePage(featureName: 'Outstanding Analysis');
    }

    final billingState = ref.watch(billingRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Ageing bucket totals
    double bucket0To30 = 0.0;
    double bucket31To60 = 0.0;
    double bucket61To90 = 0.0;
    double bucket91Plus = 0.0;

    double totalOutstanding = 0.0;
    double dueToday = 0.0;
    double totalOverdue = 0.0;

    List<_OutstandingItem> outstandingList = [];

    if (_selectedTab == 'Receivables') {
      final activeInvoices = billingState.invoices.where(
        (inv) => inv.status != InvoiceStatus.paid && inv.status != InvoiceStatus.cancelled && !inv.isCreditNote,
      ).toList();

      for (var inv in activeInvoices) {
        final diffDays = now.difference(inv.invoiceDate).inDays;
        final customer = billingState.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == inv.customerId,
          orElse: () => null,
        );
        final creditDays = customer?.creditPeriod ?? 30;
        final dueDate = inv.invoiceDate.add(Duration(days: creditDays > 0 ? creditDays : 30));
        final isOverdue = now.isAfter(dueDate) && !(now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day);
        final isDueToday = now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;

        totalOutstanding += inv.balanceAmount;
        if (isDueToday) dueToday += inv.balanceAmount;
        if (isOverdue) totalOverdue += inv.balanceAmount;

        // Ageing sort
        if (diffDays <= 30) {
          bucket0To30 += inv.balanceAmount;
        } else if (diffDays <= 60) {
          bucket31To60 += inv.balanceAmount;
        } else if (diffDays <= 90) {
          bucket61To90 += inv.balanceAmount;
        } else {
          bucket91Plus += inv.balanceAmount;
        }

        outstandingList.add(
          _OutstandingItem(
            id: inv.id,
            refNumber: inv.invoiceNumber,
            date: inv.invoiceDate,
            dueDate: dueDate,
            partyName: inv.customerName,
            amount: inv.grandTotal,
            balance: inv.balanceAmount,
            ageDays: diffDays,
            statusLabel: isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING'),
          ),
        );
      }
    } else {
      // Payables
      final activePurchases = billingState.purchases.where(
        (p) => p.status != PurchaseStatus.paid && p.status != PurchaseStatus.cancelled && !p.isDebitNote,
      ).toList();

      for (var p in activePurchases) {
        final diffDays = now.difference(p.purchaseDate).inDays;
        final supplier = billingState.suppliers.cast<Supplier?>().firstWhere(
          (s) => s?.id == p.supplierId,
          orElse: () => null,
        );
        final creditDays = supplier?.creditTerms ?? 30;
        final dueDate = p.purchaseDate.add(Duration(days: creditDays > 0 ? creditDays : 30));
        final isOverdue = now.isAfter(dueDate) && !(now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day);
        final isDueToday = now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;

        totalOutstanding += p.balanceAmount;
        if (isDueToday) dueToday += p.balanceAmount;
        if (isOverdue) totalOverdue += p.balanceAmount;

        // Ageing sort
        if (diffDays <= 30) {
          bucket0To30 += p.balanceAmount;
        } else if (diffDays <= 60) {
          bucket31To60 += p.balanceAmount;
        } else if (diffDays <= 90) {
          bucket61To90 += p.balanceAmount;
        } else {
          bucket91Plus += p.balanceAmount;
        }

        outstandingList.add(
          _OutstandingItem(
            id: p.id,
            refNumber: p.purchaseNumber,
            date: p.purchaseDate,
            dueDate: dueDate,
            partyName: p.supplierName,
            amount: p.grandTotal,
            balance: p.balanceAmount,
            ageDays: diffDays,
            statusLabel: isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING'),
          ),
        );
      }
    }

    // Filter items based on search & status
    final filteredList = outstandingList.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.refNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.partyName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'All' || item.statusLabel == _selectedStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header
              _buildPageHeader(context, isDark),
              const SizedBox(height: 16),

              // Receivables vs Payables Pill Switcher (Horizontally scrollable to never overflow)
              _buildTabSelector(isDark),
              const SizedBox(height: 16),

              // 3 KPI Metric Cards (Overflow-proof with LayoutBuilder & flexible containers)
              _buildKpiSection(
                totalOutstanding: totalOutstanding,
                dueToday: dueToday,
                totalOverdue: totalOverdue,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Ageing Analysis Schedule (4 Buckets with Progress & zero overflow)
              _buildAgeingSection(
                totalOutstanding: totalOutstanding,
                b0To30: bucket0To30,
                b31To60: bucket31To60,
                b61To90: bucket61To90,
                b91Plus: bucket91Plus,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Search & Filter Toolbar
              _buildSearchFilterBar(isDark),
              const SizedBox(height: 12),

              // Itemized Outstanding Statement Table
              _buildOutstandingTable(filteredList, isDark),
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
        // Title + Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Outstanding Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
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

        // Record Payment / Receipt Quick Action Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 1,
          ),
          icon: Icon(
            _selectedTab == 'Receivables' ? Icons.receipt_long : Icons.payment,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            _selectedTab == 'Receivables' ? 'Record Receipt' : 'Record Payment',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            if (_selectedTab == 'Receivables') {
              context.push('/receipts/new');
            } else {
              context.push('/payments/new');
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return SingleChildScrollView(
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
              isSelected: _selectedTab == 'Receivables',
              onTap: () => setState(() => _selectedTab = 'Receivables'),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _buildTabOption(
              label: 'Payables (Suppliers)',
              icon: Icons.trending_down,
              isSelected: _selectedTab == 'Payables',
              onTap: () => setState(() => _selectedTab = 'Payables'),
              isDark: isDark,
            ),
          ],
        ),
      ),
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
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final cardWidth = isSmall
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 3;

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
                subtitle: _selectedTab == 'Receivables' ? 'Total Pending Invoices' : 'Total Pending Bills',
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

          // Value Row with FittedBox to prevent any vertical/horizontal overflow
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
    required bool isDark,
  }) {
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
          // Header: Ageing Analysis Schedule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ageing Analysis Schedule',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
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

          // 4 Bucket Cards (Flexible Grid with Wrap to never overflow)
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
                    child: _buildBucketCard('0 – 30 Days', b0To30, totalOutstanding, const Color(0xFF15803D), isDark),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard('31 – 60 Days', b31To60, totalOutstanding, const Color(0xFFD97706), isDark),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard('61 – 90 Days', b61To90, totalOutstanding, const Color(0xFFEA580C), isDark),
                  ),
                  SizedBox(
                    width: bucketWidth,
                    child: _buildBucketCard('90+ Days', b91Plus, totalOutstanding, const Color(0xFFDC2626), isDark),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBucketCard(String title, double amount, double total, Color color, bool isDark) {
    final ratio = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bucket Title & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
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

          // Amount with FittedBox
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
    );
  }

  Widget _buildSearchFilterBar(bool isDark) {
    return Row(
      children: [
        // Search Input
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
                hintText: _selectedTab == 'Receivables'
                    ? 'Search by Invoice #, Customer...'
                    : 'Search by Purchase #, Supplier...',
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
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
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
              value: _selectedStatusFilter,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Status')),
                DropdownMenuItem(value: 'OVERDUE', child: Text('Overdue')),
                DropdownMenuItem(value: 'DUE TODAY', child: Text('Due Today')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatusFilter = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingTable(List<_OutstandingItem> items, bool isDark) {
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
              width: 840,
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
                        SizedBox(width: 120, child: Text('Ref Code', style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Date', style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Due Date', style: _headerStyle)),
                        Expanded(child: Text('Party Name', style: _headerStyle)),
                        SizedBox(width: 105, child: Text('Bill Val (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 105, child: Text('Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 85, child: Text('Age', textAlign: TextAlign.center, style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                        SizedBox(width: 40, child: Text('Action', textAlign: TextAlign.center, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Data Rows
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      alignment: Alignment.center,
                      child: Text(
                        'No outstanding balances found matching your criteria.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
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
                        return _buildTableRow(item, isDark);
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

  Widget _buildTableRow(_OutstandingItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Ref Code
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Text(
                  item.refNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
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
              '${item.date.day}/${item.date.month}/${item.date.year}',
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
              '${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),

          // Party Name
          Expanded(
            child: Text(
              item.partyName,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
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
            width: 40,
            child: Center(
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val == 'reminder') {
                    Share.share(
                      'Payment Reminder: ${item.refNumber}\nParty: ${item.partyName}\nBalance Due: ₹${_formatCurrency(item.balance)}\nDue Date: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                    );
                  } else if (val == 'pay') {
                    if (_selectedTab == 'Receivables') {
                      context.push('/receipts/new');
                    } else {
                      context.push('/payments/new');
                    }
                  }
                },
                itemBuilder: (ctx) => [
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
                          _selectedTab == 'Receivables' ? Icons.receipt_long : Icons.payment,
                          size: 15,
                          color: const Color(0xFF0284C7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _selectedTab == 'Receivables' ? 'Receive Payment' : 'Pay Supplier',
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
    );
  }

  Widget _buildTimelineBadge(String status, bool isDark) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);

    if (status == 'OVERDUE') {
      bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    } else if (status == 'DUE TODAY') {
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

class _OutstandingItem {
  final String id;
  final String refNumber;
  final DateTime date;
  final DateTime dueDate;
  final String partyName;
  final double amount;
  final double balance;
  final int ageDays;
  final String statusLabel;

  const _OutstandingItem({
    required this.id,
    required this.refNumber,
    required this.date,
    required this.dueDate,
    required this.partyName,
    required this.amount,
    required this.balance,
    required this.ageDays,
    required this.statusLabel,
  });
}
