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
import '../providers/customer_provider.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final String? customerId; // Non-empty if editing
  const CustomerFormPage({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _stateCodeController = TextEditingController(text: '27');
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0.0');
  final _creditPeriodController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0.0');
  final _customerGroupController = TextEditingController(text: 'General');
  final _notesController = TextEditingController();

  static const List<String> _customerTypes = [
    'Retail',
    'Wholesale',
    'Corporate',
    'General',
  ];

  String _selectedType = 'Retail';
  bool _isRegistered = false;
  bool _isShippingSameAsBilling = true;
  bool _isEdit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customerId != null && widget.customerId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomerDetails());
    }
  }

  Future<void> _loadCustomerDetails() async {
    Customer? cust;
    final customerList = ref.read(customerProvider).customers;
    for (final c in customerList) {
      if (c.id == widget.customerId) {
        cust = c;
        break;
      }
    }
    if (cust == null) {
      final billingList = ref.read(billingRepositoryProvider).customers;
      for (final c in billingList) {
        if (c.id == widget.customerId) {
          cust = c;
          break;
        }
      }
    }

    // Direct fetch from backend API if not yet in memory
    if (cust == null && widget.customerId != null && widget.customerId!.isNotEmpty) {
      try {
        final api = ref.read(customerApiServiceProvider);
        final detail = await api.getCustomerById(widget.customerId!);
        cust = detail.customer;
      } catch (_) {}
    }

    if (cust == null || !mounted) return;

    final rawType = cust.type.trim();
    final loadedType = rawType.isNotEmpty ? rawType : 'Retail';

    _nameController.text = cust.name;
    _mobileController.text = cust.mobile;
    _emailController.text = cust.email;
    _billingAddressController.text = cust.billingAddress;
    _shippingAddressController.text = cust.shippingAddress;
    _stateController.text = cust.state;
    _stateCodeController.text = cust.stateCode;
    _gstinController.text = cust.gstin;
    _panController.text = cust.pan;
    _creditLimitController.text = cust.creditLimit.toString();
    _creditPeriodController.text = cust.creditPeriod.toString();
    _openingBalanceController.text = cust.openingBalance.toString();
    _customerGroupController.text = cust.customerGroup;
    _notesController.text = cust.notes;

    setState(() {
      _selectedType = loadedType;
      _isRegistered = cust!.isRegistered;
      _isShippingSameAsBilling = cust.billingAddress == cust.shippingAddress;
    });
  }

  List<DropdownMenuItem<String>> _buildTypeDropdownItems() {
    final types = {
      ..._customerTypes,
      if (_selectedType.isNotEmpty) _selectedType,
    };
    return types
        .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _creditLimitController.dispose();
    _creditPeriodController.dispose();
    _openingBalanceController.dispose();
    _customerGroupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final shipping = _isShippingSameAsBilling
          ? _billingAddressController.text
          : _shippingAddressController.text;

      final customer = Customer(
        id: _isEdit ? widget.customerId! : '',
        name: _nameController.text.trim(),
        type: _selectedType,
        gstin: _isRegistered ? _gstinController.text.trim().toUpperCase() : '',
        pan: _panController.text.trim().toUpperCase(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        billingAddress: _billingAddressController.text.trim(),
        shippingAddress: shipping.trim(),
        state: _stateController.text.trim(),
        stateCode: _stateCodeController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
        creditPeriod: int.tryParse(_creditPeriodController.text) ?? 0,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        currentBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        customerGroup: _customerGroupController.text.trim(),
        notes: _notesController.text.trim(),
        isRegistered: _isRegistered,
      );

      try {
        final customerNotifier = ref.read(customerProvider.notifier);
        if (_isEdit) {
          await customerNotifier.updateCustomer(customer);
          if (mounted) {
            AppFeedback.showSnackbar(context, message: 'Customer updated successfully!');
            context.pop();
          }
        } else {
          await customerNotifier.addCustomer(customer);
          if (mounted) {
            AppFeedback.showSnackbar(context, message: 'Customer created successfully!');
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceAll('Exception:', '').trim();
          AppFeedback.showSnackbar(
            context,
            message: errorMsg.isNotEmpty ? errorMsg : 'Failed to save customer.',
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
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer'),
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
                    title: _isEdit ? 'Edit Profile' : 'New Customer Profile',
                    description: 'Enter commercial and contact parameters for this customer entity.',
                    breadcrumbs: ['Dashboard', 'Customers', _isEdit ? 'Edit' : 'Add'],
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
                        ResponsiveRow(
                          children: [
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                label: 'Customer Name *',
                                controller: _nameController,
                                validator: (val) => val == null || val.isEmpty ? 'Customer name is required' : null,
                              ),
                            ),
                            Expanded(
                              child: AppDropdownField<String>(
                                label: 'Customer Type *',
                                value: _selectedType.isNotEmpty ? _selectedType : 'Retail',
                                items: _buildTypeDropdownItems(),
                                onChanged: (val) => setState(() => _selectedType = val ?? 'Retail'),
                              ),
                            ),
                          ],
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
                          'GSTIN & Legal Parameters',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          title: const Text('Registered under GST?'),
                          subtitle: const Text('Check this if the client has a GSTIN.'),
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
                                    if (val == null || val.isEmpty) return 'GSTIN is required for registered clients';
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
                          'Addresses & State Supply Code',
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
                          label: 'Billing Address *',
                          controller: _billingAddressController,
                          maxLines: 2,
                          validator: (val) => val == null || val.isEmpty ? 'Billing address is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CheckboxListTile(
                          title: const Text('Shipping address is same as billing address'),
                          value: _isShippingSameAsBilling,
                          onChanged: (val) => setState(() => _isShippingSameAsBilling = val ?? true),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (!_isShippingSameAsBilling) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            label: 'Shipping Address *',
                            controller: _shippingAddressController,
                            maxLines: 2,
                            validator: (val) {
                              if (!_isShippingSameAsBilling && (val == null || val.isEmpty)) {
                                return 'Shipping address is required';
                              }
                              return null;
                            },
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Credit & Opening Balances',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Credit Limit (₹)',
                                controller: _creditLimitController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Credit Period (Days)',
                                controller: _creditPeriodController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Opening Balance (₹)',
                                controller: _openingBalanceController,
                                keyboardType: TextInputType.number,
                                readOnly: _isEdit, // Cannot edit opening balance post-creation
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
                              label: _isSaving
                                  ? 'Saving...'
                                  : (_isEdit ? 'Update Profile' : 'Save Profile'),
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
