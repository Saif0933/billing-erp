import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gst_provider.dart';

class GstMetricCards extends ConsumerWidget {
  const GstMetricCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(gstKpiMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 32) / 5;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Card 1: Return Compliance (This FY)
            SizedBox(
              width: cardWidth,
              child: Container(
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
                  children: [
                    Text(
                      'Return Compliance (This FY)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${kpi.returnsFiledCount} / ${kpi.totalReturnsCount}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Returns Filed',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Circular Percentage Donut
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: kpi.returnCompliancePercentage / 100.0,
                                strokeWidth: 3.5,
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                              ),
                              Text(
                                '${kpi.returnCompliancePercentage.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Liability (Upcoming)
            SizedBox(
              width: cardWidth,
              child: _buildStandardMetricCard(
                title: 'Liability (Upcoming)',
                value: '₹${_formatCurrency(kpi.upcomingLiability)}',
                valueColor: const Color(0xFFDC2626),
                subtitle: 'Next Payment Due',
                icon: Icons.calendar_today_outlined,
                iconBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                isDark: isDark,
              ),
            ),

            // Card 3: ITC Available
            SizedBox(
              width: cardWidth,
              child: _buildStandardMetricCard(
                title: 'ITC Available',
                value: '₹${_formatCurrency(kpi.itcAvailable)}',
                valueColor: const Color(0xFF0284C7),
                subtitle: 'As per GSTR-2B',
                icon: Icons.account_balance_wallet_outlined,
                iconBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),

            // Card 4: Annual Turnover (FY 2024-25)
            SizedBox(
              width: cardWidth,
              child: _buildStandardMetricCard(
                title: 'Annual Turnover (FY 2024-25)',
                value: '₹${_formatCurrency(kpi.annualTurnover)}',
                valueColor: const Color(0xFF9333EA),
                subtitle: kpi.turnoverDateLabel,
                icon: Icons.trending_up,
                iconBg: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                isDark: isDark,
              ),
            ),

            // Card 5: GSTIN Status
            SizedBox(
              width: cardWidth,
              child: _buildStandardMetricCard(
                title: 'GSTIN Status',
                value: kpi.gstinStatus,
                valueColor: const Color(0xFF16A34A),
                subtitle: 'View details',
                icon: Icons.verified_user_outlined,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandardMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
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
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          color: valueColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
        ],
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
