import 'package:flutter/material.dart';
import '../../domain/models/platform_admin_models.dart';

class PlatformPlanCard extends StatelessWidget {
  final PlatformPlan plan;
  final bool isAnnualView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewSubscribers;

  const PlatformPlanCard({
    super.key,
    required this.plan,
    this.isAnnualView = false,
    this.onEdit,
    this.onDelete,
    this.onViewSubscribers,
  });

  IconData _getPlanIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('starter') || lower.contains('basic')) {
      return Icons.rocket_launch_rounded;
    } else if (lower.contains('growth') || lower.contains('pro')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('enterprise') || lower.contains('ultra')) {
      return Icons.apartment_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planIcon = _getPlanIcon(plan.name);

    // Annual calculations
    final displayPrice = isAnnualView
        ? (plan.priceYearly / 12).round()
        : plan.priceMonthly.toInt();

    final annualSavingsPercent = (plan.priceMonthly > 0 && plan.priceYearly > 0)
        ? (100 - (plan.priceYearly / (plan.priceMonthly * 12) * 100)).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.isPopular
              ? plan.themeColor
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isPopular
                ? plan.themeColor.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: plan.isPopular ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(plan.isPopular ? 18 : 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Popular Ribbon / Header
            if (plan.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      plan.themeColor,
                      plan.themeColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'MOST POPULAR CHOICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Icon + Name + Subscriber Count Chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: plan.themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(planIcon, size: 22, color: plan.themeColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: plan.themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business_rounded, size: 11, color: plan.themeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${plan.activeTenantsCount} Tenants',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: plan.themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    plan.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing Block
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹ $displayPrice',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAnnualView ? '/ mo' : '/ month',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            if (isAnnualView && annualSavingsPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Save $annualSavingsPercent%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAnnualView
                              ? 'Billed annually (₹${plan.priceYearly.toInt()} / year)'
                              : 'Billed monthly • ${plan.priceYearly > 0 ? "₹${plan.priceYearly.toInt()}/yr if annual" : "Standard billing"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quotas Bar (3 Columns)
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuotaChip(
                          icon: Icons.people_alt_outlined,
                          title: 'SEATS',
                          value: '${plan.maxUsers} Users',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuotaChip(
                          icon: Icons.receipt_long_outlined,
                          title: 'INVOICES',
                          value: plan.maxInvoicesPerMonth >= 99999
                              ? 'Unlimited'
                              : '${plan.maxInvoicesPerMonth}/mo',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuotaChip(
                          icon: Icons.cloud_outlined,
                          title: 'STORAGE',
                          value: '${plan.storageLimitGb.toInt()} GB',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Capabilities Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PLAN INCLUSIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${plan.features.length} features',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: plan.themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Features List
                  ...plan.features.take(5).map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.3,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (plan.features.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 8),
                      child: Text(
                        '+ ${plan.features.length - 5} more capabilities',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Card Action Buttons
                  Row(
                    children: [
                      // Edit Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: onEdit,
                        ),
                      ),

                      // Delete Button
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Delete Tier',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // View Subscribers Button
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: plan.themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.group_outlined, size: 14),
                          label: const Text(
                            'Tenants',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: onViewSubscribers,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaChip({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
