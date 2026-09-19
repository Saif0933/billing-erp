import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../shared/layouts/widgets/public_legal_top_header.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/auth_provider.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  
  String? _selectedReason = 'Closing business / No longer needed';
  bool _isConfirmed = false;
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isDeletedSuccess = false;
  String _successMessage = '';

  final List<String> _reasons = [
    'Closing business / No longer needed',
    'Switching to another billing software',
    'Creating a new business account',
    'Temporary seasonal pause',
    'Feature or compliance limitation',
    'Other / Confidential reason',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isConfirmed) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please check the confirmation box to proceed with account deletion.',
        isError: true,
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Confirm dialog for high safety
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Final Deletion Confirmation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you absolutely sure you want to permanently delete the account for "$email"? All active sessions, business records, and POS data will be permanently deactivated.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Yes, Delete My Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldProceed != true) return;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(authApiServiceProvider);
      final response = await api.deleteAccount(
        email: email,
        password: password,
        reason: _selectedReason,
      );

      // If user is currently logged in, log them out from state
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();

      setState(() {
        _isLoading = false;
        _isDeletedSuccess = true;
        _successMessage = response['message']?.toString() ??
            'Your organization account and all associated data have been permanently deleted.';
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070D1E) : const Color(0xFFF8FAFC),
      appBar: const PublicLegalTopHeader(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
            vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _isDeletedSuccess
                ? _buildSuccessView(isDark)
                : _buildDeleteFormView(isDark, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Account Successfully Deleted',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _successMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Return to Login',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteFormView(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Danger Header Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'PUBLIC DATA DELETION PORTAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Title & Subtitle
            Text(
              'Delete Organization Account',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your organization login credentials to permanently delete your account, business records, and revoke all active sessions.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'What happens when you delete your account:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildImpactBullet(
                    'Workspace Deactivation: Your business profiles, stock records, and POS data will be permanently deactivated.',
                    isDark,
                  ),
                  _buildImpactBullet(
                    'Billing & Invoices: Access to past GST/Non-GST invoices and payment receipts will be terminated.',
                    isDark,
                  ),
                  _buildImpactBullet(
                    'Session Invalidation: All team members, cashiers, and active app sessions will be immediately signed out.',
                    isDark,
                  ),
                  _buildImpactBullet(
                    'Irreversible Action: This action cannot be undone once confirmed.',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Email Address Input
            AppTextField(
              label: 'Organization / Owner Email',
              hintText: 'name@business.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your registered email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Input
            AppTextField(
              label: 'Account Password',
              hintText: 'Enter your password to verify ownership',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              controller: _passwordController,
              obscureText: _isObscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Password is required to confirm account deletion';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Reason Dropdown
            Text(
              'Reason for Deletion (Optional)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D35) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _reasons.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirmation Checkbox
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _isConfirmed = !_isConfirmed),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isConfirmed,
                      activeColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _isConfirmed = val ?? false),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'I acknowledge that deleting my organization account is permanent and irreversible. All data, customer ledgers, and billing history will be permanently deactivated.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Danger Button
            AppButton(
              label: 'Permanently Delete Account',
              icon: Icons.delete_forever_rounded,
              type: AppButtonType.danger,
              isLoading: _isLoading,
              onPressed: _handleDeleteAccount,
            ),
            const SizedBox(height: AppSpacing.md),

            // Cancel / Return to Login
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(
                  'Cancel and Return to Login',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
