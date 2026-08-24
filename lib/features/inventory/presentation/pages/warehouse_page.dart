import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/warehouse_models.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/domain/services/feature_access_service.dart';

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

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(warehouse == null ? 'Add Warehouse Location' : 'Edit Warehouse Details'),
          content: SingleChildScrollView(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Save Warehouse',
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _codeController.text.isEmpty ||
                    _addressController.text.isEmpty ||
                    _contactController.text.isEmpty) {
                  AppFeedback.showSnackbar(context, message: 'Please fill in all fields!', isError: true);
                  return;
                }

                if (warehouse == null) {
                  final newW = Warehouse(
                    id: 'wh_${DateTime.now().millisecondsSinceEpoch}',
                    name: _nameController.text,
                    code: _codeController.text,
                    address: _addressController.text,
                    contact: _contactController.text,
                  );
                  await ref.read(billingRepositoryProvider.notifier).addWarehouse(newW);
                } else {
                  final editW = warehouse.copyWith(
                    name: _nameController.text,
                    code: _codeController.text,
                    address: _addressController.text,
                    contact: _contactController.text,
                  );
                  await ref.read(billingRepositoryProvider.notifier).updateWarehouse(editW);
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: 'Warehouse configuration saved successfully!');
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
      AppFeedback.showSnackbar(context, message: 'Please select a product!', isError: true);
      return;
    }
    final double qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) {
      AppFeedback.showSnackbar(context, message: 'Quantity must be positive!', isError: true);
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
    if (_srcWhId == _destWhId) {
      AppFeedback.showSnackbar(context, message: 'Source and Destination Warehouses must be different!', isError: true);
      return;
    }
    if (_transferItems.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'No items added to transfer list!', isError: true);
      return;
    }
    if (_refController.text.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Please enter a reference number!', isError: true);
      return;
    }

    final transfer = StockTransfer(
      id: 'trans_${DateTime.now().millisecondsSinceEpoch}',
      sourceWarehouseId: _srcWhId,
      destinationWarehouseId: _destWhId,
      items: _transferItems,
      transferDate: DateTime.now(),
      referenceNumber: _refController.text,
      status: StockTransferStatus.confirmed,
      notes: _notesController.text,
    );

    await ref.read(billingRepositoryProvider.notifier).transferStock(transfer);

    if (mounted) {
      setState(() {
        _transferItems = [];
        _refController.clear();
        _notesController.clear();
      });
      AppFeedback.showSnackbar(context, message: 'Stock transfer confirmed and inventory mutated!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);

    if (!featureAccess.canAccessWarehouse()) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.md),
                  Text('Multi-Warehouse Locked', style: AppTypography.titleLarge),
                  const Text('Upgrade to Premium or Enterprise plan to enable multi-location tracking and warehouse stock transfers.'),
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
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Multi-Warehouse Control Center'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Warehouse Locations'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Record Stock Transfer'),
              Tab(icon: Icon(Icons.history), text: 'Transfer History Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Locations List
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Configured Warehouses', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
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
                      items: billingState.warehouses,
                      emptyMessage: 'No warehouses configured yet.',
                      columns: [
                        TableColumnSpec<Warehouse>(
                          label: 'Code',
                          cellBuilder: (w) => Text(w.code, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                onPressed: () => _showAddWarehouseDialog(warehouse: w),
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form config
                  Expanded(
                    flex: 4,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Transfer Configurations', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(),
                          AppDropdownField<String>(
                            label: 'Source Warehouse *',
                            value: _srcWhId,
                            items: billingState.warehouses.map((wh) {
                              return DropdownMenuItem(value: wh.id, child: Text(wh.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _srcWhId = val);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDropdownField<String>(
                            label: 'Destination Warehouse *',
                            value: _destWhId,
                            items: billingState.warehouses.map((wh) {
                              return DropdownMenuItem(value: wh.id, child: Text(wh.name));
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
                            label: 'Submit & Confirm Stock Transfer',
                            icon: Icons.check_circle_outline,
                            onPressed: _submitTransfer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Items builder
                  Expanded(
                    flex: 6,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Add Items to Transfer', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppDropdownField<Product>(
                                  label: 'Select Product Item *',
                                  value: _selectedProduct,
                                  items: billingState.products.map((p) {
                                    final stock = p.warehouseStocks[_srcWhId] ?? 0.0;
                                    return DropdownMenuItem(value: p, child: Text('${p.name} (Avail: ${stock.toInt()})'));
                                  }).toList(),
                                  onChanged: (p) => setState(() => _selectedProduct = p),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: AppTextField(
                                  label: 'Qty *',
                                  controller: _qtyController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: AppButton(
                                  label: 'Add',
                                  onPressed: _addTransferItem,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Transfer Items List', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          if (_transferItems.isEmpty)
                            const SizedBox(
                              height: 100,
                              child: Center(child: Text('No items added. Select product and click Add.')),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transferItems.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = _transferItems[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.productName),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${item.quantity.toInt()} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _transferItems = List.from(_transferItems)..removeAt(idx);
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
                    ),
                  ),
                ],
              ),
            ),

            // Tab 3: History Logs
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Warehouse Stock Transfer History', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: AppTable<StockTransfer>(
                      items: billingState.stockTransfers,
                      emptyMessage: 'No stock transfer logs recorded.',
                      columns: [
                        TableColumnSpec<StockTransfer>(
                          label: 'Transfer Date',
                          cellBuilder: (st) => Text('${st.transferDate.day}/${st.transferDate.month}/${st.transferDate.year}'),
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'Ref Challan',
                          cellBuilder: (st) => Text(st.referenceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'From Location',
                          cellBuilder: (st) {
                            final name = billingState.warehouses.firstWhere((w) => w.id == st.sourceWarehouseId).name;
                            return Text(name);
                          },
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'To Location',
                          cellBuilder: (st) {
                            final name = billingState.warehouses.firstWhere((w) => w.id == st.destinationWarehouseId).name;
                            return Text(name);
                          },
                        ),
                        TableColumnSpec<StockTransfer>(
                          label: 'Status',
                          cellBuilder: (st) => Text(
                            st.status.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
}
