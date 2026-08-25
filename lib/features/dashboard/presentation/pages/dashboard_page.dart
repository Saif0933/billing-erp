import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/shortcut_manager.dart';
import '../../../../core/utils/global_search.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../providers/billing_repository.dart';
import '../../../../core/models/billing_models.dart';
import 'package:flutter/services.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _searchController = TextEditingController();
  final _searchRepo = SearchRepository();
  List<SearchResult> _searchResults = [];
  bool _showSearchOverlay = false;

  void _onSearch(String query) async {
    final billingState = ref.read(billingRepositoryProvider);
    final results = await _searchRepo.search(query, billingState);
    setState(() {
      _searchResults = results;
    });
  }

  void _toggleSearchOverlay() {
    setState(() {
      _showSearchOverlay = !_showSearchOverlay;
      if (!_showSearchOverlay) {
        _searchController.clear();
        _searchResults.clear();
      }
    });
  }

  void _navigateToModule(
    String path,
    SubscriptionFeature feature,
    String label,
  ) {
    final subscription = ref.read(subscriptionProvider);
    if (subscription.canAccess(feature)) {
      context.push(path);
    } else {
      context.push('/locked-feature', extra: {'featureName': label});
    }
  }

  Widget _buildBusinessHeader(BuildContext context, dynamic activeBiz) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5A3C), Color(0xFF073A26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A3C).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeBiz?.name ?? 'Tax Bunny Retail Store',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Type: ${activeBiz?.type ?? "Retail"} - GSTIN: ${activeBiz?.gstNumber ?? "27AADCA1234F1Z5"}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up, color: color.withOpacity(0.7), size: 16),
        ],
      ),
    );
  }

  Widget _buildValuationCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoriesRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _navigateToModule(
                  '/customers',
                  SubscriptionFeature.customers,
                  'Customers',
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Manage customers',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _navigateToModule(
                  '/suppliers',
                  SubscriptionFeature.suppliers,
                  'Suppliers',
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Manage suppliers',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _navigateToModule(
            '/reports',
            SubscriptionFeature.reports,
            'Reports',
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Business insights',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowYourBusinessBanner(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Grow Your Business',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use insights and reports to boost your profits',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: 12,
                        color: const Color(0xFF81C784),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 6,
                        height: 20,
                        color: const Color(0xFF66BB6A),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 6,
                        height: 32,
                        color: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 6,
                        height: 44,
                        color: const Color(0xFF43A047),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 6,
                        height: 56,
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionItem(
        label: 'Create Invoice',
        icon: Icons.receipt_long_outlined,
        feature: SubscriptionFeature.sales,
        path: '/sales/new',
      ),
      _QuickActionItem(
        label: 'Record Bill',
        icon: Icons.post_add_outlined,
        feature: SubscriptionFeature.purchase,
        path: '/purchase/new',
      ),
      _QuickActionItem(
        label: 'POS Terminal',
        icon: Icons.point_of_sale_outlined,
        feature: SubscriptionFeature.pos,
        path: '/pos',
      ),
      _QuickActionItem(
        label: 'Warehouses',
        icon: Icons.warehouse_outlined,
        feature: SubscriptionFeature.warehouse,
        path: '/settings/warehouses',
      ),
      _QuickActionItem(
        label: 'Customer',
        icon: Icons.arrow_downward_outlined,
        feature: SubscriptionFeature.payments,
        path: '/receipts/new',
      ),
      _QuickActionItem(
        label: 'Supplier',
        icon: Icons.arrow_upward_outlined,
        feature: SubscriptionFeature.payments,
        path: '/payments/new',
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.8,
          children: actions.map((act) {
            return InkWell(
              onTap: () => _navigateToModule(act.path, act.feature, act.label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F8F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        act.icon,
                        color: const Color(0xFF2E7D32),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        act.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _navigateToModule(
            '/reports',
            SubscriptionFeature.reports,
            'Reports',
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Reports',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsChart(BuildContext context, BillingState billing) {
    final salesTrend = [20000.0, 45000.0, 30000.0, 52000.0, 75000.0];
    final purchaseTrend = [15000.0, 22000.0, 18000.0, 35000.0, 40000.0];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales & Purchase\nTrend Analysis',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(
                      'This Year',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade100, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        if (value == 0)
                          return const Text(
                            '0',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        if (value == 15000)
                          return const Text(
                            '15K',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        if (value == 30000)
                          return const Text(
                            '30K',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        if (value == 45000)
                          return const Text(
                            '45K',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        if (value == 60000)
                          return const Text(
                            '60K',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        if (value == 75000)
                          return const Text(
                            '75K',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Apr', 'May', 'Jun', 'Jul', 'Aug'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      salesTrend.length,
                      (i) => FlSpot(i.toDouble(), salesTrend[i]),
                    ),
                    isCurved: true,
                    color: const Color(0xFF2E7D32),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      purchaseTrend.length,
                      (i) => FlSpot(i.toDouble(), purchaseTrend[i]),
                    ),
                    isCurved: true,
                    color: const Color(0xFFFF9800),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Sales (Dr)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 20),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Purchases (Cr)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '75K',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        'Highest Sales',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      Text(
                        'Aug 2026',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '40K',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      Text(
                        'Highest Purchase',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      Text(
                        'Aug 2026',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '35K',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Text(
                        'Avg. Monthly Sales',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      Text(
                        'This Year',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart_outlined,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track your growth',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monitor your business performance and make data-driven decisions.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTable(BuildContext context, BillingState billing) {
    final List<_Activity> list = [];
    for (var inv in billing.invoices) {
      list.add(
        _Activity(
          id: inv.invoiceNumber,
          type: inv.isCreditNote ? 'Credit Note' : 'Sales Invoice',
          party: inv.customerName,
          amount: '₹${inv.grandTotal.toStringAsFixed(2)}',
          status: inv.status.name.toUpperCase(),
          date: inv.invoiceDate,
        ),
      );
    }
    for (var p in billing.purchases) {
      list.add(
        _Activity(
          id: p.purchaseNumber,
          type: p.isDebitNote ? 'Debit Note' : 'Supplier Purchase',
          party: p.supplierName,
          amount: '₹${p.grandTotal.toStringAsFixed(2)}',
          status: p.status.name.toUpperCase(),
          date: p.purchaseDate,
        ),
      );
    }
    for (var r in billing.receipts) {
      list.add(
        _Activity(
          id: r.referenceNumber,
          type: 'Receipt Outward',
          party: r.customerName,
          amount: '₹${r.amount.toStringAsFixed(2)}',
          status: 'PAID',
          date: r.date,
        ),
      );
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    final displayList = list.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.isEmpty ? 1 : displayList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              if (displayList.isEmpty) {
                return const ListTile(
                  title: Text('No transaction history logged yet.'),
                );
              }
              final act = displayList[idx];
              final isSales =
                  act.type == 'Sales Invoice' || act.type == 'Receipt Outward';
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSales
                        ? const Color(0xFFF1F8F5)
                        : const Color(0xFFFFF8F1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSales ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isSales
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFFF9800),
                    size: 18,
                  ),
                ),
                title: Text(
                  act.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${act.type} • ${act.party}\n${act.date.day} Aug 2026 • 02:05 PM',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      act.amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      act.status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: act.status == 'PAID' || act.status == 'CONFIRMED'
                            ? const Color(0xFF2E7D32)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBiz = ref.watch(businessProvider).activeBusiness;
    final billingState = ref.watch(billingRepositoryProvider);

    final shortcuts = [
      AppShortcut(
        key: LogicalKeyboardKey.keyK,
        control: true,
        onTrigger: _toggleSearchOverlay,
        description: 'Global Search Overlay',
      ),
      AppShortcut(
        key: LogicalKeyboardKey.escape,
        onTrigger: () {
          if (_showSearchOverlay) {
            _toggleSearchOverlay();
          }
        },
        description: 'Close Search Overlay',
      ),
    ];

    final now = DateTime.now();

    final todaySales = billingState.invoices
        .where(
          (inv) =>
              inv.status == InvoiceStatus.confirmed &&
              inv.invoiceDate.day == now.day &&
              inv.invoiceDate.month == now.month &&
              inv.invoiceDate.year == now.year &&
              !inv.isCreditNote,
        )
        .fold<double>(0.0, (sum, inv) => sum + inv.grandTotal);

    final todayPurchases = billingState.purchases
        .where(
          (p) =>
              p.status == PurchaseStatus.confirmed &&
              p.purchaseDate.day == now.day &&
              p.purchaseDate.month == now.month &&
              p.purchaseDate.year == now.year &&
              !p.isDebitNote,
        )
        .fold<double>(0.0, (sum, p) => sum + p.grandTotal);

    final receivables = billingState.invoices
        .where(
          (inv) =>
              inv.status != InvoiceStatus.paid &&
              inv.status != InvoiceStatus.cancelled &&
              !inv.isCreditNote,
        )
        .fold<double>(0.0, (sum, inv) => sum + inv.balanceAmount);

    final payables = billingState.purchases
        .where(
          (p) =>
              p.status != PurchaseStatus.paid &&
              p.status != PurchaseStatus.cancelled &&
              !p.isDebitNote,
        )
        .fold<double>(0.0, (sum, p) => sum + p.balanceAmount);

    final totalReceipts = billingState.receipts.fold<double>(
      0.0,
      (sum, r) => sum + r.amount,
    );
    final totalPayments = billingState.payments.fold<double>(
      0.0,
      (sum, p) => sum + p.amount,
    );
    final totalExpenses = billingState.expenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final cashBalance =
        200000.0 + totalReceipts - totalPayments - totalExpenses;

    final stockValuation = billingState.products.fold<double>(
      0.0,
      (sum, p) => sum + (p.currentStock * p.purchasePrice),
    );
    final lowStockCount = billingState.products
        .where((p) => p.currentStock <= p.minStockLevel)
        .length;

    Widget dashboardContent = Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(
            Responsive.isMobile(context) ? AppSpacing.md : AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBusinessHeader(context, activeBiz),
              const SizedBox(height: 16),
              _buildMetricCard(
                context: context,
                title: "Today's Sales",
                value: "₹${todaySales.toStringAsFixed(2)}",
                subtitle: "Confirmed bills today",
                icon: Icons.trending_up,
                color: const Color(0xFF2E7D32),
              ),
              _buildMetricCard(
                context: context,
                title: "Today's Purchases",
                value: "₹${todayPurchases.toStringAsFixed(2)}",
                subtitle: "Confirmed supplier bills",
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF1976D2),
              ),
              _buildMetricCard(
                context: context,
                title: "Total Receivables",
                value: "₹${receivables.toStringAsFixed(2)}",
                subtitle: "Outstanding customer invoices",
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFFF9800),
              ),
              _buildMetricCard(
                context: context,
                title: "Total Payables",
                value: "₹${payables.toStringAsFixed(2)}",
                subtitle: "Outstanding vendor balances",
                icon: Icons.credit_card_outlined,
                color: const Color(0xFF9C27B0),
              ),
              const SizedBox(height: 6),
              _buildValuationCard(
                context: context,
                title: "Cash & Bank Balance",
                value: "₹${cashBalance.toStringAsFixed(2)}",
                subtitle: "Cloud synced assets",
                icon: Icons.account_balance,
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFF1F8F5),
                borderColor: const Color(0xFFE8F5E9),
                onTap: () {},
              ),
              _buildValuationCard(
                context: context,
                title: "Estimated Stock Value",
                value: "₹${stockValuation.toStringAsFixed(2)}",
                subtitle: "$lowStockCount items at low threshold",
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF673AB7),
                bgColor: const Color(0xFFF5F2F9),
                borderColor: const Color(0xFFEBE5F3),
                onTap: () => context.go('/inventory'),
              ),
              const SizedBox(height: 16),
              _buildDirectoriesRow(context),
              const SizedBox(height: 16),
              _buildGrowYourBusinessBanner(context),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildTrendsChart(context, billingState),
              const SizedBox(height: 20),
              _buildRecentActivityTable(context, billingState),
            ],
          ),
        ),
        if (_showSearchOverlay) _buildGlobalSearchOverlay(context),
      ],
    );

    return GlobalShortcutListener(
      shortcuts: shortcuts,
      child: Scaffold(body: dashboardContent),
    );
  }

  Widget _buildGlobalSearchOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleSearchOverlay,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppTextField(
                      label: 'Global Command Search',
                      hintText:
                          'Search customers, products, invoices... (Press ESC to close)',
                      controller: _searchController,
                      onChanged: _onSearch,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_searchResults.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _searchResults[idx];
                          return ListTile(
                            leading: Icon(
                              item.category == SearchCategory.customers
                                  ? Icons.person
                                  : item.category == SearchCategory.invoices
                                  ? Icons.receipt
                                  : Icons.category,
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(item.subtitle),
                            onTap: () {
                              _toggleSearchOverlay();
                              context.push(item.route);
                            },
                          );
                        },
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('No results matching query.'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final SubscriptionFeature feature;
  final String path;
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.feature,
    required this.path,
  });
}

class _Activity {
  final String id;
  final String type;
  final String party;
  final String amount;
  final String status;
  final DateTime date;
  const _Activity({
    required this.id,
    required this.type,
    required this.party,
    required this.amount,
    required this.status,
    required this.date,
  });
}
