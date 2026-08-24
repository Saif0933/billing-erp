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

class BOMPage extends ConsumerStatefulWidget {
  const BOMPage({super.key});

  @override
  ConsumerState<BOMPage> createState() => _BOMPageState();
}

class _BOMPageState extends ConsumerState<BOMPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    final boms = billing.boms.where((b) {
      if (_searchQuery.isEmpty) return true;
      return b.finishedProductName.toLowerCase().contains(_searchQuery) ||
          b.notes.toLowerCase().contains(_searchQuery) ||
          b.version.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill of Materials (BOM) Recipes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search BOM Recipes',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: 'Define New BOM',
                  icon: Icons.add,
                  onPressed: () => _showAddBOMDialog(context, billing.products),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppTable<BOM>(
                  items: boms,
                  emptyMessage: 'No BOM recipes defined yet.',
                  columns: [
                    TableColumnSpec<BOM>(
                      label: 'Finished Product',
                      cellBuilder: (bom) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bom.finishedProductName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('ID: ${bom.finishedProductId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    TableColumnSpec<BOM>(
                      label: 'Version',
                      cellBuilder: (bom) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bom.version,
                          style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableColumnSpec<BOM>(
                      label: 'Ingredient Count',
                      cellBuilder: (bom) => Text('${bom.items.length} raw materials'),
                    ),
                    TableColumnSpec<BOM>(
                      label: 'Description / Notes',
                      cellBuilder: (bom) => Text(bom.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    TableColumnSpec<BOM>(
                      label: 'Status',
                      cellBuilder: (bom) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bom.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bom.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            color: bom.isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TableColumnSpec<BOM>(
                      label: 'Actions',
                      cellBuilder: (bom) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Recipe Details',
                            onPressed: () => _viewBOMDetails(bom),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit BOM',
                            onPressed: () => _showEditBOMDialog(context, bom, billing.products),
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

  void _viewBOMDetails(BOM bom) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipe BOM: ${bom.finishedProductName} (${bom.version})'),
              if (bom.notes.isNotEmpty)
                Text(bom.notes, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 350,
            child: AppTable<BOMItem>(
              items: bom.items,
              emptyMessage: 'No ingredients defined in this recipe.',
              columns: [
                TableColumnSpec<BOMItem>(
                  label: 'Raw Material Name',
                  cellBuilder: (item) => Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TableColumnSpec<BOMItem>(
                  label: 'Quantity Required',
                  cellBuilder: (item) => Text('${item.quantity} ${item.unit}'),
                ),
                TableColumnSpec<BOMItem>(
                  label: 'Safety Wastage Margin',
                  cellBuilder: (item) => Text('${item.wastagePercentage}%'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddBOMDialog(BuildContext context, List<dynamic> products) {
    final versionController = TextEditingController(text: 'v1.0');
    final notesController = TextEditingController();

    final finishedProducts = products.where((p) => !p.id.toString().contains('raw')).toList();
    final rawProducts = products.where((p) => p.id.toString().contains('raw')).toList();

    if (finishedProducts.isEmpty || rawProducts.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Need at least 1 finished and 1 raw product in database to create BOM.', isError: true);
      return;
    }

    String selectedFinishedId = finishedProducts.first.id;
    List<Map<String, dynamic>> tempItems = [
      {'productId': rawProducts.first.id, 'quantity': 1.0, 'wastage': 0.0},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Define New BOM Recipe'),
              content: SizedBox(
                width: 700,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppDropdownField<String>(
                        label: 'Target Finished Good Output *',
                        value: selectedFinishedId,
                        items: finishedProducts.map((p) {
                          return DropdownMenuItem(value: p.id as String, child: Text(p.name as String));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedFinishedId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Version Code *',
                              controller: versionController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Recipe Description / Notes',
                              controller: notesController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ingredients (Raw Materials List)', style: TextStyle(fontWeight: FontWeight.bold)),
                          AppButton(
                            label: 'Add Raw Material',
                            icon: Icons.add,
                            type: AppButtonType.secondary,
                            onPressed: () {
                              setDialogState(() {
                                tempItems.add({
                                  'productId': rawProducts.first.id,
                                  'quantity': 1.0,
                                  'wastage': 0.0,
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(tempItems.length, (index) {
                        final item = tempItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppDropdownField<String>(
                                  label: 'Ingredient Product',
                                  value: item['productId'],
                                  items: rawProducts.map((p) {
                                    return DropdownMenuItem(value: p.id as String, child: Text(p.name as String));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => item['productId'] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Qty Required',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      item['quantity'] = double.tryParse(val) ?? 1.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Wastage %',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      item['wastage'] = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  if (tempItems.length <= 1) return;
                                  setDialogState(() => tempItems.removeAt(index));
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
                  label: 'Define BOM',
                  onPressed: () async {
                    if (versionController.text.isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Version is required.', isError: true);
                      return;
                    }

                    final finishedGood = finishedProducts.firstWhere((p) => p.id == selectedFinishedId);

                    final List<BOMItem> items = tempItems.map((item) {
                      final rawProd = rawProducts.firstWhere((p) => p.id == item['productId']);
                      return BOMItem(
                        productId: item['productId'],
                        productName: rawProd.name,
                        quantity: item['quantity'],
                        unit: 'Kg',
                        wastagePercentage: item['wastage'],
                      );
                    }).toList();

                    final newBom = BOM(
                      id: 'bom_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'biz_01',
                      finishedProductId: selectedFinishedId,
                      finishedProductName: finishedGood.name,
                      version: versionController.text.trim(),
                      items: items,
                      notes: notesController.text.trim(),
                      isActive: true,
                    );

                    await ref.read(billingRepositoryProvider.notifier).addBOM(newBom);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'BOM defined successfully!');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditBOMDialog(BuildContext context, BOM bom, List<dynamic> products) {
    final versionController = TextEditingController(text: bom.version);
    final notesController = TextEditingController(text: bom.notes);

    final rawProducts = products.where((p) => p.id.toString().contains('raw')).toList();

    List<Map<String, dynamic>> tempItems = bom.items.map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
        'wastage': item.wastagePercentage,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit BOM Recipe: ${bom.finishedProductName}'),
              content: SizedBox(
                width: 700,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Version Code *',
                              controller: versionController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Recipe Description / Notes',
                              controller: notesController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ingredients (Raw Materials List)', style: TextStyle(fontWeight: FontWeight.bold)),
                          AppButton(
                            label: 'Add Raw Material',
                            icon: Icons.add,
                            type: AppButtonType.secondary,
                            onPressed: () {
                              setDialogState(() {
                                tempItems.add({
                                  'productId': rawProducts.first.id,
                                  'quantity': 1.0,
                                  'wastage': 0.0,
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(tempItems.length, (index) {
                        final item = tempItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppDropdownField<String>(
                                  label: 'Ingredient Product',
                                  value: item['productId'],
                                  items: rawProducts.map((p) {
                                    return DropdownMenuItem(value: p.id as String, child: Text(p.name as String));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => item['productId'] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Qty Required',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      item['quantity'] = double.tryParse(val) ?? 1.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Wastage %',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      item['wastage'] = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  if (tempItems.length <= 1) return;
                                  setDialogState(() => tempItems.removeAt(index));
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
                  label: 'Save Changes',
                  onPressed: () async {
                    if (versionController.text.isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Version is required.', isError: true);
                      return;
                    }

                    final List<BOMItem> items = tempItems.map((item) {
                      final rawProd = rawProducts.firstWhere((p) => p.id == item['productId']);
                      return BOMItem(
                        productId: item['productId'],
                        productName: rawProd.name,
                        quantity: item['quantity'],
                        unit: 'Kg',
                        wastagePercentage: item['wastage'],
                      );
                    }).toList();

                    final updated = bom.copyWith(
                      version: versionController.text.trim(),
                      items: items,
                      notes: notesController.text.trim(),
                    );

                    await ref.read(billingRepositoryProvider.notifier).updateBOM(updated);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'BOM updated successfully!');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
