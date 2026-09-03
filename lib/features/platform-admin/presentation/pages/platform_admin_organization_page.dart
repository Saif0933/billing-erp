import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/platform_admin_provider.dart';
import '../widgets/platform_tenant_table.dart';
import '../widgets/platform_tenant_modal.dart';

class PlatformAdminOrganizationPage extends ConsumerWidget {
  const PlatformAdminOrganizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = state.filteredTenants;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tenant Organization Directory',
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage all provisioned enterprises, adjust seat limits, and supervise subscription statuses.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );

              final addButton = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_business, size: 16, color: Colors.white),
                label: const Text('Add Organization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () => PlatformTenantModal.show(context),
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 12),
                    addButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleSection,
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Search & Filter Controls Bar
          Container(
            padding: const EdgeInsets.all(14),
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
                // Search Input Field
                TextField(
                  onChanged: notifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by organization name, code, domain, GSTIN or admin email...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...['All', 'Active', 'Trial', 'Suspended'].map((status) {
                        final isSelected = state.selectedStatusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              status == 'Trial' ? 'Free Trial' : status,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                            selectedColor: const Color(0xFF4F46E5),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            onSelected: (_) => notifier.setStatusFilter(status),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Count Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Showing ${filteredList.length} of ${state.tenants.length} organizations',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tenants Table / Card View
          PlatformTenantTable(tenants: filteredList),
        ],
      ),
    );
  }
}
