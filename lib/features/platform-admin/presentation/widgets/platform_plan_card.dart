import 'package:flutter/material.dart';
import '../../domain/models/platform_admin_models.dart';

class PlatformPlanCard extends StatelessWidget {
  final PlatformPlan plan;
  final VoidCallback? onEdit;
  final VoidCallback? onViewSubscribers;

  const PlatformPlanCard({
    super.key,
    required this.plan,
    this.onEdit,
    this.onViewSubscribers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular
              ? plan.themeColor
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isPopular
                ? plan.themeColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Popular Pill if popular
          if (plan.isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: plan.themeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'MOST POPULAR TIER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name + Subscribers Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: plan.themeColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: plan.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_outlined, size: 12, color: plan.themeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${plan.activeTenantsCount} Active Tenants',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: plan.themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  plan.tagline,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Price Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹ ${plan.priceMonthly.toInt()}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ month',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  'billed annually (₹${plan.priceYearly.toInt()}/yr)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Core Limits Highlights
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAX USERS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : const Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text('${plan.maxUsers} Seats', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STORAGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : const Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text('${plan.storageLimitGb.toInt()} GB SSD', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features List
                Text(
                  'PLAN CAPABILITIES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 10),
                ...plan.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit Tier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plan.themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.group_outlined, size: 15, color: Colors.white),
                        label: const Text('Tenants', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
    );
  }
}
