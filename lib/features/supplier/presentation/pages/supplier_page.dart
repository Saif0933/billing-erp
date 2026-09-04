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
import '../providers/supplier_provider.dart';

class SupplierPage extends ConsumerStatefulWidget {
  const SupplierPage({super.key});

  @override
  ConsumerState<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends ConsumerState<SupplierPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"? '
          'If the vendor has existing purchase bills or ledger entries, they will be safely deactivated.',
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
                    .read(supplierProvider.notifier)
                    .deleteSupplier(supplier.id);
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message:
                        'Supplier "${supplier.name}" processed successfully.',
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
    final supplierState = ref.watch(supplierProvider);
    final supplierNotifier = ref.read(supplierProvider.notifier);
    final metrics = supplierState.metrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            tooltip: 'Refresh Supplier Directory',
            icon: const Icon(Icons.refresh),
            onPressed: () => supplierNotifier.loadSuppliers(refresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Supplier Directory',
              description:
                  'Manage vendor profiles, purchase bills, payable dues, and supplier ledgers.',
              breadcrumbs: const ['Dashboard', 'Business Masters', 'Suppliers'],
              actions: [
                AppButton(
                  label: 'Add Supplier',
                  icon: Icons.local_shipping_outlined,
                  onPressed: () => context.push('/suppliers/new'),
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
                    title: 'Total Suppliers',
                    value: '${metrics.totalSuppliers}',
                    icon: Icons.local_shipping_outlined,
                  ),
                  AppMetricCard(
                    title: 'Active Suppliers',
                    value: '${metrics.activeSuppliers}',
                    icon: Icons.check_circle_outline,
                    trendColor: Colors.green,
                  ),
                  AppMetricCard(
                    title: 'GST Registered',
                    value: '${metrics.registeredSuppliers}',
                    icon: Icons.domain_verification_outlined,
                  ),
                  AppMetricCard(
                    title: 'Total Payables',
                    value: '₹${metrics.totalPayable.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    trendColor:
                        metrics.totalPayable > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Error notice with retry
            if (supplierState.error != null &&
                supplierState.error!.isNotEmpty) ...[
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
                        'Using local cache: ${supplierState.error}',
                        style: TextStyle(
                            color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          supplierNotifier.loadSuppliers(refresh: true),
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
                  if (supplierState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: LinearProgressIndicator(),
                    ),
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Search Suppliers',
                          hintText: 'Search by supplier name, mobile, or GSTIN...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) =>
                              supplierNotifier.setSearchQuery(val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context)
                            ? double.infinity
                            : 180,
                        child: AppDropdownField<String>(
                          label: 'Filter by Group',
                          value: supplierState.selectedGroupFilter,
                          items: {
                            'All': 'All Groups',
                            'General': 'General',
                            'Raw Materials': 'Raw Materials',
                            'Packaging': 'Packaging',
                            'Consumables': 'Consumables',
                            if (supplierState.selectedGroupFilter.isNotEmpty)
                              supplierState.selectedGroupFilter:
                                  supplierState.selectedGroupFilter == 'All'
                                      ? 'All Groups'
                                      : supplierState.selectedGroupFilter,
                          }
                              .entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (val) =>
                              supplierNotifier.setGroupFilter(val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Supplier>(
                    items: supplierState.suppliers,
                    emptyMessage: supplierState.isLoading
                        ? 'Loading suppliers from server...'
                        : 'No suppliers found matching the criteria.',
                    columns: [
                      TableColumnSpec<Supplier>(
                        label: 'Supplier Name',
                        flex: 2,
                        cellBuilder: (s) => InkWell(
                          onTap: () => context.push('/suppliers/${s.id}'),
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
                              if (s.email.isNotEmpty)
                                Text(
                                  s.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Group',
                        cellBuilder: (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.supplierGroup.isNotEmpty
                                ? s.supplierGroup
                                : 'General',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade800),
                          ),
                        ),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'State',
                        cellBuilder: (s) =>
                            Text(s.state.isNotEmpty ? s.state : '—'),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Mobile No.',
                        cellBuilder: (s) =>
                            Text(s.mobile.isNotEmpty ? s.mobile : '—'),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'GSTIN',
                        flex: 2,
                        cellBuilder: (s) => Text(
                          s.gstin.isNotEmpty ? s.gstin : 'Unregistered',
                          style: TextStyle(
                            fontFamily: s.gstin.isNotEmpty ? 'monospace' : null,
                            color: s.gstin.isNotEmpty
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Payable Balance',
                        isNumeric: true,
                        cellBuilder: (s) => Text(
                          '₹${s.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: s.currentBalance > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Actions',
                        cellBuilder: (s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Supplier',
                              onPressed: () =>
                                  context.push('/suppliers/edit/${s.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              tooltip: 'Delete Supplier',
                              onPressed: () => _confirmDelete(s),
                            ),
                          ],
                        ),
                      ),
                    ],
                    mobileCardBuilder: (s) => InkWell(
                      onTap: () => context.push('/suppliers/${s.id}'),
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
                                    s.supplierGroup.isNotEmpty
                                        ? s.supplierGroup
                                        : 'General',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Mobile: ${s.mobile.isNotEmpty ? s.mobile : "N/A"} • State: ${s.state}'),
                            Text(
                              'GSTIN: ${s.gstin.isNotEmpty ? s.gstin : "Unregistered"}',
                              style: TextStyle(
                                fontFamily: s.gstin.isNotEmpty ? 'monospace' : null,
                                color: s.gstin.isNotEmpty ? Colors.black87 : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const Divider(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payable Balance:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  '₹${s.currentBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.currentBalance > 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
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
                                      context.push('/suppliers/edit/${s.id}'),
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
