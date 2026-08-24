import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../permissions/permission_models.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/providers/billing_repository.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
final expandedGroupsProvider = StateProvider<Set<String>>((ref) => <String>{});

final userRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authProvider);
  final billingState = ref.watch(billingRepositoryProvider);
  final userEmail = authState.user?.email ?? 'owner@taxbunny.com';
  
  final userMap = billingState.customUsers.firstWhere(
    (u) => u['email'] == userEmail,
    orElse: () => {
      'role': 'owner',
    },
  );
  
  final String roleStr = userMap['role'] ?? 'owner';
  return UserRole.values.firstWhere(
    (r) => r.name == roleStr,
    orElse: () => UserRole.owner,
  );
});
