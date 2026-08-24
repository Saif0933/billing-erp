import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class SupplierPage extends ConsumerStatefulWidget {
  const SupplierPage({super.key});

  @override
  ConsumerState<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends ConsumerState<SupplierPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allSuppliers = billingState.suppliers;

    // Filter suppliers
    final filteredSuppliers = allSuppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.mobile.contains(_searchQuery) ||
          s.gstin.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Supplier Directory',
              description: 'Manage details, purchases bills, and payments made to raw materials vendors.',
              breadcrumbs: const ['Dashboard', 'Parties', 'Suppliers'],
              actions: [
                AppButton(
                  label: 'Add Supplier',
                  icon: Icons.local_shipping_outlined,
                  onPressed: () => context.push('/suppliers/new'),
                ),
              ],
            ),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Search Suppliers',
                    hintText: 'Search by supplier name, mobile, or GSTIN...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Supplier>(
                    items: filteredSuppliers,
                    emptyMessage: 'No suppliers found matching the criteria.',
                    columns: [
                      TableColumnSpec<Supplier>(
                        label: 'Supplier Name',
                        flex: 2,
                        cellBuilder: (s) => InkWell(
                          onTap: () => context.push('/suppliers/${s.id}'),
                          child: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Mobile No.',
                        cellBuilder: (s) => Text(s.mobile.isNotEmpty ? s.mobile : 'N/A'),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'State',
                        cellBuilder: (s) => Text(s.state),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'GSTIN',
                        flex: 2,
                        cellBuilder: (s) => Text(s.gstin.isNotEmpty ? s.gstin : 'Unregistered'),
                      ),
                      TableColumnSpec<Supplier>(
                        label: 'Payable Balance',
                        isNumeric: true,
                        cellBuilder: (s) => Text(
                          '₹${s.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: s.currentBalance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                    mobileCardBuilder: (s) => InkWell(
                      onTap: () => context.push('/suppliers/${s.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Mobile: ${s.mobile} • State: ${s.state}'),
                            Text('GSTIN: ${s.gstin.isNotEmpty ? s.gstin : "Unregistered"}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payable Balance:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '₹${s.currentBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.currentBalance > 0 ? Colors.red : Colors.green,
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
