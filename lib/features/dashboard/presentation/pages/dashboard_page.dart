import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../providers/billing_repository.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  String _selectedTrendPeriod = 'This Year';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF131D35) : Colors.white;
  Color get _cardBorder =>
      _isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight;
  Color get _textPrimary =>
      _isDark ? Colors.white : AppColors.textLightPrimary;
  Color get _textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color get _textMuted =>
      _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get _dividerColor =>
      _isDark ? const Color(0xFF1E2E4A) : const Color(0xFFF1F5F9);
  List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
      blurRadius: _isDark ? 12 : 8,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final activeBiz = businessState.activeBusiness;
    final billingState = ref.watch(billingRepositoryProvider);

    final bizName = activeBiz?.name ?? 'Tax Bunny Retail Store';

    return Scaffold(
      backgroundColor:
          _isDark ? const Color(0xFF0B132B) : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 960;
          final isTablet = width >= 600 && width < 960;
          final isMobile = width < 600;

          final double hPadding = isMobile ? 12 : (isTablet ? 16 : 24);
          final double contentWidth = width - (hPadding * 2);
          final double bannerWidth =
              isDesktop ? ((contentWidth - 16) * 0.7) : contentWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.all(hPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Banner Row: Greeting Banner + Live Clock Widget
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildGreetingBanner(bizName, bannerWidth),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _buildLiveClockCard()),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGreetingBanner(bizName, bannerWidth),
                      const SizedBox(height: 14),
                      _buildLiveClockCard(),
                    ],
                  ),

                const SizedBox(height: 18),

                // 2. Financial KPI Metric Cards (4 Cards)
                _buildKpiSection(contentWidth, billingState),

                const SizedBox(height: 18),

                // 3. Middle Section: Trend Chart + Cash & Bank + Inventory Summary
                _buildMiddleSection(contentWidth, billingState),

                const SizedBox(height: 18),

                // 4. Quick Actions Section
                _buildQuickActions(contentWidth),

                const SizedBox(height: 18),

                // 5. Bottom Section: Recent Sales + Recent Purchases + Reminders & Insights
                _buildBottomSection(contentWidth, billingState),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 1. GREETING BANNER & CLOCK
  // ==========================================

  Widget _buildGreetingBanner(String businessName, double bannerWidth) {
    final isCompact = bannerWidth < 600;
    final isNarrowScreen = bannerWidth < 420;

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [Color(0xFF0F382B), Color(0xFF0A261D)]
              : const [Color(0xFFE8FAF3), Color(0xFFC7F4E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: _isDark
            ? Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: _isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background soft lighting circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: _isDark ? 0.08 : 0.35),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrowScreen ? 16 : 24,
                vertical: isNarrowScreen ? 16 : 20,
              ),
              child: Row(
                children: [
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Good Morning,',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF064E3B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                businessName,
                                style: TextStyle(
                                  fontSize: isCompact ? 19 : 24,
                                  fontWeight: FontWeight.w900,
                                  color: _isDark
                                      ? Colors.white
                                      : const Color(0xFF064E3B),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '👋',
                              style: TextStyle(fontSize: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your business smarter, faster and easier.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _isDark
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFF047857),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Feature Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildFeaturePill(
                              Icons.description_outlined,
                              'Billing',
                              '/sales',
                            ),
                            _buildFeaturePill(
                              Icons.inventory_2_outlined,
                              'Inventory',
                              '/inventory',
                            ),
                            _buildFeaturePill(
                              Icons.people_outline,
                              'Customers',
                              '/customers',
                            ),
                            _buildFeaturePill(
                              Icons.bar_chart_outlined,
                              'Reports',
                              '/reports',
                            ),
                            _buildFeaturePill(
                              Icons.verified_user_outlined,
                              'GST Compliant',
                              '/gst',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Storefront 3D Graphic
                  if (!isCompact) ...[
                    const SizedBox(width: 16),
                    _buildStorefrontIllustration(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, String route) {
    final pillTextColor =
        _isDark ? Colors.white : const Color(0xFF064E3B);
    final pillIconColor =
        _isDark ? const Color(0xFF6EE7B7) : const Color(0xFF064E3B);
    final pillBg = _isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF064E3B).withValues(alpha: 0.08);
    final pillBorder = _isDark
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xFF064E3B).withValues(alpha: 0.15);

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pillBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: pillIconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pillTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorefrontIllustration() {
    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft shadow
          Positioned(
            bottom: 4,
            child: Container(
              width: 170,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Store Building Base
          Positioned(
            bottom: 12,
            child: Container(
              width: 130,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Store Door
                  Positioned(
                    left: 20,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6EE7B7).withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 3,
                          height: 8,
                          margin: const EdgeInsets.only(right: 3),
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ),

                  // Store Window
                  Positioned(
                    right: 18,
                    bottom: 12,
                    child: Container(
                      width: 46,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Green Striped Awning
          Positioned(
            top: 24,
            child: Container(
              width: 146,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: List.generate(
                    7,
                    (i) => Expanded(
                      child: Container(
                        color: i.isEven
                            ? const Color(0xFF00C853)
                            : const Color(0xFF69F0AE),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Billboard "GROW BILL REPEAT"
          Positioned(
            right: 0,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GROW',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'BILL',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6EE7B7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'REPEAT',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left Cute Potted Tree
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              width: 18,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Right Cute Potted Tree
          Positioned(
            right: 28,
            bottom: 10,
            child: Container(
              width: 14,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClockCard() {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final dateStr = dateFormat.format(_currentTime);
    final timeStr = timeFormat.format(_currentTime).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date Row
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Bold Live Digital Clock
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Productive Day Greeting & Mini Chart Graphic
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 15,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Have a productive day!',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Mini Translucent Green Bar Chart Graphic
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMiniBar(10, 0.3),
                  const SizedBox(width: 3),
                  _buildMiniBar(16, 0.5),
                  const SizedBox(width: 3),
                  _buildMiniBar(22, 0.75),
                  const SizedBox(width: 3),
                  _buildMiniBar(30, 1.0),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(double height, double opacity) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==========================================
  // 2. FINANCIAL KPI CARDS
  // ==========================================

  Widget _buildKpiSection(double contentWidth, BillingState billingState) {
    // Dynamic values with graceful fallbacks matching the exact design
    final salesTotal = billingState.invoices.isNotEmpty
        ? billingState.invoices.fold<double>(
            0.0,
            (sum, inv) => sum + inv.grandTotal,
          )
        : 12450.00;
    final salesCount = billingState.invoices.isNotEmpty
        ? billingState.invoices.length
        : 24;

    final purchaseTotal = billingState.purchases.isNotEmpty
        ? billingState.purchases.fold<double>(
            0.0,
            (sum, p) => sum + p.grandTotal,
          )
        : 8320.00;
    final purchaseCount = billingState.purchases.isNotEmpty
        ? billingState.purchases.length
        : 6;

    final receivablesTotal = 95430.00;
    final payablesTotal = 40620.00;

    final cards = [
      _buildKpiCard(
        title: "Today's Sales",
        value: '₹ ${_formatCurrency(salesTotal)}',
        subtitle: '$salesCount invoices today',
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF10B981),
        percentage: '12%',
        isPositive: true,
      ),
      _buildKpiCard(
        title: "Today's Purchases",
        value: '₹ ${_formatCurrency(purchaseTotal)}',
        subtitle: '$purchaseCount purchase bills',
        icon: Icons.shopping_cart_outlined,
        iconColor: const Color(0xFF0EA5E9),
        percentage: '5%',
        isPositive: false,
      ),
      _buildKpiCard(
        title: 'Total Receivables',
        value: '₹ ${_formatCurrency(receivablesTotal)}',
        subtitle: '18 outstanding',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFFF59E0B),
        percentage: '8%',
        isPositive: true,
      ),
      _buildKpiCard(
        title: 'Total Payables',
        value: '₹ ${_formatCurrency(payablesTotal)}',
        subtitle: '12 outstanding',
        icon: Icons.credit_card_outlined,
        iconColor: const Color(0xFF8B5CF6),
        percentage: '3%',
        isPositive: false,
      ),
    ];

    if (contentWidth >= 1100) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    }

    if (contentWidth >= 640) {
      final itemW = (contentWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((c) => SizedBox(width: itemW, child: c))
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: c,
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String percentage,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: _isDark ? 0.14 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Percentage Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  (isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 2),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. MIDDLE SECTION (TREND CHART + CASH & BANK + INVENTORY)
  // ==========================================

  Widget _buildMiddleSection(double contentWidth, BillingState billingState) {
    final trendWidget = _buildSalesPurchaseTrendCard();
    final bankWidget = _buildCashAndBankCard(billingState);
    final inventoryWidget = _buildInventorySummaryCard();

    if (contentWidth >= 1200) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: trendWidget),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: bankWidget),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: inventoryWidget),
        ],
      );
    }

    if (contentWidth >= 768) {
      return Column(
        children: [
          trendWidget,
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: bankWidget),
              const SizedBox(width: 16),
              Expanded(child: inventoryWidget),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        trendWidget,
        const SizedBox(height: 16),
        bankWidget,
        const SizedBox(height: 16),
        inventoryWidget,
      ],
    );
  }

  Widget _buildSalesPurchaseTrendCard() {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isNarrow = outerConstraints.maxWidth < 620;
        return Container(
          height: isNarrow ? 375 : 330,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            boxShadow: _cardShadow,
          ),
          child: Column(
            children: [
              // Header with responsive layout
              Builder(
                builder: (context) {
                  final headerTitle = Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sales & Purchase Trend',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  );

                  final legendAndFilter = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: isNarrow
                        ? WrapAlignment.spaceBetween
                        : WrapAlignment.start,
                    children: [
                      // Legend: Sales
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sales (₹)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Legend: Purchases
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Purchases (₹)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Dropdown pill
                      PopupMenuButton<String>(
                        onSelected: (val) =>
                            setState(() => _selectedTrendPeriod = val),
                        color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: _cardBorder),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: _textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedTrendPeriod,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: _textMuted,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'This Year',
                            child: Text(
                              'This Year',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'This Quarter',
                            child: Text(
                              'This Quarter',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'This Month',
                            child: Text(
                              'This Month',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerTitle,
                        const SizedBox(height: 10),
                        legendAndFilter,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [headerTitle, legendAndFilter],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Dual Line Spline Chart
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 15,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: _isDark
                              ? const Color(0xFF1E2E4A).withValues(alpha: 0.6)
                              : AppColors.borderLight,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
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
                          interval: 15,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            const yLabels = {
                              0: '0',
                              15: '15K',
                              30: '30K',
                              45: '45K',
                              60: '60K',
                              75: '75K',
                            };
                            final text = yLabels[value.toInt()] ?? '';
                            return Text(
                              text,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: outerConstraints.maxWidth < 460 ? 2 : 1,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            final index = value.toInt();
                            if (index >= 0 && index < months.length) {
                              if (outerConstraints.maxWidth < 460 && index % 2 != 0) {
                                return const SizedBox();
                              }
                              return Text(
                                months[index],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 11,
                    minY: 0,
                    maxY: 75,
                    lineBarsData: [
                      // Sales Line (Green)
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 12),
                          FlSpot(1, 26),
                          FlSpot(2, 34),
                          FlSpot(3, 31),
                          FlSpot(4, 42),
                          FlSpot(5, 54),
                          FlSpot(6, 46),
                          FlSpot(7, 43),
                          FlSpot(8, 52),
                          FlSpot(9, 61),
                          FlSpot(10, 68),
                          FlSpot(11, 75),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF10B981),
                        barWidth: 2.8,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFF10B981),
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.22),
                              const Color(0xFF10B981).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Purchases Line (Orange/Yellow)
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 5),
                          FlSpot(1, 14),
                          FlSpot(2, 17),
                          FlSpot(3, 13),
                          FlSpot(4, 21),
                          FlSpot(5, 29),
                          FlSpot(6, 19),
                          FlSpot(7, 16),
                          FlSpot(8, 23),
                          FlSpot(9, 32),
                          FlSpot(10, 34),
                          FlSpot(11, 38),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFFF59E0B),
                        barWidth: 2.6,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFFF59E0B),
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withValues(alpha: 0.16),
                              const Color(0xFFF59E0B).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashAndBankCard(BillingState billingState) {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cash & Bank Balance',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/accounting/bank-management'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Balance Big Typography
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text(
              '₹ 1,73,500.00',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bank Accounts List
          _buildBankItem(
            name: 'HDFC Bank - 1234',
            amount: '₹ 1,20,000.00',
            iconColor: const Color(0xFFEF4444),
            icon: Icons.account_balance,
            isSquare: true,
          ),
          Divider(color: _dividerColor, height: 16),
          _buildBankItem(
            name: 'SBI - 5678',
            amount: '₹ 45,300.00',
            iconColor: const Color(0xFF2563EB),
            icon: Icons.account_balance,
            isSquare: false,
          ),
          Divider(color: _dividerColor, height: 16),
          _buildBankItem(
            name: 'Cash in Hand',
            amount: '₹ 8,200.00',
            iconColor: const Color(0xFF10B981),
            icon: Icons.payments_outlined,
            isSquare: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBankItem({
    required String name,
    required String amount,
    required Color iconColor,
    required IconData icon,
    required bool isSquare,
  }) {
    return InkWell(
      onTap: () => context.push('/accounting/bank-management'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(isSquare ? 6 : 15),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummaryCard() {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Inventory Summary',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/inventory'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart + Legend Row
          Expanded(
            child: LayoutBuilder(
              builder: (context, invConstraints) {
                final isCompact = invConstraints.maxWidth < 320;
                final centerRadius = isCompact ? 36.0 : 46.0;
                final sectionRadius = isCompact ? 14.0 : 18.0;

                return Row(
                  children: [
                    // Donut PieChart with center text
                    Expanded(
                      flex: 5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: centerRadius,
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  value: 186,
                                  color: const Color(0xFF10B981),
                                  radius: sectionRadius,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 42,
                                  color: const Color(0xFFF59E0B),
                                  radius: sectionRadius,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 20,
                                  color: const Color(0xFFEF4444),
                                  radius: sectionRadius,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '248',
                                style: TextStyle(
                                  fontSize: isCompact ? 18 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              Text(
                                'Total Items',
                                style: TextStyle(
                                  fontSize: isCompact ? 9 : 10,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Legend
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInventoryLegendItem(
                            color: const Color(0xFF10B981),
                            label: 'In Stock',
                            count: '186',
                          ),
                          const SizedBox(height: 14),
                          _buildInventoryLegendItem(
                            color: const Color(0xFFF59E0B),
                            label: 'Low Stock',
                            count: '42',
                          ),
                          const SizedBox(height: 14),
                          _buildInventoryLegendItem(
                            color: const Color(0xFFEF4444),
                            label: 'Out of Stock',
                            count: '20',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryLegendItem({
    required Color color,
    required String label,
    required String count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4.5, backgroundColor: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, color: _textSecondary),
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. QUICK ACTIONS SECTION
  // ==========================================

  Widget _buildQuickActions(double contentWidth) {
    final actions = [
      _ActionItem(
        title: 'Create Invoice',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF10B981),
        route: '/sales/new',
      ),
      _ActionItem(
        title: 'Record Purchase',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF0EA5E9),
        route: '/purchase/new',
      ),
      _ActionItem(
        title: 'POS Terminal',
        icon: Icons.point_of_sale_outlined,
        color: const Color(0xFF8B5CF6),
        route: '/pos',
      ),
      _ActionItem(
        title: 'Add Customer',
        icon: Icons.person_add_outlined,
        color: const Color(0xFFF59E0B),
        route: '/customers/new',
      ),
      _ActionItem(
        title: 'Add Product',
        icon: Icons.view_in_ar_outlined,
        color: const Color(0xFF06B6D4),
        route: '/products/new',
      ),
      _ActionItem(
        title: 'Record Expense',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFF43F5E),
        route: '/expenses',
      ),
      _ActionItem(
        title: 'View Reports',
        icon: Icons.bar_chart_outlined,
        color: const Color(0xFF6366F1),
        route: '/reports',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with lightning icon
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action Buttons Row or Wrap
        if (contentWidth >= 1100)
          Row(
            children: actions
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _buildActionButton(item),
                    ),
                  ),
                )
                .toList(),
          )
        else
          Builder(
            builder: (context) {
              final int cols =
                  contentWidth >= 750 ? 4 : (contentWidth >= 480 ? 3 : 2);
              final double spacing = 10.0;
              final double itemWidth =
                  (contentWidth - (cols - 1) * spacing - 0.5) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: actions
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _buildActionButton(item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButton(_ActionItem item) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: _isDark ? 0.08 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.color.withValues(alpha: _isDark ? 0.22 : 0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF1E293B),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. BOTTOM SECTION (TABLES + REMINDERS & INSIGHTS)
  // ==========================================

  Widget _buildBottomSection(double contentWidth, BillingState billingState) {
    final recentSales = _buildRecentSalesCard(billingState);
    final recentPurchases = _buildRecentPurchasesCard(billingState);
    final remindersAndInsights = Column(
      children: [
        _buildUpcomingRemindersCard(),
        const SizedBox(height: 16),
        _buildInsightsPromoCard(),
      ],
    );

    if (contentWidth >= 1250) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: recentSales),
          const SizedBox(width: 16),
          Expanded(flex: 7, child: recentPurchases),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: remindersAndInsights),
        ],
      );
    }

    if (contentWidth >= 768) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: recentSales),
              const SizedBox(width: 16),
              Expanded(child: recentPurchases),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildUpcomingRemindersCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildInsightsPromoCard()),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        recentSales,
        const SizedBox(height: 16),
        recentPurchases,
        const SizedBox(height: 16),
        remindersAndInsights,
      ],
    );
  }

  Widget _buildRecentSalesCard(BillingState billingState) {
    final rows = [
      _TableRowData(
        'INV-000123',
        '05 Sep 2026',
        'Walk-in Customer',
        '₹ 1,250.00',
        'Paid',
        true,
      ),
      _TableRowData(
        'INV-000122',
        '05 Sep 2026',
        'Rahul Sharma',
        '₹ 2,480.00',
        'Paid',
        true,
      ),
      _TableRowData(
        'INV-000121',
        '04 Sep 2026',
        'Acme Corporates',
        '₹ 6,320.00',
        'Pending',
        false,
      ),
      _TableRowData(
        'INV-000120',
        '04 Sep 2026',
        'Walk-in Customer',
        '₹ 890.00',
        'Paid',
        true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Recent Sales',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/sales'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Content with LayoutBuilder for responsiveness
          LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = 440.0;
              final content = Column(
                children: [
                  _buildTableHeader([
                    '#',
                    'Date',
                    'Customer',
                    'Amount',
                    'Status',
                  ]),
                  Divider(color: _dividerColor, height: 16),
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: _buildTableRow(row),
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < minWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: minWidth, child: content),
                );
              }
              return content;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchasesCard(BillingState billingState) {
    final rows = [
      _TableRowData(
        'PUR-000045',
        '05 Sep 2026',
        'Metro Distributors',
        '₹ 4,500.00',
        'Received',
        true,
      ),
      _TableRowData(
        'PUR-000044',
        '04 Sep 2026',
        'Shree Traders',
        '₹ 2,850.00',
        'Received',
        true,
      ),
      _TableRowData(
        'PUR-000043',
        '03 Sep 2026',
        'Global Supplies',
        '₹ 1,980.00',
        'Pending',
        false,
      ),
      _TableRowData(
        'PUR-000042',
        '01 Sep 2026',
        'RK Enterprises',
        '₹ 3,200.00',
        'Received',
        true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Recent Purchases',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/purchase'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Content with LayoutBuilder for responsiveness
          LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = 440.0;
              final content = Column(
                children: [
                  _buildTableHeader([
                    '#',
                    'Date',
                    'Supplier',
                    'Amount',
                    'Status',
                  ]),
                  Divider(color: _dividerColor, height: 16),
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: _buildTableRow(row),
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < minWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: minWidth, child: content),
                );
              }
              return content;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> titles) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            titles[0],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            titles[1],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            titles[2],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            titles[3],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              titles[4],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(_TableRowData row) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            row.id,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            row.date,
            style: TextStyle(fontSize: 11.5, color: _textMuted),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            row.name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            row.amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color:
                    (row.isPaid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                row.status,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: row.isPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingRemindersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Upcoming Reminders',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/outstanding'),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items
          _buildReminderItem(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFFF97316),
            title: '3 Purchase Bills due',
            subtitle: 'Due within 7 days',
            route: '/purchase',
          ),
          Divider(color: _dividerColor, height: 16),
          _buildReminderItem(
            icon: Icons.credit_card_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: '5 Customer Payments',
            subtitle: 'Awaiting payment',
            route: '/outstanding',
          ),
          Divider(color: _dividerColor, height: 16),
          _buildReminderItem(
            icon: Icons.assignment_turned_in_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'GST Return',
            subtitle: 'Due on 20 Sep 2026',
            route: '/gst',
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsPromoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [Color(0xFF0F382B), Color(0xFF09251C)]
              : const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: _isDark ? 0.35 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: _isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981)
                            .withValues(alpha: _isDark ? 0.2 : 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Grow Your Business with Insights',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF064E3B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Use detailed reports to make smarter decisions.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDark
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFF047857),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push('/reports'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981)
                          .withValues(alpha: _isDark ? 0.15 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Reports',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _isDark
                                ? Colors.white
                                : const Color(0xFF064E3B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF064E3B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3D Stylized Ascending Bar Graphic
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _build3dBar(16, 0.4),
                    _build3dBar(26, 0.6),
                    _build3dBar(38, 0.8),
                    _build3dBar(52, 1.0),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 4,
                  child: Icon(
                    Icons.trending_up,
                    size: 20,
                    color: const Color(0xFF10B981).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3dBar(double height, double opacity) {
    return Container(
      width: 9,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(amount);
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _TableRowData {
  final String id;
  final String date;
  final String name;
  final String amount;
  final String status;
  final bool isPaid;

  _TableRowData(
    this.id,
    this.date,
    this.name,
    this.amount,
    this.status,
    this.isPaid,
  );
}
