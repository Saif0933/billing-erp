import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/manufacturing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class ProductionOrdersPage extends ConsumerStatefulWidget {
  const ProductionOrdersPage({super.key});

  @override
  ConsumerState<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
}

class _ProductionOrdersPageState extends ConsumerState<ProductionOrdersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProductionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.manufacturing)) {
      return const LockedFeaturePage(featureName: 'Manufacturing Subsystem');
    }

    final billing = ref.watch(billingRepositoryProvider);
    final orders = billing.productionOrders.where((o) {
      if (_selectedStatus != null && o.status != _selectedStatus) return false;
      if (_searchQuery.isEmpty) return true;
      return o.productionNumber.toLowerCase().contains(_searchQuery) ||
          o.finishedProductName.toLowerCase().contains(_searchQuery);
    }).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Orders & Runs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search Production Orders (number, product)',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: AppDropdownField<ProductionStatus?>(
                    label: 'Filter by Status',
                    value: _selectedStatus,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...ProductionStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: 'New Production Order',
                  icon: Icons.add,
                  onPressed: () => _showCreateOrderDialog(context, billing.boms),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppTable<ProductionOrder>(
                  items: orders,
                  emptyMessage: 'No production orders defined yet.',
                  columns: [
                    TableColumnSpec<ProductionOrder>(
                      label: 'Run Number',
                      cellBuilder: (o) => Text(o.productionNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TableColumnSpec<ProductionOrder>(
                      label: 'Finished Product',
                      cellBuilder: (o) => Text(o.finishedProductName),
                    ),
                    TableColumnSpec<ProductionOrder>(
                      label: 'Target Qty',
                      cellBuilder: (o) => Text('${o.quantity} units'),
                    ),
                    TableColumnSpec<ProductionOrder>(
                      label: 'Status',
                      cellBuilder: (o) {
                        Color col = Colors.grey;
                        if (o.status == ProductionStatus.completed) col = Colors.green;
                        if (o.status == ProductionStatus.inProgress) col = Colors.blue;
                        if (o.status == ProductionStatus.cancelled) col = Colors.red;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: col.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.status.displayName.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                    TableColumnSpec<ProductionOrder>(
                      label: 'Total Cost',
                      isNumeric: true,
                      cellBuilder: (o) => Text(
                        o.status == ProductionStatus.completed ? '₹${o.totalCost.toStringAsFixed(2)}' : '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableColumnSpec<ProductionOrder>(
                      label: 'Actions',
                      cellBuilder: (o) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (o.status == ProductionStatus.draft)
                            IconButton(
                              icon: const Icon(Icons.play_arrow, color: Colors.blue),
                              tooltip: 'Start Production Run',
                              onPressed: () => _startRun(o),
                            ),
                          if (o.status == ProductionStatus.inProgress)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              tooltip: 'Complete Production & Account Cost',
                              onPressed: () => _showCompleteRunDialog(context, o),
                            ),
                          if (o.status != ProductionStatus.cancelled)
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                              tooltip: 'Cancel Production',
                              onPressed: () => _confirmCancelRun(o),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startRun(ProductionOrder order) async {
    try {
      await ref.read(billingRepositoryProvider.notifier).startProduction(order.id);
      AppFeedback.showSnackbar(context, message: 'Production run started successfully. Materials marked in progress.');
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Material Shortage Alert', style: TextStyle(color: Colors.red)),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showCreateOrderDialog(BuildContext context, List<BOM> boms) {
    if (boms.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Need at least 1 active BOM recipe defined to create production order.', isError: true);
      return;
    }

    String selectedBOMId = boms.first.id;
    final qtyController = TextEditingController(text: '100');
    final rawWarehouseController = TextEditingController(text: 'main');
    final finishedWarehouseController = TextEditingController(text: 'main');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeBOM = boms.firstWhere((b) => b.id == selectedBOMId);
            final double qty = double.tryParse(qtyController.text) ?? 0.0;

            final List<ProductionConsumptionItem> requirements = activeBOM.items.map((item) {
              final double requiredQty = item.quantity * qty;
              final double wastage = requiredQty * (item.wastagePercentage / 100.0);
              return ProductionConsumptionItem(
                productId: item.productId,
                productName: item.productName,
                quantityRequired: requiredQty + wastage,
                quantityConsumed: requiredQty + wastage,
                unit: item.unit,
              );
            }).toList();

            return AlertDialog(
              title: const Text('Create Production Order'),
              content: SizedBox(
                width: 600,
                height: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppDropdownField<String>(
                        label: 'Select BOM Recipe *',
                        value: selectedBOMId,
                        items: boms.map((b) {
                          return DropdownMenuItem(value: b.id, child: Text('${b.finishedProductName} (${b.version})'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedBOMId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Target Run Output Qty *',
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Raw Warehouse *',
                              controller: rawWarehouseController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Finished Warehouse *',
                              controller: finishedWarehouseController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estimated Materials Requirement (Inc. Wastage)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                      ),
                      const Divider(),
                      ...requirements.map((req) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(req.productName),
                              Text('${req.quantityRequired.toStringAsFixed(2)} Kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
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
                  label: 'Create Order',
                  onPressed: () async {
                    final double parsedQty = double.tryParse(qtyController.text.trim()) ?? 0.0;
                    if (parsedQty <= 0) {
                      AppFeedback.showSnackbar(context, message: 'Please specify a positive run quantity.', isError: true);
                      return;
                    }

                    final newOrder = ProductionOrder(
                      id: 'po_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'biz_01',
                      productionNumber: 'PRUN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      date: DateTime.now(),
                      finishedProductId: activeBOM.finishedProductId,
                      finishedProductName: activeBOM.finishedProductName,
                      bomId: activeBOM.id,
                      bomVersion: activeBOM.version,
                      quantity: parsedQty,
                      rawMaterialWarehouseId: rawWarehouseController.text.trim(),
                      warehouseId: finishedWarehouseController.text.trim(),
                      rawMaterialCost: 0.0,
                      laborCost: 0.0,
                      overheadCost: 0.0,
                      scrapValue: 0.0,
                      totalCost: 0.0,
                      status: ProductionStatus.draft,
                      notes: '',
                      consumedItems: requirements,
                      wastageItems: [],
                    );

                    await ref.read(billingRepositoryProvider.notifier).addProductionOrder(newOrder);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'Production order created in DRAFT status.');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompleteRunDialog(BuildContext context, ProductionOrder order) {
    double laborCost = 0.0;
    double overheadCost = 0.0;

    final List<TextEditingController> qtyControllers = order.consumedItems
        .map((item) => TextEditingController(text: item.quantityRequired.toStringAsFixed(2)))
        .toList();

    List<Map<String, dynamic>> wastageLines = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Complete Run: ${order.productionNumber}'),
              content: SizedBox(
                width: 700,
                height: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Actual Direct Labor Cost (₹) *',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                laborCost = double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Actual Factory Overheads (₹) *',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                overheadCost = double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Log Actual Consumption per Raw material', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...List.generate(order.consumedItems.length, (idx) {
                        final item = order.consumedItems[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(flex: 3, child: Text(item.productName)),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Qty Consumed (Kg)',
                                  controller: qtyControllers[idx],
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Scrap & Wastage Recovery Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                          AppButton(
                            label: 'Log Scrap/Wastage',
                            icon: Icons.add,
                            type: AppButtonType.secondary,
                            onPressed: () {
                              setDialogState(() {
                                wastageLines.add({
                                  'productId': order.consumedItems.first.productId,
                                  'quantity': 1.0,
                                  'type': 'WASTAGE',
                                  'reason': 'Normal wastage',
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(wastageLines.length, (index) {
                        final line = wastageLines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppDropdownField<String>(
                                  label: 'Product',
                                  value: line['productId'],
                                  items: order.consumedItems.map((item) {
                                    return DropdownMenuItem(value: item.productId, child: Text(item.productName));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => line['productId'] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Qty (Kg)',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      line['quantity'] = double.tryParse(val) ?? 1.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppDropdownField<String>(
                                  label: 'Wastage Type',
                                  value: line['type'],
                                  items: const [
                                    DropdownMenuItem(value: 'WASTAGE', child: Text('Normal Wastage')),
                                    DropdownMenuItem(value: 'SCRAP', child: Text('Recoverable Scrap')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => line['type'] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  label: 'Reason',
                                  hintText: 'e.g. Spillage',
                                  onChanged: (val) {
                                    setDialogState(() {
                                      line['reason'] = val;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() => wastageLines.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
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
                  label: 'Complete Production',
                  onPressed: () async {
                    try {
                      final List<ProductionConsumptionItem> actualConsumption = [];
                      for (int i = 0; i < order.consumedItems.length; i++) {
                        final item = order.consumedItems[i];
                        final double qty = double.tryParse(qtyControllers[i].text.trim()) ?? item.quantityRequired;
                        actualConsumption.add(item.copyWith(quantityConsumed: qty));
                      }

                      final List<ProductionWastageItem> wastageItems = wastageLines.map((line) {
                        final item = order.consumedItems.firstWhere((c) => c.productId == line['productId']);
                        return ProductionWastageItem(
                          productId: line['productId'],
                          productName: item.productName,
                          quantity: line['quantity'],
                          type: line['type'],
                          reason: line['reason'] ?? 'Normal wastage',
                        );
                      }).toList();

                      await ref.read(billingRepositoryProvider.notifier).completeProduction(
                            orderId: order.id,
                            laborCost: laborCost,
                            overheadCost: overheadCost,
                            actualConsumption: actualConsumption,
                            wastageItems: wastageItems,
                          );

                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(context, message: 'Production order completed. Double-entry posted.');
                    } catch (e) {
                      AppFeedback.showSnackbar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmCancelRun(ProductionOrder order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Production Order?'),
          content: Text('Are you sure you want to cancel run ${order.productionNumber}? All stocks and costing journal entries will be reversed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ref.read(billingRepositoryProvider.notifier).cancelProduction(order.id);
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: 'Production order cancelled and ledger changes reversed.');
                } catch (e) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
                }
              },
              child: const Text('Execute Cancellation', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
