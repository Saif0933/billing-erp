import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/platform_admin_models.dart';
import '../providers/platform_admin_provider.dart';
import 'platform_tenant_modal.dart';

class PlatformTenantTable extends ConsumerWidget {
  final List<OrganizationTenant> tenants;

  const PlatformTenantTable({super.key, required this.tenants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (tenants.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.domain_disabled_outlined,
              size: 48,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No Organizations Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search query or status filter.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      // Mobile Cards List
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tenants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tenant = tenants[index];
          return _buildTenantCard(context, ref, tenant, isDark);
        },
      );
    }

    // Desktop Data Table with Horizontal Scroll Protection
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 920),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 68,
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('ORGANIZATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                DataColumn(label: Text('PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                DataColumn(label: Text('USERS & USAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                DataColumn(label: Text('MONTHLY SPEND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
              ],
              rows: tenants.map((tenant) {
                return DataRow(
                  cells: [
                    // Organization Name & Domain
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                tenant.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tenant.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tenant.domain,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: tenant.statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tenant.statusLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: tenant.statusColor,
                          ),
                        ),
                      ),
                    ),

                    // Plan Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          tenant.planName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Users & Storage Usage
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${tenant.activeUsersCount} / ${tenant.maxUsersLimit} Users',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tenant.storageUsedGb} GB of ${tenant.storageLimitGb.toInt()} GB',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Monthly Spend
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹ ${tenant.monthlySpend.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tenant.totalInvoices} Invoices',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Popup Menu
                    DataCell(
                      _buildActionMenu(context, ref, tenant),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(
    BuildContext context,
    WidgetRef ref,
    OrganizationTenant tenant,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code + Name + Status + Action
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tenant.code,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tenant.domain,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildActionMenu(context, ref, tenant),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Metadata Grid: Plan, Status, Spend, Users
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS & PLAN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tenant.statusBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tenant.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tenant.statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tenant.planName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MONTHLY SPEND',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${tenant.monthlySpend.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Usage Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Team: ${tenant.activeUsersCount}/${tenant.maxUsersLimit}',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  Text(
                    '${tenant.storageUsedGb} GB / ${tenant.storageLimitGb.toInt()} GB',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (tenant.storageUsedGb / tenant.storageLimitGb).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    WidgetRef ref,
    OrganizationTenant tenant,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Tenant Actions',
      onSelected: (action) {
        final notifier = ref.read(platformAdminProvider.notifier);
        switch (action) {
          case 'edit':
            PlatformTenantModal.show(context, tenant: tenant);
            break;
          case 'activate':
            notifier.toggleTenantStatus(tenant.id, TenantStatus.active);
            AppFeedback.showSnackbar(context, message: '${tenant.name} activated successfully!');
            break;
          case 'suspend':
            notifier.toggleTenantStatus(tenant.id, TenantStatus.suspended);
            AppFeedback.showSnackbar(context, message: '${tenant.name} has been suspended.', isError: true);
            break;
          case 'login_as':
            AppFeedback.showSnackbar(context, message: 'Impersonating ${tenant.name} admin session...');
            notifier.impersonateTenant(tenant.id);
            break;
          case 'delete':
            notifier.deleteTenant(tenant.id);
            AppFeedback.showSnackbar(context, message: '${tenant.name} removed from platform.');
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit Organization'),
            ],
          ),
        ),
        if (tenant.status != TenantStatus.active)
          const PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text('Activate Tenant', style: TextStyle(color: Color(0xFF16A34A))),
              ],
            ),
          ),
        if (tenant.status == TenantStatus.active)
          const PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.block, size: 18, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Suspend Tenant', style: TextStyle(color: Color(0xFFDC2626))),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'login_as',
          child: Row(
            children: [
              Icon(Icons.login, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Impersonate Login'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Tenant', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
