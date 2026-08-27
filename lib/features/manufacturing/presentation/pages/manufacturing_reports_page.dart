import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/manufacturing_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class ManufacturingReportsPage extends ConsumerStatefulWidget {
  const ManufacturingReportsPage({super.key});

  @override
  ConsumerState<ManufacturingReportsPage> createState() => _ManufacturingReportsPageState();
}

class _ManufacturingReportsPageState extends ConsumerState<ManufacturingReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.manufacturing)) {
      return const LockedFeaturePage(featureName: 'Manufacturing Subsystem');
    }

    final billing = ref.watch(billingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturing Registers & Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Production Run Log', icon: Icon(Icons.precision_manufacturing)),
            Tab(text: 'Wastage & Scrap Register', icon: Icon(Icons.delete_outline)),
            Tab(text: 'Job Work Balances', icon: Icon(Icons.assignment_ind)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductionRunLogTab(billing.productionOrders),
          _buildWastageRegisterTab(billing.productionOrders, billing.jobWorkOrders),
          _buildJobWorkBalancesTab(billing.jobWorkOrders),
        ],
      ),
    );
  }

  Widget _buildProductionRunLogTab(List<ProductionOrder> productionOrders) {
    final completedRuns = productionOrders.where((o) => o.status == ProductionStatus.completed).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<ProductionOrder>(
        items: completedRuns,
        emptyMessage: 'No completed production runs registered in database.',
        columns: [
          TableColumnSpec<ProductionOrder>(
            label: 'Run Ref',
            cellBuilder: (o) => Text(o.productionNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Output Finished Good',
            cellBuilder: (o) => Text(o.finishedProductName),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Completed Date',
            cellBuilder: (o) => Text(o.date.toString().substring(0, 10)),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Quantity Output',
            cellBuilder: (o) => Text('${o.quantity} units'),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Material Cost',
            isNumeric: true,
            cellBuilder: (o) => Text('₹${o.rawMaterialCost.toStringAsFixed(2)}'),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Labor Cost',
            isNumeric: true,
            cellBuilder: (o) => Text('₹${o.laborCost.toStringAsFixed(2)}'),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Overheads',
            isNumeric: true,
            cellBuilder: (o) => Text('₹${o.overheadCost.toStringAsFixed(2)}'),
          ),
          TableColumnSpec<ProductionOrder>(
            label: 'Total Run Cost',
            isNumeric: true,
            cellBuilder: (o) => Text('₹${o.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildWastageRegisterTab(List<ProductionOrder> runs, List<JobWorkOrder> jobWorks) {
    final Map<String, Map<String, dynamic>> productWastageMap = {};

    for (var run in runs) {
      if (run.status == ProductionStatus.completed) {
        for (var wastage in run.wastageItems) {
          final prodId = wastage.productId;
          if (!productWastageMap.containsKey(prodId)) {
            productWastageMap[prodId] = {
              'name': wastage.productName,
              'wastageQty': 0.0,
              'scrapQty': 0.0,
            };
          }
          if (wastage.type == 'WASTAGE') {
            productWastageMap[prodId]!['wastageQty'] += wastage.quantity;
          } else {
            productWastageMap[prodId]!['scrapQty'] += wastage.quantity;
          }
        }
      }
    }

    for (var jw in jobWorks) {
      if (jw.scrapQuantity > 0) {
        final prodId = jw.rawMaterialId;
        if (!productWastageMap.containsKey(prodId)) {
          productWastageMap[prodId] = {
            'name': jw.rawMaterialName,
            'wastageQty': 0.0,
            'scrapQty': 0.0,
          };
        }
        productWastageMap[prodId]!['scrapQty'] += jw.scrapQuantity;
      }
    }

    final List<Map<String, dynamic>> items = productWastageMap.values.toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<Map<String, dynamic>>(
        items: items,
        emptyMessage: 'No wastage or scrap recovery logs found in system.',
        columns: [
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Raw Material Product',
            cellBuilder: (item) => Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Normal Wastage (Kg)',
            cellBuilder: (item) => Text('${(item['wastageQty'] as double).toStringAsFixed(2)} Kg'),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Recovered Scrap (Kg)',
            cellBuilder: (item) => Text('${(item['scrapQty'] as double).toStringAsFixed(2)} Kg', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Status Summary',
            cellBuilder: (item) {
              final scrap = item['scrapQty'] as double;
              return Text(scrap > 0 ? 'Recovery registered' : 'No scrap recovery');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobWorkBalancesTab(List<JobWorkOrder> jobWorks) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<JobWorkOrder>(
        items: jobWorks,
        emptyMessage: 'No active job work logs in database.',
        columns: [
          TableColumnSpec<JobWorkOrder>(
            label: 'Worker Name',
            cellBuilder: (jw) => Text(jw.jobWorkerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TableColumnSpec<JobWorkOrder>(
            label: 'Expected FG Output',
            cellBuilder: (jw) => Text('${jw.expectedFinishedQuantity} units of ${jw.finishedProductName}'),
          ),
          TableColumnSpec<JobWorkOrder>(
            label: 'Received FG',
            cellBuilder: (jw) => Text('${jw.receivedFinishedQuantity} units', style: const TextStyle(color: Colors.green)),
          ),
          TableColumnSpec<JobWorkOrder>(
            label: 'Outstanding FG Balance',
            cellBuilder: (jw) {
              final double outstanding = jw.expectedFinishedQuantity - jw.receivedFinishedQuantity;
              final col = outstanding > 0 ? Colors.orange : Colors.grey;
              return Text(
                '${outstanding.toStringAsFixed(2)} units pending',
                style: TextStyle(color: col, fontWeight: FontWeight.bold),
              );
            },
          ),
          TableColumnSpec<JobWorkOrder>(
            label: 'Accrued Charges',
            isNumeric: true,
            cellBuilder: (jw) => Text('₹${jw.jobWorkCharges.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
