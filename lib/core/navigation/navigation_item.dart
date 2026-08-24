import 'package:flutter/material.dart';
import '../permissions/permission_models.dart';
import '../../features/subscription/domain/entities/subscription_models.dart';

class NavigationItem {
  final String id;
  final String title;
  final IconData icon;
  final String route;
  final List<NavigationItem>? children;
  final AppPermission? requiredPermission;
  final SubscriptionFeature? requiredFeature;
  final String? badge;

  const NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
    this.children,
    this.requiredPermission,
    this.requiredFeature,
    this.badge,
  });

  bool get isExpandable => children != null && children!.isNotEmpty;
}
