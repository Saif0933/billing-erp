import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import 'app_button.dart';

class AppFeedback {
  AppFeedback._();

  static void showSnackbar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      backgroundColor: isError ? AppColors.error : AppColors.success,
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: const Duration(seconds: 4),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          title: Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          actions: [
            AppButton(
              label: cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
              type: AppButtonType.text,
            ),
            AppButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
              type: isDanger ? AppButtonType.danger : AppButtonType.primary,
            ),
          ],
        );
      },
    );
  }

  static void showBottomSheet(
    BuildContext context, {
    required Widget child,
    required String title,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        );
      },
    );
  }
}
