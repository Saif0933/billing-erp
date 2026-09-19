import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/utils/global_search.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/business/presentation/providers/business_provider.dart';
import '../../../../features/dashboard/presentation/providers/billing_repository.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';

class ResponsiveTopHeader extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ResponsiveTopHeader({super.key, required this.scaffoldKey});

  @override
  ConsumerState<ResponsiveTopHeader> createState() =>
      _ResponsiveTopHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _ResponsiveTopHeaderState extends ConsumerState<ResponsiveTopHeader> {
  final _searchRepo = SearchRepository();

  (IconData, Color, String) _getCategoryStyle(SearchCategory category) {
    switch (category) {
      case SearchCategory.navigation:
        return (Icons.explore_rounded, const Color(0xFF3B82F6), 'PAGE');
      case SearchCategory.customers:
        return (Icons.people_alt_rounded, const Color(0xFF10B981), 'CUSTOMER');
      case SearchCategory.suppliers:
        return (Icons.local_shipping_rounded, const Color(0xFF8B5CF6), 'SUPPLIER');
      case SearchCategory.products:
        return (Icons.inventory_2_rounded, const Color(0xFFF59E0B), 'PRODUCT');
      case SearchCategory.services:
        return (Icons.miscellaneous_services_rounded, const Color(0xFFEC4899), 'SERVICE');
      case SearchCategory.invoices:
        return (Icons.receipt_long_rounded, const Color(0xFF06B6D4), 'INVOICE');
      case SearchCategory.payments:
        return (Icons.payment_rounded, const Color(0xFFEF4444), 'PAYMENT');
      case SearchCategory.receipts:
        return (Icons.account_balance_wallet_rounded, const Color(0xFF10B981), 'RECEIPT');
      case SearchCategory.general:
        return (Icons.search_rounded, const Color(0xFF64748B), 'GENERAL');
    }
  }

  void _showSearchModal(BuildContext context, {String initialQuery = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalController = TextEditingController(text: initialQuery);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final billingState = ref.read(billingRepositoryProvider);
            final currentText = modalController.text;

            return FutureBuilder<List<SearchResult>>(
              future: _searchRepo.search(currentText, billingState),
              builder: (context, snapshot) {
                final results = snapshot.data ?? (currentText.isEmpty ? _searchRepo.getInitialSuggestions() : []);
                final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

                return Dialog(
                  backgroundColor: isDark ? const Color(0xFF0F1B3B) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                    ),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 620,
                      maxHeight: 520,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Input Bar
                        TextField(
                          controller: modalController,
                          autofocus: true,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search pages, customers, invoices, products, suppliers...',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 20),
                            suffixIcon: currentText.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    onPressed: () {
                                      modalController.clear();
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF131D35) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(
                                color: Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),

                        // Section Header / Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentText.trim().isEmpty
                                  ? 'QUICK SHORTCUTS'
                                  : 'SEARCH RESULTS (${results.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                letterSpacing: 0.6,
                              ),
                            ),
                            if (currentText.trim().isEmpty)
                              Text(
                                'Type to search anything',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF64748B) : Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Results List
                        Expanded(
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF10B981),
                                  ),
                                )
                              : results.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 40,
                                            color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No matching results found for "$currentText"',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: results.length,
                                      separatorBuilder: (ctx, index) => Divider(
                                        color: isDark ? const Color(0xFF1E2E4A) : const Color(0xFFF1F5F9),
                                        height: 1,
                                      ),
                                      itemBuilder: (ctx, index) {
                                        final item = results[index];
                                        final (iconData, iconColor, categoryBadge) = _getCategoryStyle(item.category);

                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: iconColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(iconData, size: 18, color: iconColor),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13.5,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: iconColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  categoryBadge,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: iconColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              item.subtitle,
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                fontSize: 11.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13,
                                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            context.push(item.route);
                                          },
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final businessState = ref.watch(businessProvider);
    final authState = ref.watch(authProvider);
    final activeBiz = businessState.activeBusiness;

    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isVeryCompact = availableWidth < 480;
            final showFullSearch = availableWidth >= 850;
            final showProfileDetails = availableWidth >= 950;

            final buttonSize = isVeryCompact ? 32.0 : 36.0;
            const actionGap = 8.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sidebar menu / Drawer toggle
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (isMobile) {
                      widget.scaffoldKey.currentState?.openDrawer();
                    } else {
                      ref
                          .read(sidebarCollapsedProvider.notifier)
                          .update((state) => !state);
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      (isMobile || isTablet) ? Icons.menu_rounded : Icons.menu_open_rounded,
                      size: isVeryCompact ? 18 : 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(width: actionGap),

                // Tax Bunny App Icon Logo
                Container(
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
                        size: isVeryCompact ? 18 : 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: actionGap),

                // Business Branding
                if (showFullSearch)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: _BrandTitle(
                      isVeryCompact: isVeryCompact,
                      isDark: isDark,
                      businessName: activeBiz?.name ?? 'Retail Store',
                    ),
                  )
                else
                  Expanded(
                    child: _BrandTitle(
                      isVeryCompact: isVeryCompact,
                      isDark: isDark,
                      businessName: activeBiz?.name ?? 'Retail Store',
                    ),
                  ),

                // Center Search Field (Desktop) or Search Icon (Mobile/Tablet)
                if (showFullSearch)
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showSearchModal(context),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: isDark ? const Color(0xFF64748B) : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Search customers, invoices, products or pages...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2E4A) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'Ctrl + K',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(width: actionGap),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showSearchModal(context),
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.search_rounded,
                        size: isVeryCompact ? 17 : 19,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.black87,
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: actionGap),

                // Notification Bell with dynamic unread badge
                Builder(
                  builder: (context) {
                    final unreadCount = ref.watch(unreadNotificationsCountProvider);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.notifications_outlined,
                              size: isVeryCompact ? 17 : 19,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.black87,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: actionGap),

                // Profile Button (Pill Card with Gradient Avatar TS + optional Name/Owner/Chevron)
                PopupMenuButton<String>(
                  color: isDark ? const Color(0xFF0F1B3B) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'profile') {
                      context.push('/profile');
                    } else if (val == 'logout') {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: showProfileDetails ? 8 : 2,
                      vertical: 3,
                    ),
                    decoration: showProfileDetails
                        ? BoxDecoration(
                            color: isDark ? const Color(0xFF131D35) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                            ),
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isVeryCompact ? 28 : 32,
                          height: isVeryCompact ? 28 : 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'TS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVeryCompact ? 10.5 : 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (showProfileDetails) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 105),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authState.user?.name ?? 'Tax Bunny',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Owner',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                          ),
                        ],
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Text(
                            authState.user?.name ?? 'Tax Bunny',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(
                      height: 1,
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  final bool isVeryCompact;
  final bool isDark;
  final String businessName;

  const _BrandTitle({
    required this.isVeryCompact,
    required this.isDark,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TAX BUNNY',
          style: TextStyle(
            fontSize: isVeryCompact ? 13 : 14,
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
                businessName,
                style: TextStyle(
                  fontSize: isVeryCompact ? 10 : 11,
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
    );
  }
}
