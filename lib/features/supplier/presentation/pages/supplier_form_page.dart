import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class SupplierFormPage extends ConsumerStatefulWidget {
  final String? supplierId;
  const SupplierFormPage({super.key, this.supplierId});

  @override
  ConsumerState<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends ConsumerState<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _stateCodeController = TextEditingController(text: '27');
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _creditTermsController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0.0');
  final _supplierGroupController = TextEditingController(text: 'General');
  final _notesController = TextEditingController();

  bool _isRegistered = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.supplierId != null && widget.supplierId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplierDetails());
    }
  }

  void _loadSupplierDetails() {
    final stateRepo = ref.read(billingRepositoryProvider);
    final supp = stateRepo.suppliers.firstWhere((s) => s.id == widget.supplierId);

    _nameController.text = supp.name;
    _mobileController.text = supp.mobile;
    _emailController.text = supp.email;
    _addressController.text = supp.address;
    _stateController.text = supp.state;
    _stateCodeController.text = supp.stateCode;
    _gstinController.text = supp.gstin;
    _panController.text = supp.pan;
    _creditTermsController.text = supp.creditTerms.toString();
    _openingBalanceController.text = supp.openingBalance.toString();
    _supplierGroupController.text = supp.supplierGroup;
    _notesController.text = supp.notes;

    setState(() {
      _isRegistered = supp.gstin.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _creditTermsController.dispose();
    _openingBalanceController.dispose();
    _supplierGroupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final billingRepo = ref.read(billingRepositoryProvider.notifier);

      final supplier = Supplier(
        id: _isEdit ? widget.supplierId! : 'supp_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        gstin: _isRegistered ? _gstinController.text : '',
        pan: _panController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        address: _addressController.text,
        state: _stateController.text,
        stateCode: _stateCodeController.text,
        creditTerms: int.tryParse(_creditTermsController.text) ?? 0,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        currentBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        supplierGroup: _supplierGroupController.text,
        notes: _notesController.text,
      );

      if (_isEdit) {
        await billingRepo.updateSupplier(supplier);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Supplier updated successfully!');
          context.pop();
        }
      } else {
        await billingRepo.addSupplier(supplier);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Supplier created successfully!');
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Supplier' : 'Add Supplier'),
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
                    title: _isEdit ? 'Edit Vendor Profile' : 'New Supplier Profile',
                    description: 'Set up supplier business parameters and GST registry information.',
                    breadcrumbs: ['Dashboard', 'Suppliers', _isEdit ? 'Edit' : 'Add'],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'General Information',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Supplier Company Name *',
                          controller: _nameController,
                          validator: (val) => val == null || val.isEmpty ? 'Supplier name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppPhoneField(
                                label: 'Mobile Number',
                                controller: _mobileController,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Email Address',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return null;
                                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!regex.hasMatch(val)) return 'Enter a valid email address';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'GSTIN & Financial Identifiers',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          title: const Text('Registered under GST?'),
                          value: _isRegistered,
                          onChanged: (val) => setState(() => _isRegistered = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_isRegistered) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ResponsiveRow(
                            children: [
                              Expanded(
                                child: AppGstinField(
                                  label: 'GSTIN *',
                                  controller: _gstinController,
                                  validator: (val) {
                                    if (!_isRegistered) return null;
                                    if (val == null || val.isEmpty) return 'GSTIN is required for registered vendors';
                                    final regex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                                    if (!regex.hasMatch(val)) return 'Invalid GSTIN format (e.g. 27AADCA1234F1Z5)';
                                    return null;
                                  },
                                ),
                              ),
                              Expanded(
                                child: AppTextField(
                                  label: 'PAN (Optional)',
                                  controller: _panController,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: (val) {
                                    final upper = val.toUpperCase();
                                    if (upper != val) {
                                      _panController.value = _panController.value.copyWith(
                                        text: upper,
                                        selection: TextSelection.collapsed(offset: upper.length),
                                      );
                                    }
                                  },
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return null;
                                    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                                    if (!regex.hasMatch(val)) return 'Enter a valid 10-character PAN';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.sm),
                           AppTextField(
                            label: 'PAN (Optional)',
                            controller: _panController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: (val) {
                              final upper = val.toUpperCase();
                              if (upper != val) {
                                _panController.value = _panController.value.copyWith(
                                  text: upper,
                                  selection: TextSelection.collapsed(offset: upper.length),
                                );
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) return null;
                              final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                              if (!regex.hasMatch(val)) return 'Enter a valid 10-character PAN';
                              return null;
                            },
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Address & State Supply Code',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                  label: 'State Name *',
                                  controller: _stateController,
                                  validator: (val) => val == null || val.isEmpty ? 'State name is required' : null,
                                ),
                            ),
                            Expanded(
                              child: AppTextField(
                                  label: 'State Code (2 Digits) *',
                                  controller: _stateCodeController,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'State code is required';
                                    if (val.length != 2 || int.tryParse(val) == null) return 'Must be a 2-digit number';
                                    return null;
                                  },
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Supplier Warehouse/Office Address *',
                          controller: _addressController,
                          maxLines: 2,
                          validator: (val) => val == null || val.isEmpty ? 'Address is required' : null,
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Credit Terms & Balances',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Credit Period (Days)',
                                controller: _creditTermsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Opening Balance (₹)',
                                controller: _openingBalanceController,
                                keyboardType: TextInputType.number,
                                readOnly: _isEdit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Notes',
                          controller: _notesController,
                          maxLines: 2,
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
                              label: 'Save Profile',
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
