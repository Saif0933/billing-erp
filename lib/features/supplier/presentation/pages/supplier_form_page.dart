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
import '../providers/supplier_provider.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _gstinController.addListener(_onGstinChanged);
    _isEdit = widget.supplierId != null && widget.supplierId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadSupplierDetails());
    }
  }

  void _onGstinChanged() {
    final upper = _gstinController.text.toUpperCase().trim();
    if (upper.length == 15) {
      final stCode = upper.substring(0, 2);
      if (_stateCodeController.text.isEmpty || _stateCodeController.text == '27') {
        _stateCodeController.text = stCode;
      }
      if (_panController.text.isEmpty) {
        _panController.text = upper.substring(2, 12);
      }
    }
  }


  Future<void> _loadSupplierDetails() async {
    Supplier? supp;
    final supplierList = ref.read(supplierProvider).suppliers;
    for (final s in supplierList) {
      if (s.id == widget.supplierId) {
        supp = s;
        break;
      }
    }
    if (supp == null) {
      final billingList = ref.read(billingRepositoryProvider).suppliers;
      for (final s in billingList) {
        if (s.id == widget.supplierId) {
          supp = s;
          break;
        }
      }
    }

    // Direct fetch from backend API if not yet in memory
    if (supp == null &&
        widget.supplierId != null &&
        widget.supplierId!.isNotEmpty) {
      try {
        final api = ref.read(supplierApiServiceProvider);
        final detail = await api.getSupplierById(widget.supplierId!);
        supp = detail.supplier;
      } catch (_) {}
    }

    if (supp == null || !mounted) return;

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
      _isRegistered = supp!.gstin.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _gstinController.removeListener(_onGstinChanged);
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
      setState(() => _isSaving = true);

      final supplier = Supplier(
        id: _isEdit
            ? widget.supplierId!
            : '',
        name: _nameController.text.trim(),
        gstin: _isRegistered ? _gstinController.text.trim().toUpperCase() : '',
        pan: _panController.text.trim().toUpperCase(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        state: _stateController.text.trim(),
        stateCode: _stateCodeController.text.trim(),
        creditTerms: int.tryParse(_creditTermsController.text) ?? 0,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        currentBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        supplierGroup: _supplierGroupController.text.trim(),
        notes: _notesController.text.trim(),
      );

      try {
        final supplierNotifier = ref.read(supplierProvider.notifier);
        if (_isEdit) {
          await supplierNotifier.updateSupplier(supplier);
          if (mounted) {
            AppFeedback.showSnackbar(context,
                message: 'Supplier updated successfully!');
            context.pop();
          }
        } else {
          await supplierNotifier.addSupplier(supplier);
          if (mounted) {
            AppFeedback.showSnackbar(context,
                message: 'Supplier created successfully!');
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceAll('Exception:', '').trim();
          AppFeedback.showSnackbar(
            context,
            message: errorMsg.isNotEmpty ? errorMsg : 'Failed to save supplier.',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
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
                    title:
                        _isEdit ? 'Edit Vendor Profile' : 'New Supplier Profile',
                    description:
                        'Set up supplier business parameters, contact information, and GST registry details.',
                    breadcrumbs: [
                      'Dashboard',
                      'Suppliers',
                      _isEdit ? 'Edit' : 'Add'
                    ],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSaving)
                          const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: LinearProgressIndicator(),
                          ),
                        Text(
                          'General Information',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Supplier Company Name *',
                          controller: _nameController,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Supplier name is required'
                              : null,
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
                                  if (!regex.hasMatch(val.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'GSTIN & Financial Identifiers',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          title: const Text('Registered under GST?'),
                          value: _isRegistered,
                          onChanged: (val) =>
                              setState(() => _isRegistered = val),
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
                                    if (val == null || val.trim().isEmpty) {
                                      return 'GSTIN is required for registered vendors';
                                    }
                                    final regex = RegExp(
                                        r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                                    if (!regex.hasMatch(val.trim())) {
                                      return 'Invalid GSTIN format (e.g. 27AADCA1234F1Z5)';
                                    }
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
                                      _panController.value =
                                          _panController.value.copyWith(
                                        text: upper,
                                        selection: TextSelection.collapsed(
                                            offset: upper.length),
                                      );
                                    }
                                  },
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return null;
                                    final regex =
                                        RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                                    if (!regex.hasMatch(val.trim())) {
                                      return 'Enter a valid 10-character PAN';
                                    }
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
                                _panController.value =
                                    _panController.value.copyWith(
                                  text: upper,
                                  selection: TextSelection.collapsed(
                                      offset: upper.length),
                                );
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) return null;
                              final regex =
                                  RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                              if (!regex.hasMatch(val.trim())) {
                                return 'Enter a valid 10-character PAN';
                              }
                              return null;
                            },
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Address & State Supply Code',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'State Name *',
                                controller: _stateController,
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'State name is required'
                                        : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'State Code (2 Digits) *',
                                controller: _stateCodeController,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'State code is required';
                                  }
                                  if (val.trim().length != 2 ||
                                      int.tryParse(val.trim()) == null) {
                                    return 'Must be a 2-digit number';
                                  }
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
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Credit Terms & Balances',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.bold),
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
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Supplier Group / Category',
                                controller: _supplierGroupController,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Notes',
                                controller: _notesController,
                                maxLines: 1,
                              ),
                            ),
                          ],
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
                              label: _isSaving ? 'Saving...' : 'Save Profile',
                              isLoading: _isSaving,
                              onPressed: _isSaving ? null : _handleSave,
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
