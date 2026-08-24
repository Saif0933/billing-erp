import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/navigation/navigation_config.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../features/business/presentation/providers/business_provider.dart';
import '../../../../features/subscription/presentation/providers/subscription_provider.dart';

class MobileDrawer extends ConsumerWidget {
  const MobileDrawer({super.key});

  bool _isRouteActive(String route, String currentLoc) {
    if (route == '/dashboard' && currentLoc == '/dashboard') {
      return true;
    }
    if (route != '/dashboard' &&
        route.isNotEmpty &&
        currentLoc.startsWith(route)) {
      return true;
    }
    return false;
  }

  Color _getItemIconColor(String id, bool isActive) {
    if (isActive) return const Color(0xFF00E676);
    switch (id) {
      case 'dashboard':
        return const Color(0xFF00E676);
      case 'pos':
        return const Color(0xFF9C27B0);
      case 'masters':
      case 'customers':
      case 'suppliers':
      case 'products':
      case 'services':
        return const Color(0xFF1976D2);
      case 'sales_group':
      case 'sales':
      case 'recurring_billing':
        return const Color(0xFF00BCD4);
      case 'purchase_group':
      case 'purchase':
        return const Color(0xFF4CAF50);
      case 'payments_group':
      case 'receipts':
      case 'payments':
      case 'outstanding':
        return const Color(0xFFFF9800);
      case 'expenses':
        return const Color(0xFFE91E63);
      case 'inventory_group':
      case 'inventory':
      case 'warehouses':
        return const Color(0xFF9C27B0);
      case 'accounting_group':
      case 'ledger':
      case 'chart_of_accounts':
      case 'journal_entries':
      case 'bank_accounts':
      case 'financial_reports':
        return const Color(0xFF4CAF50);
      case 'manufacturing_group':
      case 'bom':
      case 'production_orders':
      case 'job_work':
      case 'mfg_reports':
        return const Color(0xFFFFC107);
      case 'gst':
        return const Color(0xFFE91E63);
      case 'reports':
        return const Color(0xFF1976D2);
      case 'subscription_group':
      case 'subscription':
      case 'upgrade':
        return const Color(0xFF9C27B0);
      case 'settings_group':
      case 'settings':
      case 'profile':
      case 'invoice_customization':
      case 'users':
      case 'audit_logs':
      case 'import_export':
        return const Color(0xFF9E9E9E);
      default:
        return Colors.white70;
    }
  }

  Widget _buildNeedHelpCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A221C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0E382A), width: 1),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF0D3227),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.headset_mic_outlined, color: Color(0xFF00E676), size: 18),
        ),
        title: const Text(
          'Need Help?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          "We're here to assist you",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 16),
        onTap: () {
          Navigator.pop(context);
          context.push('/settings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedGroups = ref.watch(expandedGroupsProvider);
    final userRole = ref.watch(userRoleProvider);
    final subscription = ref.watch(subscriptionProvider);
    final activeBiz = ref.watch(businessProvider).activeBusiness;

    final GoRouterState state = GoRouterState.of(context);
    final String currentLoc = state.matchedLocation;
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      child: Container(
        color: const Color(0xFF04120E), // Deep dark green theme
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: Color(0xFF00E676), size: 28),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'TAX ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'BUNNY',
                                    style: TextStyle(
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeBiz?.name ?? 'Tax Bunny Retail Store',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                children: NavigationConfig.menuItems.where((item) {
                  if (item.requiredPermission != null) {
                    return PermissionService.hasPermission(userRole, item.requiredPermission!);
                  }
                  return true;
                }).map((item) {
                  if (item.isExpandable) {
                    final allowedChildren = item.children!.where((child) {
                      if (child.requiredPermission != null) {
                        return PermissionService.hasPermission(userRole, child.requiredPermission!);
                      }
                      return true;
                    }).toList();

                    if (allowedChildren.isEmpty) return const SizedBox.shrink();

                    final isExpanded = expandedGroups.contains(item.id);
                    final hasActiveChild = allowedChildren.any((child) => _isRouteActive(child.route, currentLoc));

                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasActiveChild ? const Color(0xFF09221C) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            dense: true,
                            leading: Icon(
                              item.icon,
                              color: _getItemIconColor(item.id, hasActiveChild),
                              size: 20,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: hasActiveChild ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13.5,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white30,
                              size: 16,
                            ),
                            onTap: () {
                              final newExpanded = Set<String>.from(expandedGroups);
                              if (isExpanded) {
                                newExpanded.remove(item.id);
                              } else {
                                newExpanded.add(item.id);
                              }
                              ref.read(expandedGroupsProvider.notifier).state = newExpanded;
                            },
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              children: allowedChildren.map((child) {
                                final isAllowed = child.requiredFeature == null || subscription.canAccess(child.requiredFeature!);
                                final isChildActive = _isRouteActive(child.route, currentLoc);

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isChildActive ? const Color(0xFF0F2D24) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isChildActive
                                        ? const Border(left: BorderSide(color: Color(0xFF00E676), width: 3.5))
                                        : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    dense: true,
                                    leading: Icon(
                                      child.icon,
                                      size: 18,
                                      color: _getItemIconColor(child.id, isChildActive),
                                    ),
                                    title: Text(
                                      child.title,
                                      style: TextStyle(
                                        color: isChildActive ? Colors.white : Colors.white70,
                                        fontWeight: isChildActive ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: !isAllowed
                                        ? const Icon(Icons.lock, size: 14, color: Color(0xFFFF9800))
                                        : Icon(
                                            Icons.chevron_right,
                                            color: isChildActive ? const Color(0xFF00E676) : Colors.white30,
                                            size: 16,
                                          ),
                                    onTap: () {
                                      Navigator.pop(context); // Close Drawer
                                      if (isAllowed) {
                                        context.push(child.route);
                                      } else {
                                        context.push('/locked-feature', extra: {'featureName': child.title});
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  } else {
                    final isAllowed = item.requiredFeature == null || subscription.canAccess(item.requiredFeature!);
                    final isActive = _isRouteActive(item.route, currentLoc);
                    final isNew = item.id == 'expenses';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF0F2D24) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isActive
                            ? const Border(left: BorderSide(color: Color(0xFF00E676), width: 3.5))
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        dense: true,
                        leading: Icon(
                          item.icon,
                          color: _getItemIconColor(item.id, isActive),
                          size: 20,
                        ),
                        title: Text(
                          item.id == 'expenses' ? 'Expeness Tracker' : item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13.5,
                          ),
                        ),
                        trailing: !isAllowed
                            ? const Icon(Icons.lock, size: 14, color: Color(0xFFFF9800))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isNew) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE65100),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(
                                    Icons.chevron_right,
                                    color: isActive ? const Color(0xFF00E676) : Colors.white30,
                                    size: 16,
                                  ),
                                ],
                              ),
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          if (isAllowed) {
                            context.push(item.route);
                          } else {
                            context.push('/locked-feature', extra: {'featureName': item.title});
                          }
                        },
                      ),
                    );
                  }
                }).toList(),
              ),
            ),

            // Bottom Need Help Card
            _buildNeedHelpCard(context),
          ],
        ),
      ),
    );
  }
}
