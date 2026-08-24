import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
          )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Switch Profile',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select the business entity you want to view and manage.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
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
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final biz = businessState.businesses[index];
                    final isActive = businessState.activeBusiness?.id == biz.id;

                    return AppCard(
                      backgroundColor: isActive
                          ? (isDark ? AppColors.accent.withOpacity(0.1) : AppColors.primary.withOpacity(0.05))
                          : null,
                      border: Border.all(
                        color: isActive
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isActive ? 2 : 1,
                      ),
                      child: InkWell(
                        onTap: () async {
                          await ref.read(businessProvider.notifier).switchBusiness(biz.id);
                          if (context.mounted) {
                            context.go('/dashboard');
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                              child: Text(
                                biz.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.accent : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    biz.name,
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Type: ${biz.type} • GSTIN: ${biz.gstNumber}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Icon(
                                Icons.check_circle,
                                color: isDark ? AppColors.accent : AppColors.primary,
                              ),
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
    );
  }
}
