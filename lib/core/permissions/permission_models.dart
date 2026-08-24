enum UserRole {
  owner,
  admin,
  accountant,
  salesUser,
  purchaseUser,
  inventoryUser;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.salesUser:
        return 'Sales User';
      case UserRole.purchaseUser:
        return 'Purchase User';
      case UserRole.inventoryUser:
        return 'Inventory User';
    }
  }
}

enum AppPermission {
  viewDashboard,
  viewTransactions,
  createTransactions,
  editTransactions,
  deleteTransactions,
  printTransactions,
  exportTransactions,
  approveTransactions,
  manageSettings,
  manageUsers,
  manageSubscription,

  // Accounting Permissions
  viewAccounts,
  createAccounts,
  editAccounts,
  deactivateAccounts,
  viewJournals,
  postJournals,
  reverseJournals,
  viewTrialBalance,
  viewProfitLoss,
  viewBalanceSheet,
  closePeriod,
  reopenPeriod,

  // Manufacturing Permissions
  viewProduction,
  createProduction,
  editProduction,
  completeProduction,
  cancelProduction,
  viewBOM,
  createBOM,
  editBOM,
  viewJobWork,
  createJobWork,
  receiveJobWork;
}
