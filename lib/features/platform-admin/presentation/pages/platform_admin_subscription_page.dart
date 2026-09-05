import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/platform_admin_models.dart';
import '../providers/platform_admin_provider.dart';
import '../widgets/platform_plan_card.dart';
import '../widgets/platform_plan_modal.dart';

class PlatformAdminSubscriptionPage extends ConsumerStatefulWidget {
  const PlatformAdminSubscriptionPage({super.key});

  @override
  ConsumerState<PlatformAdminSubscriptionPage> createState() =>
      _PlatformAdminSubscriptionPageState();
}

class _PlatformAdminSubscriptionPageState
    extends ConsumerState<PlatformAdminSubscriptionPage> {
  bool _isAnnualBilling = false;
  String _searchQuery = '';
  String _filterTag = 'All'; // 'All', 'Popular', 'With Tenants'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter plans
    final filteredPlans = state.plans.where((p) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.tagline.toLowerCase().contains(q) ||
          p.features.any((f) => f.toLowerCase().contains(q));

      if (!matchesSearch) return false;

      if (_filterTag == 'Popular') {
        return p.isPopular;
      } else if (_filterTag == 'With Tenants') {
        return p.activeTenantsCount > 0;
      }
      return true;
    }).toList();

    // Financial Metrics Calculation
    final totalMrr = state.plans.fold<double>(
      0.0,
      (sum, p) => sum + (p.priceMonthly * p.activeTenantsCount),
    );
    final totalArr = totalMrr * 12;
    final totalTenants = state.plans.fold<int>(
      0,
      (sum, p) => sum + p.activeTenantsCount,
    );
    final avgArpu = totalTenants > 0 ? (totalMrr / totalTenants) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header & Quick Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 750;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_outlined,
                                size: 13, color: Color(0xFF4F46E5)),
                            SizedBox(width: 5),
                            Text(
                              'SAAS PRICING ENGINE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscription & Pricing Tiers',
                    style: TextStyle(
                      fontSize: isSmall ? 20 : 25,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure recurring monetization tiers, quota limits, billing intervals, and feature capabilities.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );

              final actionSection = Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Monthly / Annual View Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIntervalPill(
                          label: 'Monthly',
                          isSelected: !_isAnnualBilling,
                          onTap: () => setState(() => _isAnnualBilling = false),
                          isDark: isDark,
                        ),
                        _buildIntervalPill(
                          label: 'Annual',
                          badge: 'Save 20%',
                          isSelected: _isAnnualBilling,
                          onTap: () => setState(() => _isAnnualBilling = true),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Refresh Button
                  IconButton(
                    tooltip: 'Refresh Plans',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () {
                      notifier.loadPlans();
                      AppFeedback.showSnackbar(
                        context,
                        message: 'Refreshing subscription plans from server...',
                      );
                    },
                  ),

                  // Add Plan Tier CTA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_outline,
                        size: 17, color: Colors.white),
                    label: const Text(
                      'Add Plan Tier',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => PlatformPlanModal.show(context),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 16),
                    actionSection,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 16),
                  actionSection,
                ],
              );
            },
          ),
          const SizedBox(height: 22),

          // 2. SaaS Financial Intelligence KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              int cols;
              if (w < 600) {
                cols = 2;
              } else if (w < 1000) {
                cols = 2;
              } else {
                cols = 4;
              }

              final kpiCards = [
                _buildKpiCard(
                  title: 'MONTHLY REVENUE (MRR)',
                  value: '₹ ${_formatCurrency(totalMrr)}',
                  subtitle: '${state.plans.length} active plans',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
                _buildKpiCard(
                  title: 'ANNUAL RUN RATE (ARR)',
                  value: '₹ ${_formatCurrency(totalArr)}',
                  subtitle: 'Projected annualized',
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF16A34A),
                  isDark: isDark,
                ),
                _buildKpiCard(
                  title: 'SUBSCRIBED TENANTS',
                  value: '$totalTenants',
                  subtitle: 'Active paying organizations',
                  icon: Icons.corporate_fare_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
                _buildKpiCard(
                  title: 'AVG. REVENUE / TENANT',
                  value: '₹ ${_formatCurrency(avgArpu)}',
                  subtitle: 'Blended ARPU / month',
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFFD97706),
                  isDark: isDark,
                ),
              ];

              if (cols == 4) {
                return Row(
                  children: kpiCards
                      .map((card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: card,
                            ),
                          ))
                      .toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kpiCards.map((card) {
                  final cardWidth = (w - 12) / 2;
                  return SizedBox(width: cardWidth, child: card);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 22),

          // 3. Recurring Revenue Breakdown Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RECURRING REVENUE BY TIER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ₹ ${_formatCurrency(totalMrr)} / mo',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Multi-Segment Visual Revenue Share Bar
                if (totalMrr > 0 && state.plans.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: state.plans.map((p) {
                          final tierMrr = p.priceMonthly * p.activeTenantsCount;
                          final fraction = (tierMrr / totalMrr).clamp(0.01, 1.0);
                          return Flexible(
                            flex: (fraction * 1000).toInt(),
                            child: Tooltip(
                              message:
                                  '${p.name}: ${(fraction * 100).toStringAsFixed(1)}% (₹ ${_formatCurrency(tierMrr)}/mo)',
                              child: Container(color: p.themeColor),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Responsive Tier Revenue Cards
                if (state.plans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No subscription plans configured yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final isNarrow = w < 700;

                      final tierCards = state.plans.map((p) {
                        final tierMrr = p.priceMonthly * p.activeTenantsCount;
                        final share = totalMrr > 0
                            ? ((tierMrr / totalMrr) * 100).toStringAsFixed(1)
                            : '0.0';
                        return _buildTierRevenueCard(
                          plan: p,
                          mrr: '₹ ${_formatCurrency(tierMrr)} / mo',
                          share: '$share% of MRR',
                          isDark: isDark,
                        );
                      }).toList();

                      if (isNarrow) {
                        return Column(
                          children: tierCards
                              .map((card) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: card,
                                  ))
                              .toList(),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: tierCards.map((card) {
                          final cardWidth =
                              (w - (state.plans.length > 2 ? 24 : 12)) /
                                  (state.plans.length > 2 ? 3 : 2);
                          return SizedBox(width: cardWidth, child: card);
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // 4. Filter & Search Toolbar
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;

              final searchField = Container(
                width: isSmall ? double.infinity : 280,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search plans by name, feature...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );

              final filterChips = Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'All (${state.plans.length})',
                    isSelected: _filterTag == 'All',
                    onTap: () => setState(() => _filterTag = 'All'),
                    isDark: isDark,
                  ),
                  _buildFilterChip(
                    label: 'Popular Only',
                    isSelected: _filterTag == 'Popular',
                    onTap: () => setState(() => _filterTag = 'Popular'),
                    isDark: isDark,
                  ),
                  _buildFilterChip(
                    label: 'Active Tenants',
                    isSelected: _filterTag == 'With Tenants',
                    onTap: () => setState(() => _filterTag = 'With Tenants'),
                    isDark: isDark,
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    filterChips,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  filterChips,
                  searchField,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 5. Responsive Pricing Tiers Grid
          if (filteredPlans.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 42,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _filterTag != 'All'
                        ? 'No Matching Subscription Plans'
                        : 'No Subscription Plans Configured',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty || _filterTag != 'All'
                        ? 'Try modifying your search or filter tags to discover other tiers.'
                        : 'Create your first subscription tier to define pricing, quotas, and capabilities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_searchQuery.isEmpty && _filterTag == 'All')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Create Plan Tier',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => PlatformPlanModal.show(context),
                    )
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text('Reset Filters'),
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _filterTag = 'All';
                      }),
                    ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                int cols;
                if (w < 680) {
                  cols = 1;
                } else if (w < 1150) {
                  cols = 2;
                } else if (w < 1600) {
                  cols = 3;
                } else {
                  cols = 4;
                }

                final double spacing = 16.0;
                final double cardWidth = (w - (cols - 1) * spacing) / cols;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: filteredPlans.map((plan) {
                    return SizedBox(
                      width: cardWidth,
                      child: PlatformPlanCard(
                        plan: plan,
                        isAnnualView: _isAnnualBilling,
                        onEdit: () =>
                            PlatformPlanModal.show(context, plan: plan),
                        onDelete: () => _confirmDeletePlan(context, ref, plan),
                        onViewSubscribers: () {
                          notifier.setPlanFilter(plan.name);
                          notifier.setNavTab('organizations');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Helper Widgets & Methods ---

  Widget _buildIntervalPill({
    required String label,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRevenueCard({
    required PlatformPlan plan,
    required String mrr,
    required String share,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: plan.themeColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.themeColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: plan.themeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${plan.name} Tier',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: plan.themeColor,
                      ),
                    ),
                    Text(
                      '${plan.activeTenantsCount} Tenants',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mrr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      share,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      final intPart = amount.toInt();
      final str = intPart.toString();
      // Indian comma format for thousands
      if (str.length > 3) {
        final lastThree = str.substring(str.length - 3);
        final otherNumbers = str.substring(0, str.length - 3);
        final formattedOther = otherNumbers.replaceAllMapped(
          RegExp(r'(\d)(?=(\d\d)+$)'),
          (m) => '${m[1]},',
        );
        return '$formattedOther,$lastThree';
      }
      return str;
    }
    return amount.toStringAsFixed(0);
  }

  void _confirmDeletePlan(
      BuildContext context, WidgetRef ref, PlatformPlan plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Plan Tier',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete the "${plan.name}" subscription tier?',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            if (plan.activeTenantsCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: ${plan.activeTenantsCount} active organization(s) are currently on this tier. Deleting it will mark it as inactive.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(platformAdminProvider.notifier).deletePlan(plan.id);
              AppFeedback.showSnackbar(
                context,
                message: 'Plan "${plan.name}" deleted successfully.',
              );
            },
            child: const Text(
              'Delete Plan',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
