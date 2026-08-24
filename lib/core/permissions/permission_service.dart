import 'permission_models.dart';

class PermissionService {
  PermissionService._();

  static const Map<UserRole, Set<AppPermission>> _rolePermissions = {
    UserRole.owner: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      AppPermission.createTransactions,
      AppPermission.editTransactions,
      AppPermission.deleteTransactions,
      AppPermission.printTransactions,
      AppPermission.exportTransactions,
      AppPermission.approveTransactions,
      AppPermission.manageSettings,
      AppPermission.manageUsers,
      AppPermission.manageSubscription,
      // Accounting
      AppPermission.viewAccounts,
      AppPermission.createAccounts,
      AppPermission.editAccounts,
      AppPermission.deactivateAccounts,
      AppPermission.viewJournals,
      AppPermission.postJournals,
      AppPermission.reverseJournals,
      AppPermission.viewTrialBalance,
      AppPermission.viewProfitLoss,
      AppPermission.viewBalanceSheet,
      AppPermission.closePeriod,
      AppPermission.reopenPeriod,
      // Manufacturing
      AppPermission.viewProduction,
      AppPermission.createProduction,
      AppPermission.editProduction,
      AppPermission.completeProduction,
      AppPermission.cancelProduction,
      AppPermission.viewBOM,
      AppPermission.createBOM,
      AppPermission.editBOM,
      AppPermission.viewJobWork,
      AppPermission.createJobWork,
      AppPermission.receiveJobWork,
    },
    UserRole.admin: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      AppPermission.createTransactions,
      AppPermission.editTransactions,
      AppPermission.deleteTransactions,
      AppPermission.printTransactions,
      AppPermission.exportTransactions,
      AppPermission.approveTransactions,
      AppPermission.manageSettings,
      AppPermission.manageUsers,
      // Accounting
      AppPermission.viewAccounts,
      AppPermission.createAccounts,
      AppPermission.editAccounts,
      AppPermission.deactivateAccounts,
      AppPermission.viewJournals,
      AppPermission.postJournals,
      AppPermission.reverseJournals,
      AppPermission.viewTrialBalance,
      AppPermission.viewProfitLoss,
      AppPermission.viewBalanceSheet,
      AppPermission.closePeriod,
      AppPermission.reopenPeriod,
      // Manufacturing
      AppPermission.viewProduction,
      AppPermission.createProduction,
      AppPermission.editProduction,
      AppPermission.completeProduction,
      AppPermission.cancelProduction,
      AppPermission.viewBOM,
      AppPermission.createBOM,
      AppPermission.editBOM,
      AppPermission.viewJobWork,
      AppPermission.createJobWork,
      AppPermission.receiveJobWork,
    },
    UserRole.accountant: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      AppPermission.createTransactions,
      AppPermission.editTransactions,
      AppPermission.printTransactions,
      AppPermission.exportTransactions,
      AppPermission.approveTransactions,
      // Accounting
      AppPermission.viewAccounts,
      AppPermission.createAccounts,
      AppPermission.editAccounts,
      AppPermission.deactivateAccounts,
      AppPermission.viewJournals,
      AppPermission.postJournals,
      AppPermission.reverseJournals,
      AppPermission.viewTrialBalance,
      AppPermission.viewProfitLoss,
      AppPermission.viewBalanceSheet,
      AppPermission.closePeriod,
    },
    UserRole.salesUser: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      AppPermission.createTransactions,
      AppPermission.editTransactions,
      AppPermission.printTransactions,
    },
    UserRole.purchaseUser: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      AppPermission.createTransactions,
      AppPermission.editTransactions,
      AppPermission.printTransactions,
    },
    UserRole.inventoryUser: {
      AppPermission.viewDashboard,
      AppPermission.viewTransactions,
      // Manufacturing
      AppPermission.viewProduction,
      AppPermission.createProduction,
      AppPermission.completeProduction,
      AppPermission.viewBOM,
      AppPermission.viewJobWork,
      AppPermission.receiveJobWork,
    },
  };

  static bool hasPermission(UserRole role, AppPermission permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static bool hasAllPermissions(UserRole role, List<AppPermission> permissions) {
    final rolePerms = _rolePermissions[role];
    if (rolePerms == null) return false;
    return permissions.every((p) => rolePerms.contains(p));
  }

  static bool hasAnyPermission(UserRole role, List<AppPermission> permissions) {
    final rolePerms = _rolePermissions[role];
    if (rolePerms == null) return false;
    return permissions.any((p) => rolePerms.contains(p));
  }
}
