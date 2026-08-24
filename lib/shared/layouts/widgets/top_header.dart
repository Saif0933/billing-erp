import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 400,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search customers, invoices, products...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
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
                          ? const Center(
                              child: Text('No results matching query.'),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return ListTile(
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(item.subtitle),
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
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // Sidebar menu / Drawer toggle
            if (isMobile || isTablet)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  if (isMobile) {
                    widget.scaffoldKey.currentState?.openDrawer();
                  } else {
                    // Collapse / Expand sidebar for tablet
                    ref
                        .read(sidebarCollapsedProvider.notifier)
                        .update((state) => !state);
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.menu_open),
                onPressed: () {
                  ref
                      .read(sidebarCollapsedProvider.notifier)
                      .update((state) => !state);
                },
              ),

            const SizedBox(width: AppSpacing.sm),

            // Business Switcher Dropdown
            if (activeBiz != null)
              Flexible(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Align(
                    alignment: Alignment.centerLeft,
                    child: PopupMenuButton<String>(
                      onSelected: (id) {
                        if (id == 'new_business') {
                          context.push('/create-business');
                        } else {
                          ref.read(businessProvider.notifier).switchBusiness(id);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              activeBiz.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                      itemBuilder: (context) {
                        return [
                          ...businessState.businesses.map((b) {
                            return PopupMenuItem<String>(
                              value: b.id,
                              child: Row(
                                children: [
                                  if (b.id == activeBiz.id)
                                    const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    )
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Text(b.name),
                                ],
                              ),
                            );
                          }),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'new_business',
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 16),
                                const SizedBox(width: 8),
                                Text('Add Business'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              )
            else
              Text(
                'TAX BUNNY',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

            const Spacer(),

             // Search Field
            if (!isMobile)
              Container(
                width: 320,
                height: 42,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search customers, invoices...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFF2E7D32)),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2E2E2E)
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                      ),
                  ],
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchModal(context),
              ),

            // Notifications
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),

            // Profile Switcher Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (val) {
                if (val == 'profile') {
                  context.push('/profile');
                } else if (val == 'logout') {
                  ref.read(authProvider.notifier).logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Text(authState.user?.name ?? 'User Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
