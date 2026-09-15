import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/navigation/navigation_config.dart';
import '../../../../core/navigation/navigation_item.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../features/subscription/domain/entities/subscription_models.dart';
import '../../../../features/subscription/presentation/providers/subscription_provider.dart';

class DesktopSidebar extends ConsumerStatefulWidget {
  const DesktopSidebar({super.key});

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  @override
  void initState() {
    super.initState();
    // Auto-expand groups based on active route location on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _expandActiveGroup());
  }

  void _expandActiveGroup() {
    try {
      final state = GoRouterState.of(context);
      final location = state.uri.path.isNotEmpty ? state.uri.path : state.matchedLocation;
      final activeRoute = ref.read(activeSidebarRouteProvider);
      final expanded = ref.read(expandedGroupsProvider);
      final newExpanded = Set<String>.from(expanded);

      for (var item in NavigationConfig.menuItems) {
        if (item.isExpandable && item.children != null) {
          for (var child in item.children!) {
            if (_isItemActive(child.route, location, activeRoute)) {
              newExpanded.add(item.id);
            }
          }
        }
      }
      ref.read(expandedGroupsProvider.notifier).state = newExpanded;
    } catch (_) {}
  }

  bool _isRouteActive(String route, String currentLoc) {
    final cleanLoc = currentLoc.split('?').first.split('#').first;
    final cleanRoute = route.split('?').first.split('#').first;

    // 1. Exact match
    if (cleanLoc == cleanRoute) return true;

    // Special dashboard rule (only exact match)
    if (cleanRoute == '/dashboard') return cleanLoc == '/dashboard';

    // 2. Sub-route match (e.g. /customers/new or /customers/123 matches /customers)
    if (cleanRoute.isNotEmpty &&
        cleanRoute != '/' &&
        cleanLoc.startsWith('$cleanRoute/')) {
      // Ensure there isn't another menu item with a more specific/longer match
      for (final item in NavigationConfig.menuItems) {
        if (item.isExpandable && item.children != null) {
          for (final child in item.children!) {
            final childRoute = child.route.split('?').first;
            if (childRoute != cleanRoute &&
                childRoute.length > cleanRoute.length &&
                (cleanLoc == childRoute || cleanLoc.startsWith('$childRoute/'))) {
              return false;
            }
          }
        } else {
          final itemRoute = item.route.split('?').first;
          if (itemRoute != cleanRoute &&
              itemRoute.length > cleanRoute.length &&
              (cleanLoc == itemRoute || cleanLoc.startsWith('$itemRoute/'))) {
            return false;
          }
        }
      }
      return true;
    }

    return false;
  }

  bool _isItemActive(String route, String currentLoc, String? activeRoute) {
    if (activeRoute != null && activeRoute.isNotEmpty) {
      // If user explicitly clicked this route, it takes active priority
      if (route == activeRoute) return true;
      // If activeRoute still accurately matches current router location, respect it
      if (_isRouteActive(activeRoute, currentLoc)) {
        return false;
      }
    }
    // Fallback: match against router location
    return _isRouteActive(route, currentLoc);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final expandedGroups = ref.watch(expandedGroupsProvider);
    final userRole = ref.watch(userRoleProvider);
    final subscription = ref.watch(subscriptionProvider);
    final activeRoute = ref.watch(activeSidebarRouteProvider);

    final GoRouterState state = GoRouterState.of(context);
    final String currentLoc = state.uri.path.isNotEmpty ? state.uri.path : state.matchedLocation;

    // Theme-based colors for the sidebar shell
    final sidebarBg = isDark ? const Color(0xFF0B132B) : Colors.white;
    final sidebarBorder = isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight;

    return Container(
      width: isCollapsed ? 72 : 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xs),

          // Scrollable Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: NavigationConfig.menuItems
                  .where((item) {
                    // Check RBAC permission for parent item
                    if (item.requiredPermission != null) {
                      return PermissionService.hasPermission(
                        userRole,
                        item.requiredPermission!,
                      );
                    }
                    return true;
                  })
                  .map((item) {
                    if (item.isExpandable) {
                      // Filter expandable children based on RBAC permissions
                      final allowedChildren = item.children!.where((child) {
                        if (child.requiredPermission != null) {
                          return PermissionService.hasPermission(
                            userRole,
                            child.requiredPermission!,
                          );
                        }
                        return true;
                      }).toList();

                      if (allowedChildren.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final isExpanded = expandedGroups.contains(item.id);
                      final hasActiveChild = allowedChildren.any(
                        (child) => _isItemActive(child.route, currentLoc, activeRoute),
                      );

                      if (isCollapsed) {
                        return _CollapsedGroupButton(
                          item: item,
                          allowedChildren: allowedChildren,
                          hasActiveChild: hasActiveChild,
                          isDark: isDark,
                          currentLoc: currentLoc,
                          activeRoute: activeRoute,
                          subscription: subscription,
                          onChildSelected: (route) {
                            ref.read(activeSidebarRouteProvider.notifier).state = route;
                            context.go(route);
                          },
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SidebarNavTile(
                            icon: item.icon,
                            title: item.title,
                            isActive: false,
                            isDark: isDark,
                            isExpandable: true,
                            isExpanded: isExpanded,
                            hasActiveChild: hasActiveChild,
                            onTap: () {
                              final newExpanded = Set<String>.from(expandedGroups);
                              if (isExpanded) {
                                newExpanded.remove(item.id);
                              } else {
                                newExpanded.add(item.id);
                              }
                              ref.read(expandedGroupsProvider.notifier).state =
                                  newExpanded;
                            },
                          ),
                          if (isExpanded)
                            Container(
                              margin: const EdgeInsets.only(
                                left: 24,
                                right: 6,
                                top: 2,
                                bottom: 4,
                              ),
                              padding: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF1E2E4A)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: allowedChildren.map((child) {
                                  final isAllowed =
                                      child.requiredFeature == null ||
                                      subscription.canAccess(
                                        child.requiredFeature!,
                                      );
                                  final isChildActive = _isItemActive(
                                    child.route,
                                    currentLoc,
                                    activeRoute,
                                  );

                                  return _SidebarNavTile(
                                    icon: child.icon,
                                    title: child.title,
                                    isActive: isChildActive,
                                    isDark: isDark,
                                    isAllowed: isAllowed,
                                    isSubItem: true,
                                    onTap: () {
                                      if (isAllowed) {
                                        ref.read(activeSidebarRouteProvider.notifier).state = child.route;
                                        context.go(child.route);
                                      } else {
                                        context.push(
                                          '/locked-feature',
                                          extra: {'featureName': child.title},
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    } else {
                      // Single item (no children)
                      final isAllowed =
                          item.requiredFeature == null ||
                          subscription.canAccess(item.requiredFeature!);
                      final isActive = _isItemActive(item.route, currentLoc, activeRoute);

                      if (isCollapsed) {
                        return _CollapsedSingleButton(
                          item: item,
                          isActive: isActive,
                          isDark: isDark,
                          isAllowed: isAllowed,
                          onTap: () {
                            if (isAllowed) {
                              ref.read(activeSidebarRouteProvider.notifier).state = item.route;
                              context.go(item.route);
                            } else {
                              context.push(
                                '/locked-feature',
                                extra: {'featureName': item.title},
                              );
                            }
                          },
                        );
                      }

                      return _SidebarNavTile(
                        icon: item.icon,
                        title: item.title,
                        isActive: isActive,
                        isDark: isDark,
                        isAllowed: isAllowed,
                        onTap: () {
                          if (isAllowed) {
                            ref.read(activeSidebarRouteProvider.notifier).state = item.route;
                            context.go(item.route);
                          } else {
                            context.push(
                              '/locked-feature',
                              extra: {'featureName': item.title},
                            );
                          }
                        },
                      );
                    }
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A highly polished, attractive navigation tile with smooth hover effects,
/// active state indicators, and theme-adaptive coloring.
class _SidebarNavTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isDark;
  final bool isAllowed;
  final bool isExpandable;
  final bool isExpanded;
  final bool isSubItem;
  final bool hasActiveChild;
  final VoidCallback? onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.isDark,
    this.isAllowed = true,
    this.isExpandable = false,
    this.isExpanded = false,
    this.isSubItem = false,
    this.hasActiveChild = false,
    this.onTap,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isActive = widget.isActive;
    final hasActiveChild = widget.hasActiveChild;
    final isAllowed = widget.isAllowed;
    final isHovered = _isHovered && isAllowed;

    // Background & Border styling based on state
    Color backgroundColor;
    Border border;

    if (isActive) {
      if (isDark) {
        backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.16);
        border = Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1,
        );
      } else {
        backgroundColor = const Color(0xFFECFDF5);
        border = Border.all(
          color: const Color(0xFFA7F3D0),
          width: 1,
        );
      }
    } else if (hasActiveChild) {
      if (isDark) {
        backgroundColor = isHovered
            ? const Color(0xFF162444)
            : const Color(0xFF10B981).withValues(alpha: 0.08);
        border = Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
          width: 1,
        );
      } else {
        backgroundColor = isHovered
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFF0FDF4).withValues(alpha: 0.7);
        border = Border.all(
          color: const Color(0xFFD1FAE5),
          width: 1,
        );
      }
    } else if (isHovered) {
      if (isDark) {
        backgroundColor = const Color(0xFF162444);
        border = Border.all(
          color: const Color(0xFF1E2E4A),
          width: 1,
        );
      } else {
        backgroundColor = const Color(0xFFF1F5F9);
        border = Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        );
      }
    } else {
      backgroundColor = Colors.transparent;
      border = Border.all(color: Colors.transparent, width: 1);
    }

    // Colors for Text & Icons
    Color iconColor;
    Color textColor;
    FontWeight fontWeight;

    if (!isAllowed) {
      iconColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
      textColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
      fontWeight = FontWeight.normal;
    } else if (isActive) {
      iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      textColor = isDark ? Colors.white : const Color(0xFF065F46);
      fontWeight = FontWeight.w600;
    } else if (hasActiveChild) {
      iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      fontWeight = FontWeight.w600;
    } else if (isHovered) {
      iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
      textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      fontWeight = FontWeight.w500;
    } else {
      iconColor = isDark
          ? (widget.isSubItem ? Colors.white54 : Colors.white70)
          : (widget.isSubItem ? const Color(0xFF64748B) : const Color(0xFF475569));
      textColor = isDark
          ? (widget.isSubItem ? Colors.white70 : Colors.white)
          : (widget.isSubItem ? const Color(0xFF475569) : const Color(0xFF0F172A));
      fontWeight = FontWeight.normal;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: widget.isSubItem ? 1.5 : 2.5,
      ),
      child: MouseRegion(
        cursor: isAllowed ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: widget.isSubItem ? 7.5 : 9.5,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: border,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: (isDark
                                ? const Color(0xFF10B981)
                                : const Color(0xFF059669))
                            .withValues(alpha: isDark ? 0.12 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Active indicator vertical bar
                if (isActive)
                  Container(
                    width: 3.5,
                    height: widget.isSubItem ? 13 : 15,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                else if (widget.isSubItem)
                  // Subtle indent dot for sub-items
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.only(left: 2, right: 8),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                          : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      shape: BoxShape.circle,
                    ),
                  ),

                // Icon
                Icon(
                  widget.icon,
                  size: widget.isSubItem ? 17 : 19,
                  color: iconColor,
                ),
                const SizedBox(width: 10),

                // Title
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.isSubItem ? 12.5 : 13.5,
                      fontWeight: fontWeight,
                      color: textColor,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Trailing Widget: Lock or Animated Chevron
                if (!isAllowed)
                  Tooltip(
                    message: 'Premium Feature',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: Colors.amber,
                      ),
                    ),
                  )
                else if (widget.isExpandable)
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isHovered || hasActiveChild
                          ? (isDark ? Colors.white70 : const Color(0xFF475569))
                          : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed view button for expandable menu items (shows flyout popup on click).
class _CollapsedGroupButton extends StatefulWidget {
  final NavigationItem item;
  final List<NavigationItem> allowedChildren;
  final bool hasActiveChild;
  final bool isDark;
  final String currentLoc;
  final String? activeRoute;
  final SubscriptionModel subscription;
  final ValueChanged<String> onChildSelected;

  const _CollapsedGroupButton({
    required this.item,
    required this.allowedChildren,
    required this.hasActiveChild,
    required this.isDark,
    required this.currentLoc,
    required this.activeRoute,
    required this.subscription,
    required this.onChildSelected,
  });

  @override
  State<_CollapsedGroupButton> createState() => _CollapsedGroupButtonState();
}

class _CollapsedGroupButtonState extends State<_CollapsedGroupButton> {
  bool _isHovered = false;

  bool _isChildActive(String route) {
    if (widget.activeRoute != null && widget.activeRoute!.isNotEmpty) {
      if (route == widget.activeRoute) return true;
    }
    final cleanLoc = widget.currentLoc.split('?').first;
    final cleanRoute = route.split('?').first;
    return cleanLoc == cleanRoute;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final hasActiveChild = widget.hasActiveChild;
    final isHovered = _isHovered;

    Color bg;
    Border border;
    Color iconColor;

    if (hasActiveChild) {
      bg = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.18)
          : const Color(0xFFECFDF5);
      border = Border.all(
        color: isDark
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : const Color(0xFFA7F3D0),
        width: 1.2,
      );
      iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    } else if (isHovered) {
      bg = isDark ? const Color(0xFF162444) : const Color(0xFFF1F5F9);
      border = Border.all(
        color: isDark ? const Color(0xFF1E2E4A) : const Color(0xFFE2E8F0),
        width: 1,
      );
      iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    } else {
      bg = Colors.transparent;
      border = Border.all(color: Colors.transparent, width: 1);
      iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 14),
      child: Tooltip(
        message: widget.item.title,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(56, 0),
            color: isDark ? const Color(0xFF131D35) : Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderLight,
              ),
            ),
            onSelected: (route) {
              final matched = widget.allowedChildren.firstWhere(
                (c) => c.route == route,
                orElse: () => widget.allowedChildren.first,
              );
              final isAllowed = matched.requiredFeature == null ||
                  widget.subscription.canAccess(matched.requiredFeature!);
              if (isAllowed) {
                widget.onChildSelected(route);
              } else {
                context.push(
                  '/locked-feature',
                  extra: {'featureName': matched.title},
                );
              }
            },
            itemBuilder: (context) {
              return widget.allowedChildren.map((child) {
                final isChildAllowed = child.requiredFeature == null ||
                    widget.subscription.canAccess(child.requiredFeature!);
                final isChildActive = _isChildActive(child.route);

                return PopupMenuItem<String>(
                  value: child.route,
                  child: Row(
                    children: [
                      Icon(
                        child.icon,
                        size: 18,
                        color: isChildActive
                            ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669))
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          child.title,
                          style: TextStyle(
                            color: isChildActive
                                ? (isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669))
                                : (isDark
                                    ? Colors.white
                                    : AppColors.textLightPrimary),
                            fontWeight: isChildActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!isChildAllowed)
                        const Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                );
              }).toList();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                border: border,
                borderRadius: BorderRadius.circular(10),
                boxShadow: hasActiveChild
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF059669))
                              .withValues(alpha: isDark ? 0.15 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(widget.item.icon, size: 20, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed view button for single (non-expandable) items.
class _CollapsedSingleButton extends StatefulWidget {
  final NavigationItem item;
  final bool isActive;
  final bool isDark;
  final bool isAllowed;
  final VoidCallback onTap;

  const _CollapsedSingleButton({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.isAllowed,
    required this.onTap,
  });

  @override
  State<_CollapsedSingleButton> createState() => _CollapsedSingleButtonState();
}

class _CollapsedSingleButtonState extends State<_CollapsedSingleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isActive = widget.isActive;
    final isAllowed = widget.isAllowed;
    final isHovered = _isHovered && isAllowed;

    Color bg;
    Border border;
    Color iconColor;

    if (isActive) {
      bg = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.18)
          : const Color(0xFFECFDF5);
      border = Border.all(
        color: isDark
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : const Color(0xFFA7F3D0),
        width: 1.2,
      );
      iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    } else if (isHovered) {
      bg = isDark ? const Color(0xFF162444) : const Color(0xFFF1F5F9);
      border = Border.all(
        color: isDark ? const Color(0xFF1E2E4A) : const Color(0xFFE2E8F0),
        width: 1,
      );
      iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    } else {
      bg = Colors.transparent;
      border = Border.all(color: Colors.transparent, width: 1);
      iconColor = !isAllowed
          ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1))
          : (isDark ? Colors.white70 : const Color(0xFF64748B));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 14),
      child: Tooltip(
        message: widget.item.title,
        child: MouseRegion(
          cursor: isAllowed ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                border: border,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF059669))
                              .withValues(alpha: isDark ? 0.15 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(widget.item.icon, size: 20, color: iconColor),
                    if (!isAllowed)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0B132B)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 9,
                            color: Colors.amber,
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
    );
  }
}
