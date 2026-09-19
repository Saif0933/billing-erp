import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class PublicLegalTopHeader extends ConsumerWidget implements PreferredSizeWidget {
  const PublicLegalTopHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

    final buttonSize = isMobile ? 32.0 : 36.0;

    return SafeArea(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B132B) : AppColors.backgroundLight,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? const Color(0xFF1E2E4A).withValues(alpha: 0.5)
                  : AppColors.borderLight.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand Logo (app_icon.png) - No sidebar icon before it
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isAuthenticated) {
                  context.go('/dashboard');
                } else {
                  context.go('/login');
                }
              },
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Brand Title & Legal Portal Subtitle
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (isAuthenticated) {
                    context.go('/dashboard');
                  } else {
                    context.go('/login');
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TAX BUNNY',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Legal & Policy Center',
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Action: Direct Navigation (Back / Dashboard / Login)
            if (Navigator.of(context).canPop()) ...[
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 12,
                    vertical: isMobile ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: isMobile ? 14 : 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: isMobile ? 11.5 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Action Button: Get Started / Dashboard
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isAuthenticated) {
                  context.go('/dashboard');
                } else {
                  context.go('/login');
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 6 : 7.5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAuthenticated ? 'Dashboard' : 'Get Started',
                      style: TextStyle(
                        fontSize: isMobile ? 11.5 : 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isAuthenticated ? Icons.dashboard_rounded : Icons.arrow_forward_rounded,
                      size: isMobile ? 14 : 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
