import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/platform_admin_provider.dart';
import '../widgets/platform_onboarding_wizard.dart';

class PlatformAdminOnboardingPage extends ConsumerStatefulWidget {
  const PlatformAdminOnboardingPage({super.key});

  @override
  ConsumerState<PlatformAdminOnboardingPage> createState() => _PlatformAdminOnboardingPageState();
}

class _PlatformAdminOnboardingPageState extends ConsumerState<PlatformAdminOnboardingPage> {
  int _selectedSubTab = 0; // 0: Wizard, 1: Pending Approvals

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enterprise Onboarding & Provisioning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Launch new tenant organizations, provision cloud databases, and process self-service registration requests.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sub-Tab Switcher (Wizard vs Pending Approvals) with Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton(
                  title: 'New Tenant Wizard',
                  icon: Icons.auto_awesome,
                  isSelected: _selectedSubTab == 0,
                  onTap: () => setState(() => _selectedSubTab = 0),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildSubTabButton(
                  title: 'Pending Approvals (${state.onboardingRequests.length})',
                  icon: Icons.pending_actions,
                  isSelected: _selectedSubTab == 1,
                  badgeCount: state.onboardingRequests.length,
                  onTap: () => setState(() => _selectedSubTab = 1),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content
          if (_selectedSubTab == 0)
            const PlatformOnboardingWizard()
          else
            _buildApprovalsList(context, notifier, state, isDark),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsList(
    BuildContext context,
    PlatformAdminNotifier notifier,
    PlatformAdminState state,
    bool isDark,
  ) {
    if (state.onboardingRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF16A34A)),
            const SizedBox(height: 12),
            const Text(
              'No Pending Onboarding Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All self-service and assisted registrations have been approved.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.onboardingRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = state.onboardingRequests[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;

              final reqDetails = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PENDING APPROVAL',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Requested: ${req.requestedPlanName} Plan',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req.organizationName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GSTIN: ${req.gstin.isNotEmpty ? req.gstin : 'Not Provided'} • Category: ${req.businessType} • State: ${req.state}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Primary Admin: ${req.adminName} (${req.adminEmail} • ${req.adminPhone})',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: isSmall ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (isSmall) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          AppFeedback.showSnackbar(context, message: 'Request rejected.', isError: true);
                        },
                        child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle, size: 15, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () {
                          notifier.approveOnboardingRequest(req.id);
                          AppFeedback.showSnackbar(context, message: 'Tenant "${req.organizationName}" approved and launched!');
                        },
                      ),
                    ),
                  ] else ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        AppFeedback.showSnackbar(context, message: 'Request rejected.', isError: true);
                      },
                      child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                      label: const Text('Approve & Launch', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: () {
                        notifier.approveOnboardingRequest(req.id);
                        AppFeedback.showSnackbar(context, message: 'Tenant "${req.organizationName}" approved and launched!');
                      },
                    ),
                  ],
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    reqDetails,
                    const SizedBox(height: 14),
                    actionButtons,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: reqDetails),
                  const SizedBox(width: 16),
                  actionButtons,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
