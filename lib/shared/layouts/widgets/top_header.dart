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

class ResponsiveTopHeader extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ResponsiveTopHeader({super.key, required this.scaffoldKey});

  @override
  ConsumerState<ResponsiveTopHeader> createState() =>
      _ResponsiveTopHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _ResponsiveTopHeaderState extends ConsumerState<ResponsiveTopHeader> {
  final _searchController = TextEditingController();
  final _searchRepo = SearchRepository();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    final billingState = ref.read(billingRepositoryProvider);
    final results = await _searchRepo.search(query, billingState);
    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _showSearchModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F1B3B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
                ),
              ),
              insetPadding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 420,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search customers, invoices, products...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
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
                      onChanged: (val) async {
                        final billingState = ref.read(
                          billingRepositoryProvider,
                        );
                        final results = await _searchRepo.search(
                          val,
                          billingState,
                        );
                        setModalState(() {
                          _searchResults = results;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'No results matching query.',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF64748B) : Colors.grey,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => Divider(
                                color: isDark ? const Color(0xFF1E2E4A) : Colors.black12,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF10B981)),
                                  onTap: () {
                                    Navigator.pop(context);
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
    ).then((_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    });
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
        height: 60,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F1B3B), Color(0xFF0B132B)],
                )
              : null,
          color: isDark ? null : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isVeryCompact = availableWidth < 480;
            final showFullSearch = availableWidth >= 850;
            final showProfileDetails = availableWidth >= 950;
            final showHelpIcon = availableWidth >= 750;

            final buttonSize = isVeryCompact ? 32.0 : 36.0;

            return Row(
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

                SizedBox(width: isVeryCompact ? 6 : 8),

                // Emerald Lightning Bolt Logo with Glowing Shadow
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: isVeryCompact ? 18 : 20,
                  ),
                ),

                SizedBox(width: isVeryCompact ? 6 : 8),

                // Business Branding & Switcher (Strictly Constrained to prevent overflow)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isVeryCompact ? 90 : (availableWidth < 700 ? 115 : 180),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TAX BUNNY',
                        style: TextStyle(
                          fontSize: isVeryCompact ? 12 : 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                              activeBiz?.name ?? 'Retail Store',
                              style: TextStyle(
                                fontSize: isVeryCompact ? 9 : 10.5,
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

                // Center Search Field (Desktop) or Spacer + Search Icon (Mobile/Tablet)
                if (showFullSearch)
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 38,
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search customers, invoices, products or anything...',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF64748B) : Colors.grey,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: isDark ? const Color(0xFF64748B) : Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF131D35) : const Color(0xFFF1F5F9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 12.0,
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
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                                Positioned(
                                  right: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isSearching)
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      else
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  const Spacer(),
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

                SizedBox(width: isVeryCompact ? 4 : 6),

                // Notification Bell with Badge '3'
                Stack(
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
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                // Help Question Mark Icon (Desktop/Tablet only)
                if (showHelpIcon) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Help & Documentation',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {},
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
                          Icons.help_outline_rounded,
                          size: 19,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],

                SizedBox(width: isVeryCompact ? 4 : 6),

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
