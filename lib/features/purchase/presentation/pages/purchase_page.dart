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

class PurchasePage extends ConsumerStatefulWidget {
  const PurchasePage({super.key});

  @override
  ConsumerState<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends ConsumerState<PurchasePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allPurchases = billingState.purchases;

    // Filter purchases
    final filteredPurchases = allPurchases.where((p) {
      final matchesSearch = p.purchaseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.supplierInvoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'All' || p.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase & Bills'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Purchase Registers',
              description: 'Record incoming supplier bills, track debit notes, and manage payables balances.',
              breadcrumbs: const ['Dashboard', 'Purchase', 'Bills'],
              actions: [
                AppButton(
                  label: 'Record Purchase',
                  icon: Icons.post_add_outlined,
                  onPressed: () => context.push('/purchase/new'),
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
                          label: 'Search Purchase Bills',
                          hintText: 'Search by bill number, supplier invoice, or supplier name...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context) ? double.infinity : 180,
                        child: AppDropdownField<String>(
                          label: 'Filter Status',
                          value: _selectedStatusFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                            DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                            DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                            DropdownMenuItem(value: 'PartiallyPaid', child: Text('Partially Paid')),
                            DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Purchase>(
                    items: filteredPurchases,
                    emptyMessage: 'No purchase bills match the selected criteria.',
                    columns: [
                      TableColumnSpec<Purchase>(
                        label: 'Purchase No.',
                        cellBuilder: (pur) => InkWell(
                          onTap: () => context.push('/purchase/${pur.id}'),
                          child: Text(
                            pur.purchaseNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Supplier Invoice',
                        cellBuilder: (pur) => Text(pur.supplierInvoiceNumber),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Date',
                        cellBuilder: (pur) => Text('${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}'),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Supplier',
                        flex: 2,
                        cellBuilder: (pur) => Text(pur.supplierName),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Grand Total',
                        isNumeric: true,
                        cellBuilder: (pur) => Text(
                          '₹${pur.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Remaining Payable',
                        isNumeric: true,
                        cellBuilder: (pur) => Text(
                          '₹${pur.balanceAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pur.balanceAmount > 0 && pur.status != PurchaseStatus.cancelled ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                      TableColumnSpec<Purchase>(
                        label: 'Status',
                        cellBuilder: (pur) {
                          Color badgeColor;
                          switch (pur.status) {
                            case PurchaseStatus.draft:
                              badgeColor = Colors.grey;
                              break;
                            case PurchaseStatus.confirmed:
                              badgeColor = Colors.blue;
                              break;
                            case PurchaseStatus.partiallyPaid:
                              badgeColor = Colors.orange;
                              break;
                            case PurchaseStatus.paid:
                              badgeColor = Colors.green;
                              break;
                            case PurchaseStatus.cancelled:
                              badgeColor = Colors.red;
                              break;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pur.status.name.toUpperCase(),
                              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ],
                    mobileCardBuilder: (pur) => InkWell(
                      onTap: () => context.push('/purchase/${pur.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(pur.purchaseNumber, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  pur.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: pur.status == PurchaseStatus.paid ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Supplier: ${pur.supplierName} • Ref: ${pur.supplierInvoiceNumber}'),
                            Text('Date: ${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Grand Total: ₹${pur.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('Payable Due: ₹${pur.balanceAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
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
