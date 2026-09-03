import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/platform_admin_provider.dart';
import '../widgets/platform_kpi_card.dart';
import '../widgets/platform_tenant_table.dart';
import '../widgets/platform_tenant_modal.dart';

class PlatformAdminDashboardPage extends ConsumerWidget {
  const PlatformAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Welcome & Quick Actions Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;

              final headerInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Platform Executive Dashboard',
                        style: TextStyle(
                          fontSize: isSmall ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'ALL SYSTEMS NORMAL',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Multi-tenant infrastructure overview, revenue metrics & organization health.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('New Onboarding', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    onPressed: () => notifier.setNavTab('onboarding'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_business, size: 16, color: Colors.white),
                    label: const Text('Add Tenant', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () => PlatformTenantModal.show(context),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  headerInfo,
                  actionButtons,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Platform KPI Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 4;
              if (width < 600) {
                crossAxisCount = 1;
              } else if (width < 1000) {
                crossAxisCount = 2;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxisCount == 1 ? 2.8 : (crossAxisCount == 2 ? 2.1 : 1.9),
                children: [
                  PlatformKpiCard(
                    title: 'MONTHLY RECURRING (MRR)',
                    value: '₹ ${(state.kpis.totalMrr / 1000).toStringAsFixed(1)}k',
                    subtitle: 'Annualized: ₹${(state.kpis.totalArr / 100000).toStringAsFixed(1)}L',
                    trend: '+${state.kpis.mrrGrowthPercentage}%',
                    isPositiveTrend: true,
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF16A34A),
                  ),
                  PlatformKpiCard(
                    title: 'ACTIVE ORGANIZATIONS',
                    value: '${state.kpis.activeTenants} / ${state.kpis.totalTenants}',
                    subtitle: '${state.kpis.trialTenants} in Free Trial status',
                    trend: '+12 this mo',
                    isPositiveTrend: true,
                    icon: Icons.domain_outlined,
                    iconColor: const Color(0xFF4F46E5),
                  ),
                  PlatformKpiCard(
                    title: 'TOTAL PLATFORM USERS',
                    value: '${state.kpis.totalUsers}',
                    subtitle: 'Across 148 tenant organizations',
                    trend: '+64 new',
                    isPositiveTrend: true,
                    icon: Icons.people_alt_outlined,
                    iconColor: const Color(0xFF0284C7),
                  ),
                  PlatformKpiCard(
                    title: 'SYSTEM HEALTH & UPTIME',
                    value: '${state.kpis.systemUptimePercentage}%',
                    subtitle: 'Cluster latency: ${state.kpis.serverLatencyMs}ms',
                    icon: Icons.cloud_done_outlined,
                    iconColor: const Color(0xFF059669),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Pending Onboarding Approvals Banner (If any)
          if (state.onboardingRequests.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 560;

                      final headerTitle = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_actions, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Pending Tenant Onboarding Approvals (${state.onboardingRequests.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFFB45309)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );

                      final viewAllLink = TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => notifier.setNavTab('onboarding'),
                        child: const Text('View All in Wizard →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerTitle,
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: viewAllLink,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: headerTitle),
                          const SizedBox(width: 8),
                          viewAllLink,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ...state.onboardingRequests.take(2).map((req) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final reqText = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.organizationName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Admin: ${req.adminName} (${req.adminEmail}) • Plan: ${req.requestedPlanName}',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );

                          final approveBtn = ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              notifier.approveOnboardingRequest(req.id);
                              AppFeedback.showSnackbar(context, message: '${req.organizationName} approved and provisioned!');
                            },
                            child: const Text('Approve & Launch', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                reqText,
                                const SizedBox(height: 8),
                                approveBtn,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: reqText),
                              const SizedBox(width: 10),
                              approveBtn,
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Active Organizations Table Header & View
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;

              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Tenant Organizations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recent enterprise deployments and utilization rates.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final viewFullBtn = TextButton(
                onPressed: () => notifier.setNavTab('organizations'),
                child: const Text('View Full Directory →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleCol,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: viewFullBtn,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleCol),
                  viewFullBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          PlatformTenantTable(tenants: state.tenants.take(5).toList()),
        ],
      ),
    );
  }
}
