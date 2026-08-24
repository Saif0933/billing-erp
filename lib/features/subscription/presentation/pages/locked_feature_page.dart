import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';

class LockedFeaturePage extends StatelessWidget {
  final String featureName;

  const LockedFeaturePage({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Restricted')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.lock_outline, size: 36, color: AppColors.warning),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Upgrade Plan to Access',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The "$featureName" module is not available on your current plan level. Please upgrade your business license to unlock full workflow tools.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'View Pricing Plans',
                  onPressed: () => context.push('/upgrade'),
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Back to Dashboard',
                  onPressed: () => context.go('/dashboard'),
                  type: AppButtonType.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
