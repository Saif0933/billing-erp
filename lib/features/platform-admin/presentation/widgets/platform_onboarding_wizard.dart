import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../onboarding/domain/models/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/models/platform_admin_models.dart';
import '../providers/platform_admin_provider.dart';

class PlatformOnboardingWizard extends ConsumerStatefulWidget {
  const PlatformOnboardingWizard({super.key});

  @override
  ConsumerState<PlatformOnboardingWizard> createState() =>
      _PlatformOnboardingWizardState();
}

class _PlatformOnboardingWizardState
    extends ConsumerState<PlatformOnboardingWizard> {
  int _currentStep = 0; // 0 to 6 (7 Steps)

  // Logo file state
  Uint8List? _logoBytes;
  String? _logoFileName;

  // Step 1 Controllers
  final _orgNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  String _orgType = 'Private Limited Company';
  final _panController = TextEditingController();
  String _businessNature = 'Retail Trading';
  final _doiController = TextEditingController();
  final _emailController = TextEditingController();
  final String _countryCode = '+91';
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  // Step 2 Controllers
  final _websiteController = TextEditingController();
  final _altPhoneController = TextEditingController();
  String _industry = 'Retail & Consumer Goods';

  // Step 3 Controllers
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _state = 'Maharashtra (27)';

  // Step 4 Controllers
  String _currency = 'INR - Indian Rupee (₹)';
  String _financialYear = '1st April - 31st March';
  bool _isGstRegistered = true;

  // Step 5 Controllers
  final _gstinController = TextEditingController();
  final _msmeController = TextEditingController();

  // Step 6 Controllers
  final _adminNameController = TextEditingController();
  final _adminRoleController = TextEditingController(text: 'Store Owner / MD');
  final _teamInvitesController = TextEditingController();

  @override
  void dispose() {
    _orgNameController.dispose();
    _tradeNameController.dispose();
    _panController.dispose();
    _doiController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _websiteController.dispose();
    _altPhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _msmeController.dispose();
    _adminNameController.dispose();
    _adminRoleController.dispose();
    _teamInvitesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 6) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await pickImageFile();
      if (picked != null) {
        setState(() {
          _logoBytes = picked.bytes;
          _logoFileName = picked.name;
        });
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Logo selected: ${picked.name}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Could not open file picker: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final onboardingState = ref.read(onboardingProvider);
    if (onboardingState.isLoading) return;

    final orgName = _orgNameController.text.trim();
    if (orgName.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Please enter Organization Name (Step 1)', isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid Organization Email (Step 1)', isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Please enter Mobile Number (Step 1)', isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final password = _passwordController.text.trim();
    if (password.length < 6) {
      AppFeedback.showSnackbar(context, message: 'Master Password must be at least 6 characters long (Step 1)', isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final confirmPassword = _confirmPasswordController.text.trim();
    if (password != confirmPassword) {
      AppFeedback.showSnackbar(context, message: 'Password and Confirm Password do not match (Step 1)', isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final adminName = _adminNameController.text.trim().isNotEmpty
        ? _adminNameController.text.trim()
        : orgName;

    final request = OnboardOrganizationRequest(
      organizationName: orgName,
      tradeName: _tradeNameController.text.trim().isNotEmpty
          ? _tradeNameController.text.trim()
          : null,
      organizationType: _orgType,
      businessNature: _businessNature,
      pan: _panController.text.trim().isNotEmpty
          ? _panController.text.trim().toUpperCase()
          : null,
      dateOfIncorporation: _doiController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      mobileNumber: _mobileController.text.trim(),
      password: _passwordController.text.trim(),
      website: _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
      altPhone: _altPhoneController.text.trim().isNotEmpty
          ? _altPhoneController.text.trim()
          : null,
      industry: _industry,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _state,
      pinCode: _pincodeController.text.trim(),
      currency: _currency,
      financialYearStart: _financialYear,
      isGstRegistered: _isGstRegistered,
      gstin: _isGstRegistered && _gstinController.text.trim().isNotEmpty
          ? _gstinController.text.trim().toUpperCase()
          : null,
      msmeNumber: _msmeController.text.trim().isNotEmpty
          ? _msmeController.text.trim()
          : null,
      adminName: adminName,
      adminRole: _adminRoleController.text.trim(),
      teamInvites: _teamInvitesController.text.trim().isNotEmpty
          ? _teamInvitesController.text
              .split(',')
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList()
          : [],
      planName: 'Growth',
      billingCycle: 'MONTHLY',
    );

    final result = await ref
        .read(onboardingProvider.notifier)
        .submitOnboarding(request);

    if (result != null) {
      final notifier = ref.read(platformAdminProvider.notifier);
      final newTenant = OrganizationTenant(
        id: result.businessId,
        name: result.businessName,
        code: result.businessName.replaceAll(RegExp(r'\s+'), '').toUpperCase().substring(0, result.businessName.length >= 4 ? 4 : result.businessName.length),
        domain: '${result.businessName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.billing-erp.in',
        gstin: result.gstin ?? '',
        contactPerson: result.adminUserName,
        contactEmail: result.adminUserEmail,
        contactPhone: result.mobileNumber,
        planId: 'plan_growth',
        planName: result.planName,
        status: TenantStatus.active,
        monthlySpend: 2499.0,
        totalInvoices: 0,
        activeUsersCount: 1,
        maxUsersLimit: 15,
        storageUsedGb: 0.1,
        storageLimitGb: 25.0,
        createdAt: DateTime.now(),
        renewalDate: DateTime.now().add(const Duration(days: 30)),
      );

      notifier.addTenant(newTenant);
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Organization "${result.businessName}" Successfully Onboarded & Saved in Database!',
        );
      }
    } else {
      if (mounted) {
        final errorMsg = ref.read(onboardingProvider).error ?? 'Could not complete onboarding. Please check your details.';
        AppFeedback.showSnackbar(
          context,
          message: errorMsg,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Navigation Bar
          _buildTopBar(isDark),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Main Body Layout (Centered Form Area with Zero-Overflow constraints)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: _buildRightFormCard(isDark),
              ),
            ),
          ),

          // Bottom Progress Banner Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: _buildProgressBanner(isDark),
              ),
            ),
          ),

          // Footer Copyright
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '© 2026 Tax Bunny Retail Store. All rights reserved.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Navigation Bar with Zero-Overflow LayoutBuilder ---
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          return Row(
            children: [
              // Green Lightning Bolt Logo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF15803D), size: 20),
              ),
              const SizedBox(width: 8),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _orgNameController.text.trim().isNotEmpty
                          ? _orgNameController.text.trim().toUpperCase()
                          : 'ORGANIZATION SETUP',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isNarrow)
                      Text(
                        _tradeNameController.text.trim().isNotEmpty
                            ? _tradeNameController.text.trim()
                            : 'New Tenant Onboarding',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Notification Bell with Badge (3)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),

              // Help Icon (Hide on very narrow mobile screens)
              if (!isNarrow) ...[
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8),
              ],

              // User Profile Pill with TS Avatar & Owner Role
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7),
                    child: const Text(
                      'TS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tax Bunny',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Right Main Form Card ---
  Widget _buildRightFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Icon + Title with Expanded to prevent yellow ribs
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.apartment, color: Color(0xFF15803D), size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStepTitle(_currentStep),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getStepSubtitle(_currentStep),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Green Information Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline, size: 15, color: Color(0xFF16A34A)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This information will be used to set up your organization in Tax Bunny.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Render Step Form Fields
          _buildStepFields(isDark),
          const SizedBox(height: 20),

          // Blue "Why do we need this information?" Info Box with Expanded bullets
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, size: 15, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Why do we need this information?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWhyBullet('To personalize your experience', isDark),
                _buildWhyBullet('To configure compliance and tax settings', isDark),
                _buildWhyBullet('To generate accurate invoices and reports', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: [ Back ] + [ Save & Continue -> ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 15),
                  label: const Text('Back', style: TextStyle(fontSize: 12)),
                  onPressed: ref.watch(onboardingProvider).isLoading ? null : _prevStep,
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D), // Exact green
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: ref.watch(onboardingProvider).isLoading && _currentStep == 6
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 6 ? 'Launch Organization' : 'Save & Continue',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                label: ref.watch(onboardingProvider).isLoading && _currentStep == 6
                    ? const SizedBox.shrink()
                    : const Icon(Icons.arrow_forward, size: 15, color: Colors.white),
                onPressed: ref.watch(onboardingProvider).isLoading ? null : _nextStep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhyBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 13, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1 to 7 Form Fields ---
  Widget _buildStepFields(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Fields(isDark);
      case 1:
        return _buildStep2Fields(isDark);
      case 2:
        return _buildStep3Fields(isDark);
      case 3:
        return _buildStep4Fields(isDark);
      case 4:
        return _buildStep5Fields(isDark);
      case 5:
        return _buildStep6Fields(isDark);
      case 6:
      default:
        return _buildStep7Review(isDark);
    }
  }

  // Step 1: Basic Information with Password fields under Email/Mobile
  Widget _buildStep1Fields(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Org Name & Trade Name
            if (isSmall) ...[
              _buildTextInput('Organization Name *', _orgNameController, isDark),
              const SizedBox(height: 12),
              _buildTextInput('Trade Name (Optional)', _tradeNameController, isDark),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextInput('Organization Name *', _orgNameController, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildTextInput('Trade Name (Optional)', _tradeNameController, isDark)),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Row 2: Organization Type & PAN Number
            if (isSmall) ...[
              _buildDropdownInput('Organization Type *', _orgType, [
                'Private Limited Company',
                'Sole Proprietorship',
                'Partnership Firm',
                'LLP',
                'Public Limited',
              ], (v) => setState(() => _orgType = v!), isDark),
              const SizedBox(height: 12),
              _buildTextInput('PAN Number *', _panController, isDark),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownInput('Organization Type *', _orgType, [
                      'Private Limited Company',
                      'Sole Proprietorship',
                      'Partnership Firm',
                      'LLP',
                      'Public Limited',
                    ], (v) => setState(() => _orgType = v!), isDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildTextInput('PAN Number *', _panController, isDark)),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Row 3: Business Nature & Date of Incorporation
            if (isSmall) ...[
              _buildDropdownInput('Business Nature *', _businessNature, [
                'Retail Trading',
                'Wholesale Trading',
                'Manufacturing',
                'Services & Consulting',
                'E-Commerce',
              ], (v) => setState(() => _businessNature = v!), isDark),
              const SizedBox(height: 12),
              _buildTextInput('Date of Incorporation / Establishment *', _doiController, isDark, suffixIcon: Icons.calendar_today_outlined),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownInput('Business Nature *', _businessNature, [
                      'Retail Trading',
                      'Wholesale Trading',
                      'Manufacturing',
                      'Services & Consulting',
                      'E-Commerce',
                    ], (v) => setState(() => _businessNature = v!), isDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextInput('Date of Incorporation / Establishment *', _doiController, isDark, suffixIcon: Icons.calendar_today_outlined),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Row 4: Email Address & Mobile Number
            if (isSmall) ...[
              _buildTextInput('Email Address *', _emailController, isDark),
              const SizedBox(height: 12),
              _buildPhoneInput(isDark),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextInput('Email Address *', _emailController, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildPhoneInput(isDark)),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Row 4b: Password & Confirm Password (NEW - under Email)
            if (isSmall) ...[
              _buildPasswordInput('Admin Password *', _passwordController, isDark),
              const SizedBox(height: 12),
              _buildPasswordInput('Confirm Password *', _confirmPasswordController, isDark),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildPasswordInput('Admin Password *', _passwordController, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildPasswordInput('Confirm Password *', _confirmPasswordController, isDark)),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Row 5: Upload Logo & Logo Preview
            if (isSmall) ...[
              _buildUploadLogoBox(isDark),
              const SizedBox(height: 12),
              _buildLogoPreviewBox(isDark),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildUploadLogoBox(isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildLogoPreviewBox(isDark)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // Upload Logo Dashed Box
  Widget _buildUploadLogoBox(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Logo (Optional)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickLogo,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 125,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _logoBytes != null
                      ? const Color(0xFF15803D)
                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  style: BorderStyle.solid,
                  width: _logoBytes != null ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: _logoFileName != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 26, color: Color(0xFF15803D)),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _logoFileName!,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF15803D),
                              side: const BorderSide(color: Color(0xFF15803D)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _pickLogo,
                            child: const Text('Change Logo', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 22, color: Color(0xFF15803D)),
                          const SizedBox(height: 4),
                          Text(
                            'Drag & drop your logo here or',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF15803D),
                              side: const BorderSide(color: Color(0xFF15803D)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _pickLogo,
                            child: const Text('Browse File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PNG, JPG or JPEG (Max. 2MB)',
                            style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Logo Preview Box
  Widget _buildLogoPreviewBox(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo Preview',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 125,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_logoBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _logoBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.bolt, color: Color(0xFF15803D), size: 32),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _orgNameController.text.trim().isNotEmpty
                            ? _orgNameController.text.trim().toUpperCase()
                            : 'YOUR ORGANIZATION',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _tradeNameController.text.trim().isNotEmpty
                            ? _tradeNameController.text.trim()
                            : 'Trade Name / Brand',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Phone input with +91 Country Code Box
  Widget _buildPhoneInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Text(_countryCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, size: 14),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _mobileController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Password Input Field
  Widget _buildPasswordInput(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  // Generic Text Input with Label
  Widget _buildTextInput(String label, TextEditingController controller, bool isDark, {IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  // Generic Dropdown Input
  Widget _buildDropdownInput(String label, String value, List<String> options, ValueChanged<String?> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          ),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Step 2: Business Details
  Widget _buildStep2Fields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextInput('Official Website URL', _websiteController, isDark),
        const SizedBox(height: 12),
        _buildTextInput('Alternate Phone / Landline', _altPhoneController, isDark),
        const SizedBox(height: 12),
        _buildDropdownInput('Industry Vertical', _industry, [
          'Retail & Consumer Goods',
          'FMCG & Groceries',
          'Apparel & Fashion',
          'Electronics & Hardware',
          'Pharma & Healthcare',
        ], (v) => setState(() => _industry = v!), isDark),
      ],
    );
  }

  // Step 3: Address Details
  Widget _buildStep3Fields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextInput('Registered Address Line 1 *', _addressLine1Controller, isDark),
        const SizedBox(height: 12),
        _buildTextInput('Address Line 2 (Optional)', _addressLine2Controller, isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextInput('City / District *', _cityController, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextInput('Postal PIN Code *', _pincodeController, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdownInput('State & State Code *', _state, [
          'Maharashtra (27)',
          'Delhi (07)',
          'Karnataka (29)',
          'Gujarat (24)',
          'Tamil Nadu (33)',
        ], (v) => setState(() => _state = v!), isDark),
      ],
    );
  }

  // Step 4: Financial Settings
  Widget _buildStep4Fields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownInput('Base Currency *', _currency, [
          'INR - Indian Rupee (₹)',
          'USD - US Dollar (\$)',
          'EUR - Euro (€)',
          'AED - UAE Dirham',
        ], (v) => setState(() => _currency = v!), isDark),
        const SizedBox(height: 12),
        _buildDropdownInput('Financial Year Cycle *', _financialYear, [
          '1st April - 31st March',
          '1st January - 31st December',
        ], (v) => setState(() => _financialYear = v!), isDark),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('GST Registered Business', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Enable GST invoicing, E-Way bills & GSTR returns', style: TextStyle(fontSize: 11)),
          value: _isGstRegistered,
          onChanged: (v) => setState(() => _isGstRegistered = v),
          activeTrackColor: const Color(0xFFDCFCE7),
          activeThumbColor: const Color(0xFF15803D),
        ),
      ],
    );
  }

  // Step 5: Compliance Details
  Widget _buildStep5Fields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextInput('GSTIN (15-Digit Goods & Services Tax Number) *', _gstinController, isDark),
        const SizedBox(height: 12),
        _buildTextInput('MSME / Udyam Registration Number (Optional)', _msmeController, isDark),
      ],
    );
  }

  // Step 6: User Setup
  Widget _buildStep6Fields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextInput('Primary Admin Name *', _adminNameController, isDark),
        const SizedBox(height: 12),
        _buildTextInput('Admin Designation / Role *', _adminRoleController, isDark),
        const SizedBox(height: 12),
        _buildTextInput('Invite Team Members (Comma-separated emails)', _teamInvitesController, isDark),
      ],
    );
  }

  // Step 7: Review & Confirm
  Widget _buildStep7Review(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Organization', _orgNameController.text, isDark),
              _buildReviewRow('Trade Name', _tradeNameController.text, isDark),
              _buildReviewRow('PAN Number', _panController.text, isDark),
              _buildReviewRow('GSTIN', _gstinController.text, isDark),
              _buildReviewRow('Admin Contact', '${_adminNameController.text} (${_emailController.text})', isDark),
              _buildReviewRow('Location', '${_cityController.text}, $_state', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Progress Banner ---
  Widget _buildProgressBanner(bool isDark) {
    final int progressPercent = (((_currentStep + 1) / 7) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 650;

          final leftInfo = Row(
            children: [
              // Storefront Building Icon Illustration
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.storefront_outlined, size: 24, color: Color(0xFF15803D)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You're just a few steps away!",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete the onboarding process and start managing your business seamlessly.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final rightProgress = SizedBox(
            width: isSmall ? double.infinity : 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 7,
                          minHeight: 6,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progressPercent% Completed',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftInfo,
                const SizedBox(height: 12),
                rightProgress,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: leftInfo),
              const SizedBox(width: 20),
              rightProgress,
            ],
          );
        },
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Business Details';
      case 2:
        return 'Address Details';
      case 3:
        return 'Financial Settings';
      case 4:
        return 'Compliance Details';
      case 5:
        return 'User Setup';
      case 6:
      default:
        return 'Review & Confirm';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Enter basic details about your organization';
      case 1:
        return 'Configure contact channels and website';
      case 2:
        return 'Enter registered and billing premises';
      case 3:
        return 'Set accounting currency and FY period';
      case 4:
        return 'Verify GSTIN and tax compliance';
      case 5:
        return 'Assign root administrator and invite staff';
      case 6:
      default:
        return 'Review all entered organization details';
    }
  }
}
