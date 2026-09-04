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
import '../providers/customer_provider.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? '
          'If the customer has existing invoices or ledger entries, they will be safely deactivated.',
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
                await ref.read(customerProvider.notifier).deleteCustomer(customer.id);
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message: 'Customer "${customer.name}" processed successfully.',
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
    final customerState = ref.watch(customerProvider);
    final customerNotifier = ref.read(customerProvider.notifier);
    final metrics = customerState.metrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Refresh Customer Directory',
            icon: const Icon(Icons.refresh),
            onPressed: () => customerNotifier.loadCustomers(refresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Customer Directory',
              description:
                  'Manage client profiles, GSTIN details, outstanding dues, and party ledgers.',
              breadcrumbs: const ['Dashboard', 'Business Masters', 'Customers'],
              actions: [
                AppButton(
                  label: 'Add Customer',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => context.push('/customers/new'),
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
                    title: 'Total Customers',
                    value: '${metrics.totalCustomers}',
                    icon: Icons.people_outline,
                  ),
                  AppMetricCard(
                    title: 'Active Customers',
                    value: '${metrics.activeCustomers}',
                    icon: Icons.check_circle_outline,
                    trendColor: Colors.green,
                  ),
                  AppMetricCard(
                    title: 'GST Registered',
                    value: '${metrics.registeredCustomers}',
                    icon: Icons.domain_verification_outlined,
                  ),
                  AppMetricCard(
                    title: 'Total Receivables',
                    value: '₹${metrics.totalReceivables.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    trendColor: metrics.totalReceivables > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Error notice with retry
            if (customerState.error != null && customerState.error!.isNotEmpty) ...[
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
                        'Using local cache: ${customerState.error}',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => customerNotifier.loadCustomers(refresh: true),
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
                  if (customerState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: LinearProgressIndicator(),
                    ),
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Search Customers',
                          hintText: 'Search by name, mobile, or GSTIN...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) => customerNotifier.setSearchQuery(val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context) ? double.infinity : 180,
                        child: AppDropdownField<String>(
                          label: 'Filter by Type',
                          value: customerState.selectedTypeFilter,
                          items: {
                            'All': 'All Types',
                            'Wholesale': 'Wholesale',
                            'Retail': 'Retail',
                            'Corporate': 'Corporate',
                            'General': 'General',
                            if (customerState.selectedTypeFilter.isNotEmpty)
                              customerState.selectedTypeFilter: customerState.selectedTypeFilter == 'All'
                                  ? 'All Types'
                                  : customerState.selectedTypeFilter,
                          }.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                          onChanged: (val) =>
                              customerNotifier.setTypeFilter(val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Customer>(
                    items: customerState.customers,
                    emptyMessage: customerState.isLoading
                        ? 'Loading customers from server...'
                        : 'No customers found matching the search criteria.',
                    columns: [
                      TableColumnSpec<Customer>(
                        label: 'Customer Name',
                        flex: 2,
                        cellBuilder: (c) => InkWell(
                          onTap: () => context.push('/customers/${c.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              if (c.email.isNotEmpty)
                                Text(
                                  c.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Type',
                        cellBuilder: (c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.type,
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                          ),
                        ),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'State',
                        cellBuilder: (c) => Text(c.state.isNotEmpty ? c.state : '—'),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Mobile No.',
                        cellBuilder: (c) => Text(c.mobile.isNotEmpty ? c.mobile : '—'),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'GSTIN',
                        flex: 2,
                        cellBuilder: (c) => Text(
                          c.gstin.isNotEmpty ? c.gstin : 'Unregistered',
                          style: TextStyle(
                            fontFamily: c.gstin.isNotEmpty ? 'monospace' : null,
                            color: c.gstin.isNotEmpty ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Outstanding',
                        isNumeric: true,
                        cellBuilder: (c) => Text(
                          '₹${c.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.currentBalance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Actions',
                        cellBuilder: (c) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Customer',
                              onPressed: () => context.push('/customers/edit/${c.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'Delete Customer',
                              onPressed: () => _confirmDelete(c),
                            ),
                          ],
                        ),
                      ),
                    ],
                    mobileCardBuilder: (c) => InkWell(
                      onTap: () => context.push('/customers/${c.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.type,
                                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Mobile: ${c.mobile.isNotEmpty ? c.mobile : "—"}'),
                            Text(
                              'GSTIN: ${c.gstin.isNotEmpty ? c.gstin : "Unregistered"}',
                              style: TextStyle(
                                fontFamily: c.gstin.isNotEmpty ? 'monospace' : null,
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Outstanding Balance:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '₹${c.currentBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: c.currentBalance > 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () => context.push('/customers/edit/${c.id}'),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () => _confirmDelete(c),
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
