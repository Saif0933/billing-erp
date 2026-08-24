import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt,
              size: 72,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'TAX BUNNY',
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Billing & Business Management',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
