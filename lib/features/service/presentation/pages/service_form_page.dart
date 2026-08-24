import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class ServiceFormPage extends ConsumerStatefulWidget {
  final String? serviceId;
  const ServiceFormPage({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends ConsumerState<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _sacCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController(text: '0.0');
  final _unitController = TextEditingController(text: 'Hour');
  final _discountController = TextEditingController(text: '0.0');
  final _incomeLedgerController = TextEditingController(text: 'Service Income');

  double _selectedGstRate = 18.0;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.serviceId != null && widget.serviceId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadServiceDetails());
    }
  }

  void _loadServiceDetails() {
    final stateRepo = ref.read(billingRepositoryProvider);
    final serv = stateRepo.services.firstWhere((s) => s.id == widget.serviceId);

    _nameController.text = serv.name;
    _codeController.text = serv.code;
    _sacCodeController.text = serv.sacCode;
    _descriptionController.text = serv.description;
    _rateController.text = serv.rate.toString();
    _unitController.text = serv.unit;
    _discountController.text = serv.discount.toString();
    _incomeLedgerController.text = serv.incomeLedger;

    setState(() {
      _selectedGstRate = serv.gstRate;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sacCodeController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _unitController.dispose();
    _discountController.dispose();
    _incomeLedgerController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final billingRepo = ref.read(billingRepositoryProvider.notifier);

      final service = Service(
        id: _isEdit ? widget.serviceId! : 'serv_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        code: _codeController.text,
        sacCode: _sacCodeController.text,
        description: _descriptionController.text,
        rate: double.tryParse(_rateController.text) ?? 0.0,
        gstRate: _selectedGstRate,
        unit: _unitController.text,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        incomeLedger: _incomeLedgerController.text,
      );

      if (_isEdit) {
        await billingRepo.updateService(service);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Service item updated successfully!');
          context.pop();
        }
      } else {
        await billingRepo.addService(service);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Service item created successfully!');
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Service' : 'Add Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    title: _isEdit ? 'Edit Service Item' : 'New Service Master',
                    description: 'Set professional billing hourly/milestone rates, descriptions, and SAC codes.',
                    breadcrumbs: ['Dashboard', 'Services', _isEdit ? 'Edit' : 'Add'],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service Core details', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Service Name *',
                          controller: _nameController,
                          validator: (val) => val == null || val.isEmpty ? 'Service name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Service Reference Code *',
                                controller: _codeController,
                                validator: (val) => val == null || val.isEmpty ? 'Reference code is required' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'SAC Tax Classification Code *',
                                controller: _sacCodeController,
                                validator: (val) => val == null || val.isEmpty ? 'SAC code is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppDropdownField<double>(
                                label: 'GST Tax Rate *',
                                value: _selectedGstRate,
                                items: gstRates.map((rate) {
                                  return DropdownMenuItem(value: rate, child: Text('${rate.toStringAsFixed(0)}%'));
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedGstRate = val ?? 18.0),
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Billing Unit * (e.g. Hour, Day, Job, Trip)',
                                controller: _unitController,
                                validator: (val) => val == null || val.isEmpty ? 'Billing unit is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text('Rates & Ledger Mapping', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Standard Billing Rate (₹) *',
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid rate' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Standard Discount (₹)',
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Income Ledger Account Name',
                          controller: _incomeLedgerController,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Description / Scope of Work',
                          controller: _descriptionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppButton(
                              label: 'Cancel',
                              type: AppButtonType.text,
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AppButton(
                              label: 'Save Service',
                              onPressed: _handleSave,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
