import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/navigation_config.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/permissions/permission_service.dart';
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
    // Auto-expand groups based on current route location on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _expandActiveGroup());
  }

  void _expandActiveGroup() {
    try {
      final state = GoRouterState.of(context);
      final location = state.matchedLocation;
      final expanded = ref.read(expandedGroupsProvider);
      final newExpanded = Set<String>.from(expanded);

      for (var item in NavigationConfig.menuItems) {
        if (item.isExpandable) {
          for (var child in item.children!) {
            if (location == child.route ||
                (child.route != '/' && location.startsWith(child.route))) {
              newExpanded.add(item.id);
            }
          }
        }
      }
      ref.read(expandedGroupsProvider.notifier).state = newExpanded;
    } catch (_) {}
  }

  bool _isRouteActive(String route, String currentLoc) {
    if (route == '/dashboard' && currentLoc == '/dashboard') return true;
    if (route != '/dashboard' &&
        route.isNotEmpty &&
        currentLoc.startsWith(route))
      return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final expandedGroups = ref.watch(expandedGroupsProvider);
    final userRole = ref.watch(userRoleProvider);
    final subscription = ref.watch(subscriptionProvider);

    final GoRouterState state = GoRouterState.of(context);
    final String currentLoc = state.matchedLocation;

    return Container(
      width: isCollapsed ? 72 : 260,
      color: isDark ? AppColors.primaryDark : AppColors.primary,
      child: Column(
        children: [
          // Sidebar header title
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            child: isCollapsed
                ? const Icon(Icons.bolt, color: AppColors.accent, size: 28)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.accent, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'TAX BUNNY',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),

          const Divider(color: Colors.white24, height: 1),

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

                      if (allowedChildren.isEmpty)
                        return const SizedBox.shrink();

                      final isExpanded = expandedGroups.contains(item.id);
                      final hasActiveChild = allowedChildren.any(
                        (child) => _isRouteActive(child.route, currentLoc),
                      );

                      if (isCollapsed) {
                        // Render flyout menu popup or hover tooltip for groups
                        return Tooltip(
                          message: item.title,
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              item.icon,
                              color: hasActiveChild
                                  ? AppColors.accent
                                  : Colors.white70,
                            ),
                            offset: const Offset(70, 0),
                            onSelected: (route) => context.push(route),
                            itemBuilder: (context) {
                              return allowedChildren.map((child) {
                                final isChildAllowed =
                                    child.requiredFeature == null ||
                                    subscription.canAccess(
                                      child.requiredFeature!,
                                    );
                                return PopupMenuItem<String>(
                                  value: child.route,
                                  child: Row(
                                    children: [
                                      Icon(child.icon, size: 18),
                                      const SizedBox(width: 8),
                                      Text(child.title),
                                      if (!isChildAllowed)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.lock,
                                            size: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              item.icon,
                              color: hasActiveChild
                                  ? AppColors.accent
                                  : Colors.white70,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: hasActiveChild
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: hasActiveChild
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onTap: () {
                              final newExpanded = Set<String>.from(
                                expandedGroups,
                              );
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
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                              ),
                              child: Column(
                                children: allowedChildren.map((child) {
                                  final isAllowed =
                                      child.requiredFeature == null ||
                                      subscription.canAccess(
                                        child.requiredFeature!,
                                      );
                                  final isChildActive = _isRouteActive(
                                    child.route,
                                    currentLoc,
                                  );

                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      child.icon,
                                      size: 18,
                                      color: isChildActive
                                          ? AppColors.accent
                                          : (isAllowed
                                                ? Colors.white54
                                                : Colors.white24),
                                    ),
                                    title: Text(
                                      child.title,
                                      style: TextStyle(
                                        color: isChildActive
                                            ? Colors.white
                                            : (isAllowed
                                                  ? Colors.white70
                                                  : Colors.white30),
                                        fontWeight: isChildActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: !isAllowed
                                        ? const Icon(
                                            Icons.lock,
                                            size: 12,
                                            color: Colors.orange,
                                          )
                                        : null,
                                    onTap: () {
                                      if (isAllowed) {
                                        context.push(child.route);
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
                      final isActive = _isRouteActive(item.route, currentLoc);

                      if (isCollapsed) {
                        return Tooltip(
                          message: item.title,
                          child: IconButton(
                            icon: Icon(
                              item.icon,
                              color: isActive
                                  ? AppColors.accent
                                  : (isAllowed
                                        ? Colors.white70
                                        : Colors.white24),
                            ),
                            onPressed: () {
                              if (isAllowed) {
                                context.push(item.route);
                              } else {
                                context.push(
                                  '/locked-feature',
                                  extra: {'featureName': item.title},
                                );
                              }
                            },
                          ),
                        );
                      }

                      return ListTile(
                        leading: Icon(
                          item.icon,
                          color: isActive
                              ? AppColors.accent
                              : (isAllowed ? Colors.white70 : Colors.white24),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : (isAllowed ? Colors.white70 : Colors.white30),
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: !isAllowed
                            ? const Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.orange,
                              )
                            : null,
                        onTap: () {
                          if (isAllowed) {
                            context.push(item.route);
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
