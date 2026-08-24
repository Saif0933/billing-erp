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

class ServicePage extends ConsumerStatefulWidget {
  const ServicePage({super.key});

  @override
  ConsumerState<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends ConsumerState<ServicePage> {
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
    final allServices = billingState.services;

    // Filter services
    final filteredServices = allServices.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.sacCode.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Master'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Services Directory',
              description: 'Manage professional consulting and logistics service items with SAC tax codes.',
              breadcrumbs: const ['Dashboard', 'Items', 'Services'],
              actions: [
                AppButton(
                  label: 'Add Service',
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.push('/services/new'),
                ),
              ],
            ),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Search Services',
                    hintText: 'Search by service name, code, or SAC...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTable<Service>(
                    items: filteredServices,
                    emptyMessage: 'No services found matching the search query.',
                    columns: [
                      TableColumnSpec<Service>(
                        label: 'Service Info',
                        flex: 2,
                        cellBuilder: (s) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Code: ${s.code} | SAC: ${s.sacCode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Billing Unit',
                        cellBuilder: (s) => Text(s.unit),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Standard Rate',
                        isNumeric: true,
                        cellBuilder: (s) => Text('₹${s.rate.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Discount (₹)',
                        isNumeric: true,
                        cellBuilder: (s) => Text('₹${s.discount.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<Service>(
                        label: 'GST Rate',
                        cellBuilder: (s) => Text('${s.gstRate.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<Service>(
                        label: 'Actions',
                        cellBuilder: (s) => IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => context.push('/services/edit/${s.id}'),
                        ),
                      ),
                    ],
                    mobileCardBuilder: (s) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(s.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => context.push('/services/edit/${s.id}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Code: ${s.code} • SAC: ${s.sacCode}'),
                          Text('Description: ${s.description}'),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rate: ₹${s.rate.toStringAsFixed(2)} per ${s.unit}'),
                              Text('GST Rate: ${s.gstRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
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
