import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/service_provider.dart';

class ServicePage extends ConsumerStatefulWidget {
  const ServicePage({super.key});

  @override
  ConsumerState<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends ConsumerState<ServicePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.name}" (${service.code})? '
          'If this service is referenced in past invoices, it will be safely deactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(serviceProvider.notifier)
                    .deleteService(service.id);
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message:
                        'Service "${service.name}" deleted successfully.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message: e.toString().replaceAll('Exception:', '').trim(),
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);
    final serviceNotifier = ref.read(serviceProvider.notifier);
    final metrics = serviceState.metrics;

    final unitFilterOptions = [
      'All',
      'Hour',
      'Day',
      'Month',
      'Job',
      'Visit',
      'NOS',
      'Trip',
      'Session',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Work Master'),
        actions: [
          IconButton(
            tooltip: 'Refresh Services Directory',
            icon: const Icon(Icons.refresh),
            onPressed: () => serviceNotifier.loadServices(refresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Services Directory',
              description:
                  'Manage professional consulting, logistics, and labor service items with SAC codes and rates.',
              breadcrumbs: const ['Dashboard', 'Business Masters', 'Services & Work'],
              actions: [
                AppButton(
                  label: 'Add Service',
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.push('/services/new'),
                ),
              ],
            ),

            // Top Metric Cards from Backend
            if (metrics != null) ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: Responsive.isMobile(context) ? 1.6 : 1.85,
                children: [
                  AppMetricCard(
                    title: 'Total Services',
                    value: '${metrics.totalServices}',
                    icon: Icons.work_outline,
                  ),
                  AppMetricCard(
                    title: 'Active Services',
                    value: '${metrics.activeServices}',
                    icon: Icons.check_circle_outline,
                    trendColor: Colors.green,
                  ),
                  AppMetricCard(
                    title: 'GST Applicable',
                    value: '${metrics.gstApplicableServices}',
                    icon: Icons.domain_verification_outlined,
                  ),
                  AppMetricCard(
                    title: 'Avg Billing Rate',
                    value: '₹${metrics.averageRate.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    trendColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Error notice with retry
            if (serviceState.error != null && serviceState.error!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Using local cache: ${serviceState.error}',
                        style: TextStyle(
                            color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          serviceNotifier.loadServices(refresh: true),
                      child: const Text('Retry Server'),
                    ),
                  ],
                ),
              ),
            ],

            // Search and Filters Card
            AppCard(
              child: Column(
                children: [
                  if (serviceState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: LinearProgressIndicator(),
                    ),
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Search Services',
                          hintText: 'Search by service name, reference code, or SAC code...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) =>
                              serviceNotifier.setSearchQuery(val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context)
                            ? double.infinity
                            : 180,
                        child: AppDropdownField<String>(
                          label: 'Filter by Unit',
                          value: serviceState.selectedUnitFilter,
                          items: {
                            for (var unit in unitFilterOptions)
                              unit: unit == 'All' ? 'All Units' : unit,
                            if (serviceState.selectedUnitFilter.isNotEmpty &&
                                !unitFilterOptions
                                    .contains(serviceState.selectedUnitFilter))
                              serviceState.selectedUnitFilter:
                                  serviceState.selectedUnitFilter,
                          }
                              .entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (val) =>
                              serviceNotifier.setUnitFilter(val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Service>(
                    items: serviceState.services,
                    emptyMessage: serviceState.isLoading
                        ? 'Loading services from server...'
                        : 'No services found matching the criteria.',
                    columns: [
                      TableColumnSpec<Service>(
                        label: 'Service Info',
                        flex: 2,
                        cellBuilder: (s) => InkWell(
                          onTap: () => context.push('/services/edit/${s.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Code: ${s.code} | SAC: ${s.sacCode}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (s.description.isNotEmpty)
                                Text(
                                  s.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Billing Unit',
                        cellBuilder: (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.unit.isNotEmpty ? s.unit : 'Hour',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade800),
                          ),
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Standard Rate',
                        isNumeric: true,
                        cellBuilder: (s) => Text(
                          '₹${s.rate.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Discount',
                        isNumeric: true,
                        cellBuilder: (s) => Text(
                          s.discount > 0
                              ? '₹${s.discount.toStringAsFixed(2)}'
                              : '—',
                          style: TextStyle(
                            color: s.discount > 0 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'GST Rate',
                        cellBuilder: (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${s.gstRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Actions',
                        cellBuilder: (s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Service',
                              onPressed: () =>
                                  context.push('/services/edit/${s.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              tooltip: 'Delete Service',
                              onPressed: () => _confirmDelete(s),
                            ),
                          ],
                        ),
                      ),
                    ],
                    mobileCardBuilder: (s) => InkWell(
                      onTap: () => context.push('/services/edit/${s.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.unit.isNotEmpty ? s.unit : 'Hour',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Code: ${s.code} • SAC: ${s.sacCode}'),
                            if (s.description.isNotEmpty)
                              Text(
                                'Description: ${s.description}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            const Divider(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rate: ₹${s.rate.toStringAsFixed(2)} / ${s.unit}'),
                                Text(
                                  'GST: ${s.gstRate.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () =>
                                      context.push('/services/edit/${s.id}'),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.red),
                                  label: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () => _confirmDelete(s),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
