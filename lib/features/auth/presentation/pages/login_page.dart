import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../platform-admin/presentation/providers/platform_admin_provider.dart';
import '../providers/auth_provider.dart';

enum LoginPortalType { organization, platformAdmin }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  LoginPortalType _portalType = LoginPortalType.organization;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchPortal(LoginPortalType type) {
    setState(() {
      _portalType = type;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isSuperAdminTab = _portalType == LoginPortalType.platformAdmin;

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email,
          password,
          isPlatformAdminPortal: isSuperAdminTab,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        final authState = ref.read(authProvider);

        // If account is a Platform Administrator, always route to /platform-admin
        if (authState.isPlatformAdmin || isSuperAdminTab) {
          ref.read(platformAdminProvider.notifier).login(email, password);
          AppFeedback.showSnackbar(
            context,
            message: 'SuperAdmin Authenticated Successfully!',
          );
          context.go('/platform-admin');
          return;
        }

        // Standard tenant organization user
        await ref.read(businessProvider.notifier).loadBusinesses();
        if (!mounted) return;
        AppFeedback.showSnackbar(
          context,
          message: 'Welcome to Organization Portal!',
        );
        context.go('/dashboard');
      } else {
        final error = ref.read(authProvider).error ?? 'Authentication failed';
        AppFeedback.showSnackbar(context, message: error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuperAdmin = _portalType == LoginPortalType.platformAdmin;

    Widget formContent = Center(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Portal Mode Segmented Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _switchPortal(LoginPortalType.organization),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isSuperAdmin
                                ? (isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !isSuperAdmin
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.3 : 0.06,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 16,
                                color: !isSuperAdmin
                                    ? const Color(0xFF15803D)
                                    : (isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organization',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: !isSuperAdmin
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: !isSuperAdmin
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A))
                                      : (isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _switchPortal(LoginPortalType.platformAdmin),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSuperAdmin
                                ? const Color(0xFF4F46E5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isSuperAdmin
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4F46E5,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 16,
                                color: isSuperAdmin
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Platform Admin',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSuperAdmin
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSuperAdmin
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title & Subtitle based on selected portal
              Text(
                isSuperAdmin ? 'Platform Control Plane' : 'Organization Portal',
                style: AppTypography.headlineLarge.copyWith(
                  color: isSuperAdmin
                      ? const Color(0xFF4F46E5)
                      : (isDark ? Colors.white : AppColors.primary),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isSuperAdmin
                    ? 'Sign in to access global platform administration & multi-tenant operations'
                    : 'Sign in to access your business accounts, sales, GST & ledger',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Email Input
              AppTextField(
                label: isSuperAdmin ? 'SuperAdmin Email' : 'Work Email Address',
                hintText: isSuperAdmin
                    ? 'admin@platform-billing.com'
                    : 'name@business.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Password Input
              AppTextField(
                label: isSuperAdmin ? 'Master Password' : 'Password',
                hintText: '••••••••',
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              if (!isSuperAdmin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.accentLight
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),

              const SizedBox(height: AppSpacing.md),

              // Action Submit Button
              AppButton(
                label: isSuperAdmin
                    ? 'Sign In as SuperAdmin'
                    : 'Sign In to Organization',
                onPressed: _handleLogin,
                isLoading: _isLoading,
                icon: isSuperAdmin ? Icons.shield_outlined : Icons.login,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (isSuperAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have a SuperAdmin account?",
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        'Register here',
                        style: AppTypography.labelLarge.copyWith(
                          color: const Color(0xFF818CF8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Organization access is provisioned by your Platform Administrator.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Responsive(
        mobile: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: formContent,
        ),
        desktop: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: isSuperAdmin
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF090D16),
                            Color(0xFF1E1B4B),
                            Color(0xFF311042),
                          ],
                        )
                      : null,
                  color: !isSuperAdmin
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSuperAdmin ? Icons.shield_outlined : Icons.bolt,
                      size: 96,
                      color: isSuperAdmin
                          ? const Color(0xFF818CF8)
                          : AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isSuperAdmin ? 'PLATFORM ADMIN' : 'TAX BUNNY',
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        isSuperAdmin
                            ? 'Multi-Tenant Governance, SaaS Subscriptions & Cloud Operations'
                            : 'Simple for Business Owners. Powerful for Accountants.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 520,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: formContent,
            ),
          ],
        ),
      ),
    );
  }
}
