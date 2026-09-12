import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../providers/business_provider.dart';

class BusinessSelectionPage extends ConsumerWidget {
  const BusinessSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessState = ref.watch(businessProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Business Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-business'),
            tooltip: 'Create New Business',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= Responsive.mobileMax;
          final isSmallMobile = constraints.maxWidth < 360;
          final hPadding = isSmallMobile
              ? 12.0
              : (isMobile ? 16.0 : AppSpacing.lg);
          final vPadding = isMobile ? 16.0 : AppSpacing.lg;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: vPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Switch Profile',
                        style: (isSmallMobile
                                ? AppTypography.titleLarge
                                : AppTypography.headlineMedium)
                            .copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Select the business entity you want to view and manage.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (businessState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: businessState.businesses.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final biz = businessState.businesses[index];
                            final isActive =
                                businessState.activeBusiness?.id == biz.id;

                            final initial = biz.name.isNotEmpty
                                ? biz.name.substring(0, 1).toUpperCase()
                                : 'B';
                            final gstinDisplay = biz.gstNumber.isNotEmpty
                                ? biz.gstNumber
                                : 'N/A';

                            return AppCard(
                              backgroundColor: isActive
                                  ? (isDark
                                      ? AppColors.accent.withValues(alpha: 0.1)
                                      : AppColors.primary.withValues(alpha: 0.05))
                                  : null,
                              border: Border.all(
                                color: isActive
                                    ? (isDark
                                        ? AppColors.accent
                                        : AppColors.primary)
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                                width: isActive ? 2 : 1,
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await ref
                                      .read(businessProvider.notifier)
                                      .switchBusiness(biz.id);
                                  if (context.mounted) {
                                    context.go('/dashboard');
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: isSmallMobile ? 18 : 20,
                                      backgroundColor: isDark
                                          ? AppColors.primaryLight
                                          : const Color(0xFFF1F5F9),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallMobile ? 13 : 14,
                                          color: isDark
                                              ? AppColors.accent
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width: isSmallMobile
                                            ? AppSpacing.sm
                                            : AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            biz.name,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Type: ${biz.type} • GSTIN: $gstinDisplay',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors.textDarkSecondary
                                                  : AppColors.textLightSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(
                                        Icons.check_circle,
                                        size: isSmallMobile ? 20 : 24,
                                        color: isDark
                                            ? AppColors.accent
                                            : AppColors.primary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Add New Business Profile',
                          onPressed: () => context.push('/create-business'),
                          type: AppButtonType.outline,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
