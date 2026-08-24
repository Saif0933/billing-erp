import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';

enum AppButtonType { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color getBgColor() {
      if (onPressed == null) {
        return isDark ? AppColors.borderDark : AppColors.borderLight;
      }
      switch (type) {
        case AppButtonType.primary:
          return isDark ? AppColors.accent : AppColors.primary;
        case AppButtonType.secondary:
          return isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9);
        case AppButtonType.outline:
        case AppButtonType.text:
          return Colors.transparent;
        case AppButtonType.danger:
          return AppColors.error;
      }
    }

    Color getTextColor() {
      if (onPressed == null) {
        return isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;
      }
      switch (type) {
        case AppButtonType.primary:
          return isDark ? AppColors.primary : Colors.white;
        case AppButtonType.secondary:
          return isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
        case AppButtonType.outline:
          return isDark ? AppColors.accent : AppColors.primary;
        case AppButtonType.text:
          return isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
        case AppButtonType.danger:
          return Colors.white;
      }
    }

    Border? getBorder() {
      if (type == AppButtonType.outline) {
        final color = onPressed == null
            ? (isDark ? AppColors.borderDark : AppColors.borderLight)
            : (isDark ? AppColors.accent : AppColors.primary);
        return Border.all(color: color, width: 1.5);
      }
      return null;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: getTextColor()),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: getTextColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: getBgColor(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smBorder,
          side: getBorder()?.top ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
