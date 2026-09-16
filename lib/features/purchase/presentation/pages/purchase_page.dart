import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../providers/purchase_provider.dart';

class PurchasePage extends ConsumerStatefulWidget {
  const PurchasePage({super.key});

  @override
  ConsumerState<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends ConsumerState<PurchasePage> {
  final _searchController = TextEditingController();

  Widget _buildStatusBadge(PurchaseStatus status) {
    Color badgeColor;
    String label;
    switch (status) {
      case PurchaseStatus.draft:
        badgeColor = Colors.grey;
        label = 'DRAFT';
        break;
      case PurchaseStatus.confirmed:
        badgeColor = Colors.blue;
        label = 'CONFIRMED';
        break;
      case PurchaseStatus.partiallyPaid:
        badgeColor = Colors.orange;
        label = 'PARTIALLY PAID';
        break;
      case PurchaseStatus.paid:
        badgeColor = const Color(0xFF2E7D32);
        label = 'PAID';
        break;
      case PurchaseStatus.cancelled:
        badgeColor = Colors.red;
        label = 'CANCELLED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final purchases = purchaseState.purchases;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(purchaseProvider.notifier).loadPurchases(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'Purchase Registers',
                description:
                    'Record incoming supplier bills, track debit notes, and manage payables balances.',
                breadcrumbs: const ['Dashboard', 'Purchase', 'Bills'],
                actions: [
                  AppButton(
                    label: 'Record Purchase',
                    icon: Icons.post_add_outlined,
                    onPressed: () async {
                      await context.push('/purchase/new');
                      if (mounted) {
                        ref.read(purchaseProvider.notifier).loadPurchases();
                      }
                    },
                  ),
                ],
              ),
              if (purchaseState.error != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    purchaseState.error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              AppCard(
                child: Column(
                  children: [
                    ResponsiveRow(
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            label: 'Search Purchase Bills',
                            hintText:
                                'Search by bill number, supplier invoice, or supplier name...',
                            controller: _searchController,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                      });
                                      ref
                                          .read(purchaseProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                  )
                                : null,
                            onChanged: (val) => ref
                                .read(purchaseProvider.notifier)
                                .setSearchQuery(val),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: AppDropdownField<String>(
                            label: 'Filter Status',
                            value: purchaseState.selectedStatusFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All Statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'Draft',
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: 'Confirmed',
                                child: Text('Confirmed'),
                              ),
                              DropdownMenuItem(
                                value: 'PartiallyPaid',
                                child: Text('Partially Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'Paid',
                                child: Text('Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'Cancelled',
                                child: Text('Cancelled'),
                              ),
                            ],
                            onChanged: (val) => ref
                                .read(purchaseProvider.notifier)
                                .setStatusFilter(val ?? 'All'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'All',
                              'Draft',
                              'Confirmed',
                              'PartiallyPaid',
                              'Paid',
                              'Cancelled',
                            ].map((status) {
                              final isSelected =
                                  purchaseState.selectedStatusFilter == status;
                              final displayLabel = status == 'PartiallyPaid'
                                  ? 'Partially Paid'
                                  : status;
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(displayLabel),
                                  selected: isSelected,
                                  selectedColor: isDark
                                      ? const Color(0xFF1E3A2F)
                                      : const Color(0xFFE8F5E9),
                                  checkmarkColor: const Color(0xFF2E7D32),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? const Color(0xFF2E7D32)
                                        : (isDark
                                              ? AppColors.textDarkSecondary
                                              : AppColors.textLightSecondary),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (selected) {
                                    if (selected) {
                                      ref
                                          .read(purchaseProvider.notifier)
                                          .setStatusFilter(status);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (purchaseState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      AppTable<Purchase>(
                        items: purchases,
                        emptyMessage:
                            'No purchase bills match the selected criteria.',
                        columns: [
                          TableColumnSpec<Purchase>(
                            label: 'Purchase No.',
                            cellBuilder: (pur) => InkWell(
                              onTap: () => context.push('/purchase/${pur.id}'),
                              child: Text(
                                pur.purchaseNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Supplier Invoice',
                            cellBuilder: (pur) => Text(
                              pur.supplierInvoiceNumber.isEmpty
                                  ? '-'
                                  : pur.supplierInvoiceNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Date',
                            cellBuilder: (pur) => Text(
                              '${pur.purchaseDate.day.toString().padLeft(2, '0')}/${pur.purchaseDate.month.toString().padLeft(2, '0')}/${pur.purchaseDate.year}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Supplier',
                            flex: 2,
                            cellBuilder: (pur) => Text(
                              pur.supplierName.isEmpty
                                  ? 'Unknown Supplier'
                                  : pur.supplierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Grand Total',
                            isNumeric: true,
                            cellBuilder: (pur) => Text(
                              '₹${pur.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Remaining Payable',
                            isNumeric: true,
                            cellBuilder: (pur) => Text(
                              '₹${pur.balanceAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    pur.balanceAmount > 0 &&
                                        pur.status != PurchaseStatus.cancelled
                                    ? Colors.red
                                    : const Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableColumnSpec<Purchase>(
                            label: 'Status',
                            cellBuilder: (pur) => _buildStatusBadge(pur.status),
                          ),
                        ],
                        mobileCardBuilder: (pur) {
                          final isDarkCard =
                              Theme.of(context).brightness == Brightness.dark;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/purchase/${pur.id}'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDarkCard
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkCard
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pur.purchaseNumber,
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDarkCard
                                                    ? AppColors.textDarkPrimary
                                                    : AppColors
                                                          .textLightPrimary,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(pur.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping_outlined,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Supplier: ${pur.supplierName.isEmpty ? "Unknown" : pur.supplierName}${pur.supplierInvoiceNumber.isNotEmpty ? " • Ref: ${pur.supplierInvoiceNumber}" : ""}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkCard
                                                ? AppColors.textDarkSecondary
                                                : AppColors.textLightSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${pur.purchaseDate.day.toString().padLeft(2, '0')}/${pur.purchaseDate.month.toString().padLeft(2, '0')}/${pur.purchaseDate.year}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Grand Total: ₹${pur.grandTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isDarkCard
                                                    ? AppColors.textDarkPrimary
                                                    : AppColors
                                                          .textLightPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              pur.balanceAmount > 0 &&
                                                      pur.status !=
                                                          PurchaseStatus
                                                              .cancelled
                                                  ? 'Payable Due: ₹${pur.balanceAmount.toStringAsFixed(2)}'
                                                  : (pur.status ==
                                                            PurchaseStatus
                                                                .cancelled
                                                        ? 'Cancelled'
                                                        : 'Fully Paid'),
                                              style: TextStyle(
                                                color:
                                                    pur.balanceAmount > 0 &&
                                                        pur.status !=
                                                            PurchaseStatus
                                                                .cancelled
                                                    ? Colors.red.shade700
                                                    : (pur.status ==
                                                              PurchaseStatus
                                                                  .cancelled
                                                          ? Colors.grey
                                                          : const Color(
                                                              0xFF2E7D32,
                                                            )),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
}
