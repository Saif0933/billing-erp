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
import '../providers/service_provider.dart';

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
  final _rateController = TextEditingController(text: '0.00');
  final _unitController = TextEditingController(text: 'Hour');
  final _discountController = TextEditingController(text: '0.00');
  final _incomeLedgerController = TextEditingController(text: 'Service Income');

  double _selectedGstRate = 18.0;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.serviceId != null && widget.serviceId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadServiceDetails());
    }
  }

  Future<void> _loadServiceDetails() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try finding in serviceProvider state
      final currentList = ref.read(serviceProvider).services;
      Service? found = currentList.where((s) => s.id == widget.serviceId).firstOrNull;

      // 2. Try finding in billingRepository
      if (found == null) {
        final billingState = ref.read(billingRepositoryProvider);
        found = billingState.services.where((s) => s.id == widget.serviceId).firstOrNull;
      }

      // 3. Fallback: Fetch directly from server API
      if (found == null && widget.serviceId != null) {
        found = await ref
            .read(serviceApiServiceProvider)
            .getServiceById(widget.serviceId!);
      }

      if (found != null && mounted) {
        _nameController.text = found.name;
        _codeController.text = found.code;
        _sacCodeController.text = found.sacCode;
        _descriptionController.text = found.description;
        _rateController.text = found.rate.toStringAsFixed(2);
        _unitController.text = found.unit.isNotEmpty ? found.unit : 'Hour';
        _discountController.text = found.discount.toStringAsFixed(2);
        _incomeLedgerController.text = found.incomeLedger.isNotEmpty
            ? found.incomeLedger
            : 'Service Income';
        setState(() {
          _selectedGstRate = found!.gstRate;
        });
      } else if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Service record not found on server.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Failed to load service details: ${e.toString().replaceAll('Exception:', '').trim()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final serviceNotifier = ref.read(serviceProvider.notifier);

    final service = Service(
      id: _isEdit ? widget.serviceId! : '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      sacCode: _sacCodeController.text.trim(),
      description: _descriptionController.text.trim(),
      rate: double.tryParse(_rateController.text.trim()) ?? 0.0,
      gstRate: _selectedGstRate,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : 'Hour',
      discount: double.tryParse(_discountController.text.trim()) ?? 0.0,
      incomeLedger: _incomeLedgerController.text.trim().isNotEmpty
          ? _incomeLedgerController.text.trim()
          : 'Service Income',
    );

    try {
      if (_isEdit) {
        await serviceNotifier.updateService(service);
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Service "${service.name}" updated successfully!',
          );
          context.pop();
        }
      } else {
        final created = await serviceNotifier.addService(service);
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Service "${created.name}" created successfully!',
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: e.toString().replaceAll('Exception:', '').trim(),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          title: _isEdit
                              ? 'Edit Service Item'
                              : 'New Service Master',
                          description:
                              'Set professional billing hourly/milestone rates, descriptions, and SAC codes.',
                          breadcrumbs: [
                            'Dashboard',
                            'Services',
                            _isEdit ? 'Edit' : 'Add',
                          ],
                        ),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Core Details',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                label: 'Service Name *',
                                hintText: 'e.g. Legal Consulting, Software Development',
                                controller: _nameController,
                                validator: (val) => val == null ||
                                        val.trim().isEmpty
                                    ? 'Service name is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Service Code',
                                      hintText: 'e.g. SRV-001 (auto-generated if empty)',
                                      controller: _codeController,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'SAC Tax Code *',
                                      hintText: 'e.g. 998311, 998221 (2-8 digits)',
                                      controller: _sacCodeController,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null ||
                                            val.trim().isEmpty) {
                                          return 'SAC code is required';
                                        }
                                        if (!RegExp(r'^[0-9]{2,8}$')
                                            .hasMatch(val.trim())) {
                                          return 'SAC code must be 2 to 8 digits';
                                        }
                                        return null;
                                      },
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
                                        return DropdownMenuItem(
                                          value: rate,
                                          child: Text(
                                              '${rate.toStringAsFixed(0)}% GST'),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(
                                          () => _selectedGstRate = val ?? 18.0),
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Billing Unit *',
                                      hintText: 'e.g. Hour, Day, Job, Month, NOS',
                                      controller: _unitController,
                                      validator: (val) => val == null ||
                                              val.trim().isEmpty
                                          ? 'Billing unit is required'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                'Rates & Ledger Mapping',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Standard Billing Rate (₹) *',
                                      hintText: '0.00',
                                      controller: _rateController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      validator: (val) {
                                        if (val == null ||
                                            val.trim().isEmpty) {
                                          return 'Standard rate is required';
                                        }
                                        final r =
                                            double.tryParse(val.trim());
                                        if (r == null || r < 0) {
                                          return 'Please enter a valid rate';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Standard Discount (%)',
                                      hintText: '0.00',
                                      controller: _discountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return null;
                                        }
                                        final d = double.tryParse(val.trim());
                                        if (d == null || d < 0 || d > 100) {
                                          return 'Discount must be 0 to 100%';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                label: 'Income Ledger Account Name',
                                hintText: 'Service Income',
                                controller: _incomeLedgerController,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                label: 'Description / Scope of Work',
                                hintText: 'Describe deliverables, terms, or scope...',
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
                                    onPressed: _isSaving
                                        ? null
                                        : () => context.pop(),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  AppButton(
                                    label: _isSaving
                                        ? 'Saving...'
                                        : (_isEdit
                                            ? 'Update Service'
                                            : 'Save Service'),
                                    icon: _isSaving
                                        ? null
                                        : (_isEdit
                                            ? Icons.save_outlined
                                            : Icons.check),
                                    onPressed:
                                        _isSaving ? null : _handleSave,
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
