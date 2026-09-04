import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../providers/supplier_provider.dart';

class SupplierDetailPage extends ConsumerWidget {
  final String supplierId;
  const SupplierDetailPage({super.key, required this.supplierId});

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"? '
          'If the supplier has existing purchase bills or ledger entries, they will be safely deactivated.',
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
                if (context.mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message:
                        'Supplier "${supplier.name}" processed successfully.',
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingRepositoryProvider);
    final supplierState = ref.watch(supplierProvider);
    final liveDetailAsync = ref.watch(supplierDetailProvider(supplierId));

    // Resolve Supplier from live backend detail or fallback to state
    Supplier? resolvedSupplier = liveDetailAsync.value?.supplier;
    if (resolvedSupplier == null) {
      for (final s in supplierState.suppliers) {
        if (s.id == supplierId) {
          resolvedSupplier = s;
          break;
        }
      }
    }
    if (resolvedSupplier == null) {
      for (final s in billingState.suppliers) {
        if (s.id == supplierId) {
          resolvedSupplier = s;
          break;
        }
      }
    }

    final supplier = resolvedSupplier ??
        const Supplier(
          id: '',
          name: 'Not Found',
          gstin: '',
          pan: '',
          mobile: '',
          email: '',
          address: '',
          state: '',
          stateCode: '',
          creditTerms: 0,
          openingBalance: 0,
          currentBalance: 0,
          supplierGroup: '',
          notes: '',
        );

    if (supplier.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Details')),
        body: const Center(child: Text('Supplier profile not found.')),
      );
    }

    // Filter transactions
    final supplierPurchases = billingState.purchases
        .where((p) => p.supplierId == supplierId)
        .toList();
    final supplierPayments = billingState.payments
        .where((p) => p.supplierId == supplierId)
        .toList();

    final purchaseNumbers =
        supplierPurchases.map((p) => p.purchaseNumber).toSet();
    final paymentRefs = supplierPayments.map((p) => p.referenceNumber).toSet();
    final supplierLedger = billingState.ledgerEntries.where((entry) {
      return purchaseNumbers.contains(entry.referenceNumber) ||
          paymentRefs.contains(entry.referenceNumber) ||
          entry.particulars.contains(supplier.name) ||
          (entry.type == LedgerTransactionType.openingBalance &&
              entry.id.contains(supplier.id));
    }).toList();

    // Stats from live backend or local calculation
    final totalPurchasesValue = liveDetailAsync.value?.statistics[
            'lifetimePurchasedValue'] ??
        supplierPurchases
            .where((p) => p.status != PurchaseStatus.cancelled)
            .fold<double>(0.0, (prev, p) => prev + p.grandTotal);
    final totalPaymentsValue = liveDetailAsync.value?.statistics[
            'lifetimePaymentsValue'] ??
        supplierPayments.fold<double>(0.0, (prev, pay) => prev + pay.amount);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(supplier.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Profile',
              onPressed: () {
                ref.invalidate(supplierDetailProvider(supplierId));
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Supplier',
              onPressed: () => context.push('/suppliers/edit/${supplier.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Supplier',
              onPressed: () => _confirmDelete(context, ref, supplier),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: supplier.name,
                description:
                    'Mobile: ${supplier.mobile.isNotEmpty ? supplier.mobile : "N/A"} • State: ${supplier.state}',
                breadcrumbs: ['Dashboard', 'Suppliers', supplier.name],
              ),

              // Key Stats
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: Responsive.isMobile(context) ? 3.0 : 2.2,
                children: [
                  AppMetricCard(
                    title: 'Current Outward Payable',
                    value: '₹${supplier.currentBalance.toStringAsFixed(2)}',
                    trendColor: supplier.currentBalance > 0
                        ? Colors.red
                        : Colors.green,
                    trendLabel:
                        supplier.currentBalance > 0 ? 'Payable' : 'Clear',
                  ),
                  AppMetricCard(
                    title: 'Total Purchased Value',
                    value:
                        '₹${(totalPurchasesValue as num).toDouble().toStringAsFixed(2)}',
                    subtitle: 'Confirmed Purchase Bills',
                  ),
                  AppMetricCard(
                    title: 'Total Payments Cleared',
                    value:
                        '₹${(totalPaymentsValue as num).toDouble().toStringAsFixed(2)}',
                    subtitle: 'Outward Payments',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Detail Section Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier Information',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                  'GSTIN:',
                                  supplier.gstin.isNotEmpty
                                      ? supplier.gstin
                                      : 'Unregistered'),
                              _buildInfoRow(
                                  'PAN:',
                                  supplier.pan.isNotEmpty
                                      ? supplier.pan
                                      : 'N/A'),
                              _buildInfoRow(
                                  'Email:',
                                  supplier.email.isNotEmpty
                                      ? supplier.email
                                      : 'N/A'),
                              _buildInfoRow(
                                  'Mobile:',
                                  supplier.mobile.isNotEmpty
                                      ? supplier.mobile
                                      : 'N/A'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Office/Warehouse Address:',
                                  supplier.address),
                              _buildInfoRow('State / State Code:',
                                  '${supplier.state} (${supplier.stateCode})'),
                              _buildInfoRow('Credit Terms:',
                                  '${supplier.creditTerms} Days'),
                              _buildInfoRow('Supplier Group:',
                                  supplier.supplierGroup),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Tabs
              TabBar(
                tabs: const [
                  Tab(text: 'Ledger Statement'),
                  Tab(text: 'Purchase Bills'),
                  Tab(text: 'Payments Outward'),
                  Tab(text: 'Outstanding Payables'),
                ],
                labelStyle: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey,
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    // Tab 1: Ledger Statement
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<LedgerEntry>(
                        items: supplierLedger,
                        emptyMessage:
                            'No ledger transactions recorded for this supplier.',
                        columns: [
                          TableColumnSpec<LedgerEntry>(
                            label: 'Date',
                            cellBuilder: (l) => Text(
                                '${l.date.day}/${l.date.month}/${l.date.year}'),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Particulars',
                            flex: 2,
                            cellBuilder: (l) => Text(l.particulars),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Ref No.',
                            cellBuilder: (l) => Text(l.referenceNumber),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Debit (₹)',
                            isNumeric: true,
                            cellBuilder: (l) => Text(l.debit > 0
                                ? l.debit.toStringAsFixed(2)
                                : '-'),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Credit (₹)',
                            isNumeric: true,
                            cellBuilder: (l) => Text(l.credit > 0
                                ? l.credit.toStringAsFixed(2)
                                : '-'),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Purchase Bills
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Purchase>(
                        items: supplierPurchases,
                        emptyMessage:
                            'No purchases recorded for this supplier.',
                        columns: [
                          TableColumnSpec<Purchase>(
                            label: 'Purchase Number',
                            cellBuilder: (pur) => InkWell(
                              onTap: () => context.push('/purchase/${pur.id}'),
                              child: Text(pur.purchaseNumber,
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Inv Ref',
                            cellBuilder: (pur) =>
                                Text(pur.supplierInvoiceNumber),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Date',
                            cellBuilder: (pur) => Text(
                                '${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}'),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Grand Total',
                            isNumeric: true,
                            cellBuilder: (pur) =>
                                Text('₹${pur.grandTotal.toStringAsFixed(2)}'),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Status',
                            cellBuilder: (pur) => Text(
                              pur.status.name.toUpperCase(),
                              style: TextStyle(
                                color: pur.status == PurchaseStatus.paid
                                    ? Colors.green
                                    : pur.status == PurchaseStatus.cancelled
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 3: Payments Outward
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Payment>(
                        items: supplierPayments,
                        emptyMessage:
                            'No outward payments recorded for this supplier.',
                        columns: [
                          TableColumnSpec<Payment>(
                            label: 'Date',
                            cellBuilder: (p) => Text(
                                '${p.date.day}/${p.date.month}/${p.date.year}'),
                          ),
                          TableColumnSpec<Payment>(
                            label: 'Payment Ref',
                            cellBuilder: (p) => Text(p.referenceNumber),
                          ),
                          TableColumnSpec<Payment>(
                            label: 'Mode',
                            cellBuilder: (p) => Text(p.paymentMode),
                          ),
                          TableColumnSpec<Payment>(
                            label: 'Allocated Bills',
                            flex: 2,
                            cellBuilder: (p) => Text(p.allocations
                                .map((a) => a.purchaseId)
                                .join(', ')),
                          ),
                          TableColumnSpec<Payment>(
                            label: 'Amount Paid',
                            isNumeric: true,
                            cellBuilder: (p) => Text(
                              '₹${p.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 4: Outstanding Payables
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Purchase>(
                        items: supplierPurchases
                            .where((p) =>
                                p.status != PurchaseStatus.paid &&
                                p.status != PurchaseStatus.cancelled)
                            .toList(),
                        emptyMessage:
                            'No outstanding payables for this supplier.',
                        columns: [
                          TableColumnSpec<Purchase>(
                            label: 'Bill Number',
                            cellBuilder: (pur) => Text(pur.purchaseNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Invoice Ref',
                            cellBuilder: (pur) =>
                                Text(pur.supplierInvoiceNumber),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Date',
                            cellBuilder: (pur) => Text(
                                '${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}'),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Total Amount',
                            isNumeric: true,
                            cellBuilder: (pur) =>
                                Text('₹${pur.grandTotal.toStringAsFixed(2)}'),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Payable Amount',
                            isNumeric: true,
                            cellBuilder: (pur) => Text(
                              '₹${pur.balanceAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
