import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/feedback.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/gst_provider.dart';
import '../widgets/gst_header_profile_card.dart';
import '../widgets/gst_metric_cards.dart';
import '../widgets/gst_navigation_tabs.dart';
import '../widgets/gst_quick_actions_card.dart';
import '../widgets/gst_returns_dashboard_card.dart';
import '../widgets/gst_tax_liability_card.dart';

class GstPortalPage extends ConsumerWidget {
  const GstPortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.gst)) {
      return const LockedFeaturePage(featureName: 'GST Portal GSTIN');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header: GST Portal - GSTIN + [ Refresh from GST Portal ] + [ Go to GST Portal ↗ ]
              _buildPageHeader(context, ref, isDark),
              const SizedBox(height: 14),

              // 1. GSTIN Profile Card (Top Box)
              const GstHeaderProfileCard(),
              const SizedBox(height: 14),

              // 2. Horizontal Navigation Tabs (Overview, Returns, Payments, Ledger, Documents, GSTIN Details, Compliance)
              const GstNavigationTabs(),
              const SizedBox(height: 14),

              // 3. 5 KPI Metric Cards
              const GstMetricCards(),
              const SizedBox(height: 16),

              // 4. Middle Section: Upcoming & Recent Returns (Left) + Liability Summary Donut (Right)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 850;

                  if (isSmall) {
                    return Column(
                      children: const [
                        GstReturnsDashboardCard(),
                        SizedBox(height: 16),
                        GstTaxLiabilityCard(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        flex: 6,
                        child: GstReturnsDashboardCard(),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: GstTaxLiabilityCard(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 5. Quick Actions Section (6 Cards)
              const GstQuickActionsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, WidgetRef ref, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GST Portal - GSTIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your GSTIN details, filings, returns and compliance',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        final actionsWidget = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Outlined Refresh Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              ),
              icon: Icon(
                Icons.refresh,
                size: 15,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              label: Text(
                'Refresh from GST Portal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              onPressed: () async {
                AppFeedback.showSnackbar(context, message: 'Syncing live data from GSTN Portal...');
                final msg = await ref.read(gstStateProvider.notifier).syncFromPortal();
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: msg);
                }
              },
            ),

            // Green Solid [ Go to GST Portal ↗ ] Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D), // Green
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Text(
                'Go to GST Portal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              label: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
              onPressed: () {
                AppFeedback.showSnackbar(context, message: 'Opening https://www.gst.gov.in in browser...');
              },
            ),
          ],
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 10),
              actionsWidget,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 12),
            actionsWidget,
          ],
        );
      },
    );
  }
}
