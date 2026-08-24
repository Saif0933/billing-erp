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
import '../../../dashboard/presentation/providers/billing_repository.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allCustomers = billingState.customers;

    // Filter customers
    final filteredCustomers = allCustomers.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.mobile.contains(_searchQuery) ||
          c.gstin.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedTypeFilter == 'All' || c.type == _selectedTypeFilter;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Customer Directory',
              description: 'Manage details, outstanding bills, and ledger balances for your clients.',
              breadcrumbs: const ['Dashboard', 'Parties', 'Customers'],
              actions: [
                AppButton(
                  label: 'Add Customer',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => context.push('/customers/new'),
                ),
              ],
            ),
            AppCard(
              child: Column(
                children: [
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Search Customers',
                          hintText: 'Search by name, mobile, or GSTIN...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context) ? double.infinity : 180,
                        child: AppDropdownField<String>(
                          label: 'Filter by Type',
                          value: _selectedTypeFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Types')),
                            DropdownMenuItem(value: 'Wholesale', child: Text('Wholesale')),
                            DropdownMenuItem(value: 'Retail', child: Text('Retail')),
                          ],
                          onChanged: (val) => setState(() => _selectedTypeFilter = val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Customer>(
                    items: filteredCustomers,
                    emptyMessage: 'No customers found matching the search criteria.',
                    columns: [
                      TableColumnSpec<Customer>(
                        label: 'Customer Name',
                        flex: 2,
                        cellBuilder: (c) => InkWell(
                          onTap: () => context.push('/customers/${c.id}'),
                          child: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Type',
                        cellBuilder: (c) => Text(c.type),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'State',
                        cellBuilder: (c) => Text(c.state),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'Mobile No.',
                        cellBuilder: (c) => Text(c.mobile.isNotEmpty ? c.mobile : 'N/A'),
                      ),
                      TableColumnSpec<Customer>(
                        label: 'GSTIN',
                        flex: 2,
                        cellBuilder: (c) => Text(c.gstin.isNotEmpty ? c.gstin : 'Unregistered'),
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
                    ],
                    mobileCardBuilder: (c) => InkWell(
                      onTap: () => context.push('/customers/${c.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Type: ${c.type} • Mobile: ${c.mobile}'),
                            Text('GSTIN: ${c.gstin.isNotEmpty ? c.gstin : "Unregistered"}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Outstanding Balance:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '₹${c.currentBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: c.currentBalance > 0 ? Colors.red : Colors.green,
                                  ),
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
