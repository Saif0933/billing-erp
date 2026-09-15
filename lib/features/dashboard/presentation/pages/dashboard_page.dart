import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/billing_models.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../providers/billing_repository.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/dashboard_models.dart';

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
    final dashboardState = ref.watch(dashboardProvider);

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

          return RefreshIndicator(
            color: const Color(0xFF10B981),
            onRefresh: () => ref
                .read(dashboardProvider.notifier)
                .loadOverview(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  _buildKpiSection(contentWidth, billingState, dashboardState),

                  const SizedBox(height: 18),

                  // 3. Middle Section: Trend Chart + Cash & Bank + Inventory Summary
                  _buildMiddleSection(
                      contentWidth, billingState, dashboardState),

                  const SizedBox(height: 18),

                  // 4. Quick Actions Section
                  _buildQuickActions(contentWidth),

                  const SizedBox(height: 18),

                  // 5. Bottom Section: Recent Sales + Recent Purchases + Reminders & Insights
                  _buildBottomSection(
                      contentWidth, billingState, dashboardState),

                  const SizedBox(height: 24),
                ],
              ),
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

  Widget _buildKpiSection(
    double contentWidth,
    BillingState billingState,
    DashboardState dashboardState,
  ) {
    final liveMetrics = dashboardState.overview?.metrics;

    // Fully dynamic calculation from billingState if liveMetrics not yet loaded
    final salesTotal = billingState.invoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.grandTotal,
    );
    final salesCount = billingState.invoices.length;

    final purchaseTotal = billingState.purchases.fold<double>(
      0.0,
      (sum, p) => sum + p.grandTotal,
    );
    final purchaseCount = billingState.purchases.length;

    final unpaidInvoices = billingState.invoices
        .where((inv) =>
            inv.status != InvoiceStatus.paid &&
            inv.status != InvoiceStatus.cancelled &&
            inv.balanceAmount > 0)
        .toList();
    final receivablesTotal = unpaidInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.balanceAmount,
    );
    final receivablesCount = unpaidInvoices.length;

    final unpaidPurchases = billingState.purchases
        .where((p) =>
            p.status != PurchaseStatus.paid &&
            p.status != PurchaseStatus.cancelled &&
            p.balanceAmount > 0)
        .toList();
    final payablesTotal = unpaidPurchases.fold<double>(
      0.0,
      (sum, p) => sum + p.balanceAmount,
    );
    final payablesCount = unpaidPurchases.length;

    final cards = [
      liveMetrics != null
          ? _buildKpiCard(
              title: liveMetrics.todaysSales.title,
              value: liveMetrics.todaysSales.formattedValue,
              subtitle: liveMetrics.todaysSales.subtitle,
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF10B981),
              percentage: liveMetrics.todaysSales.percentage,
              isPositive: liveMetrics.todaysSales.isPositive,
            )
          : _buildKpiCard(
              title: "Today's Sales",
              value: '₹ ${_formatCurrency(salesTotal)}',
              subtitle:
                  '$salesCount ${salesCount == 1 ? "invoice" : "invoices"} today',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF10B981),
              percentage: salesTotal > 0 ? 'Active' : '0%',
              isPositive: true,
            ),
      liveMetrics != null
          ? _buildKpiCard(
              title: liveMetrics.todaysPurchases.title,
              value: liveMetrics.todaysPurchases.formattedValue,
              subtitle: liveMetrics.todaysPurchases.subtitle,
              icon: Icons.shopping_cart_outlined,
              iconColor: const Color(0xFF0EA5E9),
              percentage: liveMetrics.todaysPurchases.percentage,
              isPositive: liveMetrics.todaysPurchases.isPositive,
            )
          : _buildKpiCard(
              title: "Today's Purchases",
              value: '₹ ${_formatCurrency(purchaseTotal)}',
              subtitle:
                  '$purchaseCount ${purchaseCount == 1 ? "purchase bill" : "purchase bills"}',
              icon: Icons.shopping_cart_outlined,
              iconColor: const Color(0xFF0EA5E9),
              percentage: purchaseTotal > 0 ? 'Active' : '0%',
              isPositive: false,
            ),
      liveMetrics != null
          ? _buildKpiCard(
              title: liveMetrics.totalReceivables.title,
              value: liveMetrics.totalReceivables.formattedValue,
              subtitle: liveMetrics.totalReceivables.subtitle,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFFF59E0B),
              percentage: liveMetrics.totalReceivables.percentage,
              isPositive: liveMetrics.totalReceivables.isPositive,
            )
          : _buildKpiCard(
              title: 'Total Receivables',
              value: '₹ ${_formatCurrency(receivablesTotal)}',
              subtitle:
                  '$receivablesCount ${receivablesCount == 1 ? "invoice" : "invoices"} pending',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFFF59E0B),
              percentage: receivablesCount > 0 ? 'Pending' : '0%',
              isPositive: receivablesCount == 0,
            ),
      liveMetrics != null
          ? _buildKpiCard(
              title: liveMetrics.totalPayables.title,
              value: liveMetrics.totalPayables.formattedValue,
              subtitle: liveMetrics.totalPayables.subtitle,
              icon: Icons.credit_card_outlined,
              iconColor: const Color(0xFF8B5CF6),
              percentage: liveMetrics.totalPayables.percentage,
              isPositive: liveMetrics.totalPayables.isPositive,
            )
          : _buildKpiCard(
              title: 'Total Payables',
              value: '₹ ${_formatCurrency(payablesTotal)}',
              subtitle:
                  '$payablesCount ${payablesCount == 1 ? "bill" : "bills"} pending',
              icon: Icons.credit_card_outlined,
              iconColor: const Color(0xFF8B5CF6),
              percentage: payablesCount > 0 ? 'Due' : '0%',
              isPositive: payablesCount == 0,
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

  Widget _buildMiddleSection(
    double contentWidth,
    BillingState billingState,
    DashboardState dashboardState,
  ) {
    final trendWidget =
        _buildSalesPurchaseTrendCard(dashboardState.overview?.trend);
    final bankWidget = _buildCashAndBankCard(
        billingState, dashboardState.overview?.cashAndBank);
    final inventoryWidget =
        _buildInventorySummaryCard(dashboardState.overview?.inventory);

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

  Widget _buildSalesPurchaseTrendCard([DashboardTrendData? trendData]) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isNarrow = outerConstraints.maxWidth < 620;

        final labels = (trendData != null && trendData.labels.isNotEmpty)
            ? trendData.labels
            : const [
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

        final List<FlSpot> salesSpots = [];
        final List<FlSpot> purchasesSpots = [];

        if (trendData != null && trendData.sales.isNotEmpty) {
          for (int i = 0; i < trendData.sales.length; i++) {
            salesSpots.add(FlSpot(i.toDouble(), trendData.sales[i]));
          }
        } else {
          for (int i = 0; i < labels.length; i++) {
            salesSpots.add(FlSpot(i.toDouble(), 0));
          }
        }

        if (trendData != null && trendData.purchases.isNotEmpty) {
          for (int i = 0; i < trendData.purchases.length; i++) {
            purchasesSpots.add(FlSpot(i.toDouble(), trendData.purchases[i]));
          }
        } else {
          for (int i = 0; i < labels.length; i++) {
            purchasesSpots.add(FlSpot(i.toDouble(), 0));
          }
        }

        double highestY = 0.0;
        for (final s in salesSpots) {
          if (s.y > highestY) highestY = s.y;
        }
        for (final p in purchasesSpots) {
          if (p.y > highestY) highestY = p.y;
        }

        final double yInterval = _calculateNiceYInterval(highestY);
        final double rawMax = highestY <= 0
            ? (yInterval * 4.0)
            : ((highestY / yInterval).ceil() * yInterval).toDouble();
        final double chartMaxY =
            (highestY > 0 && (rawMax - highestY) < (yInterval * 0.15))
                ? rawMax + yInterval
                : (rawMax < yInterval * 2 ? yInterval * 2 : rawMax);
        final double chartMaxX =
            (labels.length > 1 ? (labels.length - 1).toDouble() : 11.0);

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
                        onSelected: (val) {
                          setState(() => _selectedTrendPeriod = val);
                          final periodKey = val == 'This Year'
                              ? 'this_year'
                              : val == 'This Quarter'
                                  ? 'this_quarter'
                                  : 'this_month';
                          ref
                              .read(dashboardProvider.notifier)
                              .changeTrendPeriod(periodKey);
                        },
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
                      horizontalInterval: yInterval,
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
                          interval: yInterval,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value > chartMaxY + 0.1) {
                              return const SizedBox();
                            }
                            final intVal = value.round();
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  intVal == 0 ? '0' : '${intVal}K',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                            final index = value.toInt();
                            if (index >= 0 && index < labels.length) {
                              if (outerConstraints.maxWidth < 460 &&
                                  index % 2 != 0) {
                                return const SizedBox();
                              }
                              return Text(
                                labels[index],
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
                    clipData: const FlClipData.all(),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => _isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF0F172A),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isSales = spot.barIndex == 0;
                            final label = isSales ? 'Sales' : 'Purchases';
                            final color = isSales
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B);
                            final amountInRupees = spot.y * 1000;
                            final formatted =
                                NumberFormat('#,##,##0.00', 'en_IN')
                                    .format(amountInRupees);
                            return LineTooltipItem(
                              '$label: ₹ $formatted',
                              TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    minX: 0,
                    maxX: chartMaxX,
                    minY: 0,
                    maxY: chartMaxY,
                    lineBarsData: [
                      // Sales Line (Green)
                      LineChartBarData(
                        spots: salesSpots,
                        isCurved: true,
                        curveSmoothness: 0.22,
                        preventCurveOverShooting: true,
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
                        spots: purchasesSpots,
                        isCurved: true,
                        curveSmoothness: 0.22,
                        preventCurveOverShooting: true,
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

  double _calculateNiceYInterval(double maxVal) {
    if (maxVal <= 10.0) return 5.0;
    const double targetSteps = 4.0;
    final double roughStep = maxVal / targetSteps;
    final double powerOf10 =
        math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
    final double ratio = roughStep / powerOf10;
    double niceRatio;
    if (ratio <= 1.25) {
      niceRatio = 1.0;
    } else if (ratio <= 2.5) {
      niceRatio = 2.0;
    } else if (ratio <= 6.0) {
      niceRatio = 5.0;
    } else {
      niceRatio = 10.0;
    }
    final double interval = niceRatio * powerOf10;
    return interval < 1.0 ? 1.0 : interval;
  }

  Color _parseHexColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _parseIcon(String? iconName, IconData fallback) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'payments':
        return Icons.payments_outlined;
      case 'calendar_month':
        return Icons.calendar_month_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in_outlined;
      case 'notifications':
      default:
        return fallback;
    }
  }

  Widget _buildCashAndBankCard(
    BillingState billingState, [
    DashboardCashBankSummary? cashAndBank,
  ]) {
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
            child: Text(
              cashAndBank?.formattedTotalBalance ?? '₹ 0.00',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bank Accounts List
          if (cashAndBank != null && cashAndBank.accounts.isNotEmpty) ...[
            for (int i = 0;
                i < cashAndBank.accounts.take(3).length;
                i++) ...[
              if (i > 0) Divider(color: _dividerColor, height: 16),
              _buildBankItem(
                name: cashAndBank.accounts[i].accountNumberMasked.isNotEmpty
                    ? '${cashAndBank.accounts[i].name} - ${cashAndBank.accounts[i].accountNumberMasked}'
                    : cashAndBank.accounts[i].name,
                amount: cashAndBank.accounts[i].formattedAmount,
                iconColor: _parseHexColor(
                  cashAndBank.accounts[i].iconColor,
                  const Color(0xFF10B981),
                ),
                icon: _parseIcon(
                  cashAndBank.accounts[i].icon,
                  Icons.account_balance,
                ),
                isSquare: cashAndBank.accounts[i].isSquare,
              ),
            ],
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 34,
                      color: _textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No bank accounts linked',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push('/accounting/bank-management'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '+ Link Account',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildInventorySummaryCard([DashboardInventorySummary? inventory]) {
    final int totalItems = inventory?.totalItems ?? 0;
    final int inStock = inventory?.inStockCount ?? 0;
    final int lowStock = inventory?.lowStockCount ?? 0;
    final int outOfStock = inventory?.outOfStockCount ?? 0;

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
                              sections: totalItems > 0
                                  ? [
                                      PieChartSectionData(
                                        value: inStock.toDouble(),
                                        color: const Color(0xFF10B981),
                                        radius: sectionRadius,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: lowStock.toDouble(),
                                        color: const Color(0xFFF59E0B),
                                        radius: sectionRadius,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: outOfStock.toDouble(),
                                        color: const Color(0xFFEF4444),
                                        radius: sectionRadius,
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      PieChartSectionData(
                                        value: 1,
                                        color: _isDark
                                            ? const Color(0xFF1E2E4A)
                                            : const Color(0xFFE2E8F0),
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
                                '$totalItems',
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
                            count: '$inStock',
                          ),
                          const SizedBox(height: 14),
                          _buildInventoryLegendItem(
                            color: const Color(0xFFF59E0B),
                            label: 'Low Stock',
                            count: '$lowStock',
                          ),
                          const SizedBox(height: 14),
                          _buildInventoryLegendItem(
                            color: const Color(0xFFEF4444),
                            label: 'Out of Stock',
                            count: '$outOfStock',
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

  Widget _buildBottomSection(
    double contentWidth,
    BillingState billingState,
    DashboardState dashboardState,
  ) {
    final recentSales = _buildRecentSalesCard(
      billingState,
      dashboardState.overview?.recentSales,
    );
    final recentPurchases = _buildRecentPurchasesCard(
      billingState,
      dashboardState.overview?.recentPurchases,
    );
    final remindersAndInsights = Column(
      children: [
        _buildUpcomingRemindersCard(dashboardState.overview?.reminders),
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
              Expanded(
                child: _buildUpcomingRemindersCard(
                    dashboardState.overview?.reminders),
              ),
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

  Widget _buildRecentSalesCard(
    BillingState billingState, [
    List<DashboardRecentSalesItem>? liveSales,
  ]) {
    final rows = (liveSales != null && liveSales.isNotEmpty)
        ? liveSales
            .map((s) => _TableRowData(
                  s.invoiceNumber,
                  s.date,
                  s.customerName,
                  s.formattedAmount,
                  s.status,
                  s.isPaid,
                ))
            .toList()
        : <_TableRowData>[];

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

          // Table Content or Empty State
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 34,
                      color: _textMuted.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent sales recorded',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/sales'),
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text(
                        'New Invoice',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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

  Widget _buildRecentPurchasesCard(
    BillingState billingState, [
    List<DashboardRecentPurchasesItem>? livePurchases,
  ]) {
    final rows = (livePurchases != null && livePurchases.isNotEmpty)
        ? livePurchases
            .map((p) => _TableRowData(
                  p.purchaseNumber,
                  p.date,
                  p.supplierName,
                  p.formattedAmount,
                  p.status,
                  p.isReceived,
                ))
            .toList()
        : <_TableRowData>[];

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

          // Table Content or Empty State
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 34,
                      color: _textMuted.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent purchases recorded',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/purchase'),
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text(
                        'Record Purchase',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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

  Widget _buildUpcomingRemindersCard([
    List<DashboardReminderItem>? liveReminders,
  ]) {
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
          if (liveReminders != null && liveReminders.isNotEmpty) ...[
            for (int i = 0; i < liveReminders.length; i++) ...[
              if (i > 0) Divider(color: _dividerColor, height: 16),
              _buildReminderItem(
                icon: _parseIcon(
                  liveReminders[i].icon,
                  Icons.notifications_active_outlined,
                ),
                iconColor: _parseHexColor(
                  liveReminders[i].iconColor,
                  const Color(0xFFF59E0B),
                ),
                title: liveReminders[i].title,
                subtitle: liveReminders[i].subtitle,
                route: liveReminders[i].route,
              ),
            ],
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 34,
                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No pending bills or due reminders',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
