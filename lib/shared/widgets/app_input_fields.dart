import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textDarkPrimary
                : AppColors.textLightPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textDarkMuted
                  : AppColors.textLightMuted,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class AppCurrencyField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppCurrencyField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: const Icon(Icons.currency_rupee, size: 16),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class AppPhoneField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const AppPhoneField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: '98765 43210',
      keyboardType: TextInputType.phone,
      prefixIcon: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm + 4,
        ),
        child: Text('+91 ', style: TextStyle(fontSize: 14)),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return null;
            if (value.length != 10)
              return 'Enter a valid 10-digit mobile number';
            return null;
          },
    );
  }
}

class AppGstinField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const AppGstinField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: '27AADCA1234F1Z5',
      keyboardType: TextInputType.text,
      inputFormatters: [LengthLimitingTextInputFormatter(15)],
      onChanged: (val) {
        if (controller != null) {
          final upper = val.toUpperCase();
          if (upper != val) {
            controller!.value = controller!.value.copyWith(
              text: upper,
              selection: TextSelection.collapsed(offset: upper.length),
            );
          }
        }
      },
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return null;
            final regex = RegExp(
              r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$',
            );
            if (!regex.hasMatch(value)) {
              return 'Enter a valid 15-character GSTIN format';
            }
            return null;
          },
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textDarkPrimary
                : AppColors.textLightPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.smBorder,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
