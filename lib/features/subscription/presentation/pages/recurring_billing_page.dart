import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/models/recurring_billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../domain/entities/subscription_models.dart';
import '../../domain/services/feature_access_service.dart';

class RecurringBillingPage extends ConsumerStatefulWidget {
  const RecurringBillingPage({super.key});

  @override
  ConsumerState<RecurringBillingPage> createState() =>
      _RecurringBillingPageState();
}

class _RecurringBillingPageState extends ConsumerState<RecurringBillingPage> {
  final _qtyController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  Product? _selectedProduct;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  List<InvoiceItem> _scheduleItems = [];

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addScheduleItem() {
    if (_selectedProduct == null) {
      AppFeedback.showSnackbar(context,
          message: 'Please select a product!', isError: true);
      return;
    }
    final double qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) {
      AppFeedback.showSnackbar(context,
          message: 'Quantity must be positive!', isError: true);
      return;
    }

    final p = _selectedProduct!;
    final item = InvoiceItem(
      id: 'rec_item_${DateTime.now().millisecondsSinceEpoch}',
      productId: p.id,
      serviceId: '',
      name: p.name,
      hsnSac: p.hsnCode,
      quantity: qty,
      unit: p.primaryUnit,
      rate: p.sellingPrice,
      discountPercentage: 0.0,
      discountAmount: 0.0,
      taxableValue: p.sellingPrice * qty,
      gstRate: p.gstRate,
      cgst: (p.sellingPrice * qty) * (p.gstRate / 200.0),
      sgst: (p.sellingPrice * qty) * (p.gstRate / 200.0),
      igst: 0.0,
      cess: 0.0,
    );

    setState(() {
      _scheduleItems = [..._scheduleItems, item];
      _selectedProduct = null;
      _qtyController.text = '1.0';
    });
  }

  void _submitSchedule() async {
    if (_selectedCustomer == null) {
      AppFeedback.showSnackbar(context,
          message: 'Please select a customer!', isError: true);
      return;
    }
    if (_scheduleItems.isEmpty) {
      AppFeedback.showSnackbar(context,
          message: 'Please add items to the schedule!', isError: true);
      return;
    }

    final schedule = RecurringSchedule(
      id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      items: _scheduleItems,
      frequency: _selectedFrequency,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      nextBillingDate: DateTime.now()
          .subtract(const Duration(hours: 1)), // Trigger immediately for demo
      status: RecurringScheduleStatus.active,
      paymentTerms: 'Net 30',
      notes: _notesController.text,
    );

    await ref
        .read(billingRepositoryProvider.notifier)
        .addRecurringSchedule(schedule);

    if (mounted) {
      setState(() {
        _scheduleItems = [];
        _selectedCustomer = null;
        _notesController.clear();
      });
      AppFeedback.showSnackbar(context,
          message: 'Recurring billing contract scheduled successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);

    if (!featureAccess.canAccess(SubscriptionFeature.reports)) {
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
                  Text('Recurring Billing Gated',
                      style: AppTypography.titleLarge),
                  const Text(
                      'Upgrade to Premium or Enterprise plan to configure automated recurring client invoice billing.'),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final leftFormCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'New Billing Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          AppDropdownField<Customer>(
            label: 'Client / Customer *',
            value: _selectedCustomer,
            items: billingState.customers.map((c) {
              return DropdownMenuItem(value: c, child: Text(c.name));
            }).toList(),
            onChanged: (c) => setState(() => _selectedCustomer = c),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<RecurringFrequency>(
            label: 'Cycle Frequency *',
            value: _selectedFrequency,
            items: RecurringFrequency.values.map((f) {
              return DropdownMenuItem(value: f, child: Text(f.displayName));
            }).toList(),
            onChanged: (f) {
              if (f != null) setState(() => _selectedFrequency = f);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Schedule Contract Notes',
            controller: _notesController,
            hintText: 'e.g. Monthly corporate flour delivery agreement',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Create Billing Schedule',
            icon: Icons.calendar_today,
            onPressed: _submitSchedule,
          ),
        ],
      ),
    );

    final rightCartCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.add_shopping_cart, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'Add Items to Contract',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppDropdownField<Product>(
                  label: 'Select Product *',
                  value: _selectedProduct,
                  items: billingState.products.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
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
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _addScheduleItem,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_scheduleItems.isEmpty)
            const SizedBox(
              height: 60,
              child: Center(
                  child: Text('No items added to contract.',
                      style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scheduleItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = _scheduleItems[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '₹${item.rate.toStringAsFixed(2)} x ${item.quantity.toInt()} units',
                      style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _scheduleItems = List.from(_scheduleItems)
                          ..removeAt(idx);
                      });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );

    final directoryCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.history, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'Active Billing Schedules Directory',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          AppTable<RecurringSchedule>(
            items: billingState.recurringSchedules,
            emptyMessage: 'No recurring billing schedules defined.',
            columns: [
              TableColumnSpec<RecurringSchedule>(
                label: 'Customer',
                cellBuilder: (rs) => Text(rs.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TableColumnSpec<RecurringSchedule>(
                label: 'Cycle',
                cellBuilder: (rs) => Text(rs.frequency.displayName),
              ),
              TableColumnSpec<RecurringSchedule>(
                label: 'Next Run Date',
                cellBuilder: (rs) => Text(
                    '${rs.nextBillingDate.day}/${rs.nextBillingDate.month}/${rs.nextBillingDate.year}'),
              ),
              TableColumnSpec<RecurringSchedule>(
                label: 'Status',
                cellBuilder: (rs) {
                  final isActive =
                      rs.status == RecurringScheduleStatus.active;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rs.status.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
              TableColumnSpec<RecurringSchedule>(
                label: 'Actions',
                cellBuilder: (rs) => Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pause_circle_outline, size: 20),
                      onPressed: () async {
                        final updated =
                            rs.copyWith(status: RecurringScheduleStatus.paused);
                        await ref
                            .read(billingRepositoryProvider.notifier)
                            .updateRecurringSchedule(updated);
                        if (context.mounted) {
                          AppFeedback.showSnackbar(context,
                              message: 'Subscription billing paused.');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final contentLayout = Responsive.isMobile(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftFormCard,
              const SizedBox(height: 16),
              rightCartCard,
              const SizedBox(height: 16),
              directoryCard,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: leftFormCard),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    rightCartCard,
                    const SizedBox(height: 16),
                    directoryCard,
                  ],
                ),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Billing Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled,
                color: Color(0xFF2E7D32), size: 24),
            tooltip: 'Simulate Scheduler Run',
            onPressed: () async {
              await ref
                  .read(billingRepositoryProvider.notifier)
                  .triggerRecurringBillingRun();
              if (mounted) {
                AppFeedback.showSnackbar(context,
                    message:
                        'Billing scheduler evaluated! Active invoices generated.');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: contentLayout,
      ),
    );
  }
}
