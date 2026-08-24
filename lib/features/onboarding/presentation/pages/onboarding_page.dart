import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/onboarding_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  String? _businessType = 'Retail';
  final _nameController = TextEditingController(text: 'My Business');
  final _legalNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _emailController = TextEditingController(text: 'info@mybusiness.com');
  final _phoneController = TextEditingController();
  
  final _addressController = TextEditingController(text: '123 Business Street');
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _pinController = TextEditingController(text: '400001');

  String? _gstRegType = 'Regular';
  final _invoicePrefix = TextEditingController(text: 'INV');
  final _invoiceStartNum = TextEditingController(text: '0001');

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _invoicePrefix.dispose();
    _invoiceStartNum.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 5) {
        setState(() => _currentStep++);
      } else {
        _submitOnboarding();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitOnboarding() async {
    await ref.read(businessProvider.notifier).createBusiness(
          name: _nameController.text,
          type: _businessType ?? 'Retail',
          gstNumber: _gstinController.text.isNotEmpty ? _gstinController.text : 'N/A',
        );

    await ref.read(onboardingProvider.notifier).completeOnboarding();
    
    if (mounted) {
      AppFeedback.showSnackbar(context, message: 'Onboarding completed successfully!');
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Business'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      AppButton(
                        label: 'Back',
                        onPressed: _prevStep,
                        type: AppButtonType.secondary,
                      )
                    else
                      const SizedBox.shrink(),
                    AppButton(
                      label: _currentStep == 5 ? 'Finish' : 'Next',
                      onPressed: _nextStep,
                      type: AppButtonType.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.accent : AppColors.primary;
    final inactiveColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Row(
      children: List.generate(6, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            color: isActive ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepBusinessType();
      case 1:
        return _buildStepBusinessInfo();
      case 2:
        return _buildStepBusinessAddress();
      case 3:
        return _buildStepFinancialSetup();
      case 4:
        return _buildStepInvoiceSetup();
      case 5:
        return _buildStepBranding();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepBusinessType() {
    final types = ['Service', 'Retail', 'Trading', 'Wholesale', 'Manufacturing'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Select Business Type', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('Choose the primary category that matches your operations.', style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        ...types.map((type) {
          final isSelected = _businessType == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RadioListTile<String>(
              title: Text(type, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              value: type,
              groupValue: _businessType,
              onChanged: (val) {
                setState(() => _businessType = val);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepBusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Business Information', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Business Name *',
          controller: _nameController,
          validator: (value) => value == null || value.isEmpty ? 'Business Name is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Legal Name', controller: _legalNameController),
        const SizedBox(height: AppSpacing.md),
        AppGstinField(label: 'GSTIN (Optional)', controller: _gstinController),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'PAN', controller: _panController),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Email', controller: _emailController),
        const SizedBox(height: AppSpacing.md),
        AppPhoneField(label: 'Mobile', controller: _phoneController),
      ],
    );
  }

  Widget _buildStepBusinessAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Addresses', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Primary Business Address *',
          controller: _addressController,
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty ? 'Address is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'State *',
          controller: _stateController,
          validator: (value) => value == null || value.isEmpty ? 'State is required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'PIN Code *',
          controller: _pinController,
          keyboardType: TextInputType.number,
          validator: (value) => value == null || value.isEmpty ? 'PIN Code is required' : null,
        ),
      ],
    );
  }

  Widget _buildStepFinancialSetup() {
    final regTypes = ['Regular', 'Composition', 'Unregistered'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Financial Setup', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        const AppTextField(
          label: 'Financial Year Starts From',
          readOnly: true,
          hintText: '01-04-2026',
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Books Commencing Date',
          readOnly: true,
          hintText: '01-04-2026',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdownField<String>(
          label: 'GST Registration Type',
          value: _gstRegType,
          items: regTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (val) => setState(() => _gstRegType = val),
        ),
      ],
    );
  }

  Widget _buildStepInvoiceSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5: Invoice Settings', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Invoice Prefix *', controller: _invoicePrefix),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Starting Number *', controller: _invoiceStartNum, keyboardType: TextInputType.number),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(label: 'Series Pattern', readOnly: true, hintText: 'PREFIX/YEAR/NUMBER'),
      ],
    );
  }

  Widget _buildStepBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 6: Business Branding & Payments', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        const Text('Upload Company Logo (Placeholder)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: const Center(
            child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(label: 'Bank Account Number', hintText: '1234567890'),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(label: 'IFSC Code', hintText: 'SBIN0000001'),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(label: 'UPI ID for QR Code', hintText: 'merchant@upi'),
      ],
    );
  }
}
