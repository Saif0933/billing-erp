import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/warehouse_models.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/services/feature_access_service.dart';
import '../providers/goods_warehouse_provider.dart';

class WarehousePage extends ConsumerStatefulWidget {
  const WarehousePage({super.key});

  @override
  ConsumerState<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends ConsumerState<WarehousePage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  String _srcWhId = 'main';
  String _destWhId = 'store';
  Product? _selectedProduct;
  List<TransferItem> _transferItems = [];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _qtyController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddWarehouseDialog({Warehouse? warehouse}) {
    if (warehouse != null) {
      _nameController.text = warehouse.name;
      _codeController.text = warehouse.code;
      _addressController.text = warehouse.address;
      _contactController.text = warehouse.contact;
    } else {
      _nameController.clear();
      _codeController.clear();
      _addressController.clear();
      _contactController.clear();
    }

    final isMobile = Responsive.isMobile(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            warehouse == null
                ? 'Add Warehouse Location'
                : 'Edit Warehouse Details',
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              minWidth: isMobile ? 280 : 420,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Warehouse Name *',
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Location Code * (e.g. WH-01)',
                    controller: _codeController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Street Address *',
                    controller: _addressController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Contact Phone *',
                    controller: _contactController,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Save Warehouse',
              onPressed: () async {
                if (_nameController.text.trim().isEmpty ||
                    _codeController.text.trim().isEmpty ||
                    _addressController.text.trim().isEmpty ||
                    _contactController.text.trim().isEmpty) {
                  AppFeedback.showSnackbar(
                    context,
                    message: 'Please fill in all fields!',
                    isError: true,
                  );
                  return;
                }

                final ok = await ref
                    .read(goodsWarehouseProvider.notifier)
                    .saveWarehouse(
                      existing: warehouse,
                      name: _nameController.text.trim(),
                      code: _codeController.text.trim(),
                      address: _addressController.text.trim(),
                      contact: _contactController.text.trim(),
                    );

                if (!ok) {
                  AppFeedback.showSnackbar(
                    context,
                    message: 'Failed to save warehouse. Please try again.',
                    isError: true,
                  );
                  return;
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message: 'Warehouse configuration saved successfully!',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addTransferItem() {
    if (_selectedProduct == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a product!',
        isError: true,
      );
      return;
    }
    final double qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) {
      AppFeedback.showSnackbar(
        context,
        message: 'Quantity must be positive!',
        isError: true,
      );
      return;
    }

    final item = TransferItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: qty,
    );
    setState(() {
      _transferItems = [..._transferItems, item];
      _selectedProduct = null;
      _qtyController.text = '1.0';
    });
  }

  void _submitTransfer() async {
    final warehouseState = ref.read(goodsWarehouseProvider);
    final billingState = ref.read(billingRepositoryProvider);
    final warehouses = (!warehouseState.isUsingLocalFallback &&
            warehouseState.domainWarehouses.isNotEmpty)
        ? warehouseState.domainWarehouses
        : billingState.warehouses;
    final sourceId = warehouses.any((w) => w.id == _srcWhId)
        ? _srcWhId
        : (warehouses.isNotEmpty ? warehouses.first.id : _srcWhId);
    final destId = warehouses.any((w) => w.id == _destWhId)
        ? _destWhId
        : (warehouses.length > 1
            ? warehouses[1].id
            : (warehouses.isNotEmpty ? warehouses.first.id : _destWhId));

    if (sourceId == destId) {
      AppFeedback.showSnackbar(
        context,
        message: 'Source and Destination Warehouses must be different!',
        isError: true,
      );
      return;
    }
    if (_transferItems.isEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'No items added to transfer list!',
        isError: true,
      );
      return;
    }
    if (_refController.text.trim().isEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please enter a reference number!',
        isError: true,
      );
      return;
    }

    final ok = await ref.read(goodsWarehouseProvider.notifier).recordTransfer(
          fromWarehouseId: sourceId,
          toWarehouseId: destId,
          referenceNumber: _refController.text.trim(),
          notes: _notesController.text.trim(),
          items: _transferItems,
        );

    if (!ok) {
      AppFeedback.showSnackbar(
        context,
        message: 'Failed to record stock transfer. Please try again.',
        isError: true,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _transferItems = [];
        _refController.clear();
        _notesController.clear();
      });
      AppFeedback.showSnackbar(
        context,
        message: 'Stock transfer confirmed and inventory mutated!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final warehouseState = ref.watch(goodsWarehouseProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);
    final warehouses = (!warehouseState.isUsingLocalFallback &&
            warehouseState.domainWarehouses.isNotEmpty)
        ? warehouseState.domainWarehouses
        : billingState.warehouses;
    final products = (!warehouseState.isUsingLocalFallback &&
            warehouseState.domainProducts.isNotEmpty)
        ? warehouseState.domainProducts
        : billingState.products;
    final stockTransfers = (!warehouseState.isUsingLocalFallback &&
            warehouseState.domainTransfers.isNotEmpty)
        ? warehouseState.domainTransfers
        : billingState.stockTransfers;
    final isMobile = Responsive.isMobile(context);
    final isMobileOrTablet = Responsive.isMobileOrTablet(context);
    final pagePadding = EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg);

    if (!featureAccess.canAccessWarehouse()) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 48, color: AppColors.warning),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Multi-Warehouse Locked',
                      style: AppTypography.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Upgrade to Premium or Enterprise plan to enable multi-location tracking and warehouse stock transfers.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Upgrade Subscription Now',
                      onPressed: () => context.go('/subscription'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isMobile ? 'Warehouses & Godowns' : 'Multi-Warehouse Control Center',
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.store, size: 20),
                text: isMobile ? 'Godowns' : 'Warehouse Locations',
              ),
              Tab(
                icon: const Icon(Icons.swap_horiz, size: 20),
                text: isMobile ? 'Transfer' : 'Record Stock Transfer',
              ),
              Tab(
                icon: const Icon(Icons.history, size: 20),
                text: isMobile ? 'History' : 'Transfer History Logs',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Locations List
            SingleChildScrollView(
              padding: pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Configured Godowns',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${warehouses.length} Active',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: isMobile ? 'Add New Godown' : 'Configure New Godown',
                          icon: Icons.add,
                          onPressed: () => _showAddWarehouseDialog(),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Configured Warehouses',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${warehouses.length} Active',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Configure New Godown',
                          icon: Icons.add,
                          onPressed: () => _showAddWarehouseDialog(),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: AppTable<Warehouse>(
                      items: warehouses,
                      emptyMessage: 'No warehouses configured yet.',
                      mobileCardBuilder: (w) => Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.store,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            w.name,
                                            style: AppTypography.titleSmall
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      w.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      w.address,
                                      style: AppTypography.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    w.contact,
                                    style: AppTypography.bodySmall,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Edit'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () =>
                                        _showAddWarehouseDialog(warehouse: w),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      columns: [
                        TableColumnSpec<Warehouse>(
                          label: 'Code',
                          cellBuilder: (w) => Text(
                            w.code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TableColumnSpec<Warehouse>(
                          label: 'Name',
                          flex: 2,
                          cellBuilder: (w) => Text(w.name),
                        ),
                        TableColumnSpec<Warehouse>(
                          label: 'Address',
                          flex: 2,
                          cellBuilder: (w) => Text(w.address),
                        ),
                        TableColumnSpec<Warehouse>(
                          label: 'Contact',
                          cellBuilder: (w) => Text(w.contact),
                        ),
                        TableColumnSpec<Warehouse>(
                          label: 'Actions',
                          cellBuilder: (w) => Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Details',
                                onPressed: () =>
                                    _showAddWarehouseDialog(warehouse: w),
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

            // Tab 2: Stock Transfer Entry
            SingleChildScrollView(
              padding: pagePadding,
              child: _buildTransferTab(
                context,
                warehouses,
                products,
                isMobile,
                isMobileOrTablet,
              ),
            ),

            // Tab 3: History Logs
            SingleChildScrollView(
              padding: pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isMobile
                              ? 'Stock Transfer History'
                              : 'Warehouse Stock Transfer History',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stockTransfers.length} Records',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: AppTable<StockTransfer>(
                      items: stockTransfers,
                      emptyMessage: 'No stock transfer logs recorded.',
                      mobileCardBuilder: (st) {
                        final fromName = warehouses
                                .where((w) => w.id == st.sourceWarehouseId)
                                .firstOrNull
                                ?.name ??
                            st.sourceWarehouseId;
                        final toName = warehouses
                                .where((w) => w.id == st.destinationWarehouseId)
                                .firstOrNull
                                ?.name ??
                            st.destinationWarehouseId;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.receipt_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          st.referenceNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        st.status.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'From Location',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              fromName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'To Location',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              toName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${st.transferDate.day}/${st.transferDate.month}/${st.transferDate.year}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${st.items.length} ${st.items.length == 1 ? 'item' : 'items'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (st.notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Note: ${st.notes}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      columns: [
                        TableColumnSpec<StockTransfer>(
                          label: 'Transfer Date',
                          cellBuilder: (st) => Text(
                            '${st.transferDate.day}/${st.transferDate.month}/${st.transferDate.year}',
                          ),
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'Ref Challan',
                          cellBuilder: (st) => Text(
                            st.referenceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'From Location',
                          cellBuilder: (st) {
                            final name = warehouses
                                    .where((w) => w.id == st.sourceWarehouseId)
                                    .firstOrNull
                                    ?.name ??
                                st.sourceWarehouseId;
                            return Text(name);
                          },
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'To Location',
                          cellBuilder: (st) {
                            final name = warehouses
                                    .where(
                                      (w) => w.id == st.destinationWarehouseId,
                                    )
                                    .firstOrNull
                                    ?.name ??
                                st.destinationWarehouseId;
                            return Text(name);
                          },
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'Status',
                          cellBuilder: (st) => Text(
                            st.status.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'Notes',
                          cellBuilder: (st) => Text(st.notes),
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
    );
  }

  Widget _buildTransferTab(
    BuildContext context,
    List<Warehouse> warehouses,
    List<Product> products,
    bool isMobile,
    bool isMobileOrTablet,
  ) {
    final sourceId = warehouses.any((w) => w.id == _srcWhId)
        ? _srcWhId
        : (warehouses.isNotEmpty ? warehouses.first.id : _srcWhId);
    final destId = warehouses.any((w) => w.id == _destWhId)
        ? _destWhId
        : (warehouses.length > 1
            ? warehouses[1].id
            : (warehouses.isNotEmpty ? warehouses.first.id : _destWhId));

    final configCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Transfer Configurations',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(),
          AppDropdownField<String>(
            label: 'Source Warehouse *',
            value: sourceId,
            items: warehouses.map((wh) {
              return DropdownMenuItem<String>(
                value: wh.id,
                child: Text(wh.name),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _srcWhId = val);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppDropdownField<String>(
            label: 'Destination Warehouse *',
            value: destId,
            items: warehouses.map((wh) {
              return DropdownMenuItem<String>(
                value: wh.id,
                child: Text(wh.name),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _destWhId = val);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Reference / Challan Number *',
            controller: _refController,
            hintText: 'e.g. TR-2026-001',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Notes / Remarks',
            controller: _notesController,
            hintText: 'e.g. Stock replenishment for retail front',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: isMobile
                ? 'Confirm Transfer'
                : 'Submit & Confirm Stock Transfer',
            icon: Icons.check_circle_outline,
            onPressed: _submitTransfer,
          ),
        ],
      ),
    );

    final itemsCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Add Items to Transfer',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_transferItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_transferItems.length} Added',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(),
          if (isMobile) ...[
            AppDropdownField<Product>(
              label: 'Select Product Item *',
              value: _selectedProduct,
              items: products.map((p) {
                final stock = p.warehouseStocks[sourceId] ?? 0.0;
                return DropdownMenuItem<Product>(
                  value: p,
                  child: Text(
                    '${p.name} (Avail: ${stock.toInt()})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (p) => setState(() => _selectedProduct = p),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'Qty *',
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AppButton(
                    label: 'Add Item',
                    icon: Icons.add,
                    onPressed: _addTransferItem,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 4,
                  child: AppDropdownField<Product>(
                    label: 'Select Product Item *',
                    value: _selectedProduct,
                    items: products.map((p) {
                      final stock = p.warehouseStocks[sourceId] ?? 0.0;
                      return DropdownMenuItem<Product>(
                        value: p,
                        child: Text(
                          '${p.name} (Avail: ${stock.toInt()})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Qty *',
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AppButton(
                    label: 'Add Item',
                    icon: Icons.add,
                    onPressed: _addTransferItem,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Transfer Items List',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_transferItems.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 26,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No items added yet. Select product and click Add.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transferItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = _transferItems[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity.toInt()} units',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            _transferItems = List.from(_transferItems)
                              ..removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    if (isMobileOrTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          configCard,
          const SizedBox(height: AppSpacing.md),
          itemsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: configCard,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 6,
          child: itemsCard,
        ),
      ],
    );
  }
}
