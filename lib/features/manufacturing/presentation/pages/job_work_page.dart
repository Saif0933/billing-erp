/*
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

class JobWorkPage extends ConsumerStatefulWidget {
  const JobWorkPage({super.key});

  @override
  ConsumerState<JobWorkPage> createState() => _JobWorkPageState();
}

class _JobWorkPageState extends ConsumerState<JobWorkPage> {
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
    final orders = billing.jobWorkOrders.where((o) {
      if (_searchQuery.isEmpty) return true;
      return o.jobWorkerName.toLowerCase().contains(_searchQuery) ||
          o.rawMaterialName.toLowerCase().contains(_searchQuery) ||
          o.finishedProductName.toLowerCase().contains(_searchQuery);
    }).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Work Ledger Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search Job Work Orders (worker, material, finished good)',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: 'Send Materials to Job Worker',
                  icon: Icons.outbox,
                  onPressed: () => _showSendMaterialsDialog(context, billing.products),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppTable<JobWorkOrder>(
                  items: orders,
                  emptyMessage: 'No Job Work orders currently registered.',
                  columns: [
                    TableColumnSpec<JobWorkOrder>(
                      label: 'Worker Name',
                      cellBuilder: (o) => Text(o.jobWorkerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TableColumnSpec<JobWorkOrder>(
                      label: 'Material Out',
                      cellBuilder: (o) => Text('${o.quantitySent} Kg of ${o.rawMaterialName}'),
                    ),
                    TableColumnSpec<JobWorkOrder>(
                      label: 'Finished Good In',
                      cellBuilder: (o) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${o.expectedFinishedQuantity} expected of ${o.finishedProductName}'),
                          Text('Received: ${o.receivedFinishedQuantity} units', style: const TextStyle(fontSize: 11, color: Colors.green)),
                        ],
                      ),
                    ),
                    TableColumnSpec<JobWorkOrder>(
                      label: 'Status',
                      cellBuilder: (o) {
                        Color col = Colors.grey;
                        if (o.status == JobWorkStatus.completed) col = Colors.green;
                        if (o.status == JobWorkStatus.sent) col = Colors.blue;
                        if (o.status == JobWorkStatus.partiallyReceived) col = Colors.orange;

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
                    TableColumnSpec<JobWorkOrder>(
                      label: 'Actions',
                      cellBuilder: (o) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (o.status != JobWorkStatus.completed)
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.green),
                              tooltip: 'Receive Finished Goods & Log Scrap',
                              onPressed: () => _showReceiveDialog(context, o),
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

  void _showSendMaterialsDialog(BuildContext context, List<dynamic> products) {
    final workerController = TextEditingController();
    final qtySentController = TextEditingController(text: '50.0');
    final qtyExpectedController = TextEditingController(text: '80.0');
    final chargesController = TextEditingController(text: '1500.0');

    final rawProducts = products.where((p) => p.id.toString().contains('raw')).toList();
    final finishedProducts = products.where((p) => !p.id.toString().contains('raw')).toList();

    if (rawProducts.isEmpty || finishedProducts.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Need at least 1 raw and 1 finished product to dispatch job work.', isError: true);
      return;
    }

    String selectedRawId = rawProducts.first.id;
    String selectedFinishedId = finishedProducts.first.id;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dispatch Materials for Job Work'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Job Worker / Contractor Name *',
                      controller: workerController,
                    ),
                    const SizedBox(height: 12),
                    AppDropdownField<String>(
                      label: 'Select Raw Material to Dispatch *',
                      value: selectedRawId,
                      items: rawProducts.map((p) {
                        return DropdownMenuItem(value: p.id as String, child: Text(p.name as String));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRawId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Quantity to Send (Kg) *',
                      controller: qtySentController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
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
                    AppTextField(
                      label: 'Expected Finished Output Quantity *',
                      controller: qtyExpectedController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Expected Job Work Charges (₹) *',
                      controller: chargesController,
                      keyboardType: TextInputType.number,
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
                  label: 'Dispatch Material',
                  onPressed: () async {
                    if (workerController.text.trim().isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Please specify the contractor name.', isError: true);
                      return;
                    }

                    final double sentQty = double.tryParse(qtySentController.text.trim()) ?? 0.0;
                    final double expectedQty = double.tryParse(qtyExpectedController.text.trim()) ?? 0.0;
                    final double charges = double.tryParse(chargesController.text.trim()) ?? 0.0;

                    if (sentQty <= 0 || expectedQty <= 0) {
                      AppFeedback.showSnackbar(context, message: 'Quantities must be positive.', isError: true);
                      return;
                    }

                    final rawProd = rawProducts.firstWhere((p) => p.id == selectedRawId);
                    final finishedProd = finishedProducts.firstWhere((p) => p.id == selectedFinishedId);

                    final newOrder = JobWorkOrder(
                      id: 'jw_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'biz_01',
                      jobWorkerId: 'jw_worker_01',
                      jobWorkerName: workerController.text.trim(),
                      rawMaterialId: selectedRawId,
                      rawMaterialName: rawProd.name,
                      quantitySent: sentQty,
                      dateSent: DateTime.now(),
                      reference: 'JW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      expectedReturnDate: DateTime.now().add(const Duration(days: 14)),
                      finishedProductId: selectedFinishedId,
                      finishedProductName: finishedProd.name,
                      expectedFinishedQuantity: expectedQty,
                      receivedFinishedQuantity: 0.0,
                      scrapQuantity: 0.0,
                      jobWorkCharges: charges,
                      status: JobWorkStatus.sent,
                    );

                    await ref.read(billingRepositoryProvider.notifier).addJobWorkOrder(newOrder);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'Job Work dispatch registered. Raw material stock updated.');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiveDialog(BuildContext context, JobWorkOrder order) {
    final qtyRecvController = TextEditingController(
      text: (order.expectedFinishedQuantity - order.receivedFinishedQuantity).toStringAsFixed(2),
    );
    final scrapController = TextEditingController(text: '0.0');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Receive Job Work: ${order.reference}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Quantity Received *',
                controller: qtyRecvController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Scrap/Wastage Quantity (Kg)',
                controller: scrapController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Receive Goods',
              onPressed: () async {
                final double recvQty = double.tryParse(qtyRecvController.text.trim()) ?? 0.0;
                final double scrapQty = double.tryParse(scrapController.text.trim()) ?? 0.0;

                if (recvQty <= 0) {
                  AppFeedback.showSnackbar(context, message: 'Please enter a valid quantity received.', isError: true);
                  return;
                }

                await ref.read(billingRepositoryProvider.notifier).receiveJobWork(order.id, recvQty, scrapQty);
                Navigator.pop(ctx);
                AppFeedback.showSnackbar(context, message: 'Finished goods received and warehouse stock updated.');
              },
            ),
          ],
        );
      },
    );
  }
}
*/
