class DashboardKpiItem {
  final String title;
  final double value;
  final String formattedValue;
  final String subtitle;
  final int count;
  final String percentage;
  final bool isPositive;

  const DashboardKpiItem({
    required this.title,
    required this.value,
    required this.formattedValue,
    required this.subtitle,
    required this.count,
    required this.percentage,
    required this.isPositive,
  });

  factory DashboardKpiItem.fromJson(Map<String, dynamic> json) {
    return DashboardKpiItem(
      title: json['title'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      formattedValue: json['formattedValue'] as String? ?? '₹ 0.00',
      subtitle: json['subtitle'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: json['percentage'] as String? ?? '0%',
      isPositive: json['isPositive'] as bool? ?? true,
    );
  }
}

class DashboardKpiMetrics {
  final DashboardKpiItem todaysSales;
  final DashboardKpiItem todaysPurchases;
  final DashboardKpiItem totalReceivables;
  final DashboardKpiItem totalPayables;

  const DashboardKpiMetrics({
    required this.todaysSales,
    required this.todaysPurchases,
    required this.totalReceivables,
    required this.totalPayables,
  });

  factory DashboardKpiMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardKpiMetrics(
      todaysSales: DashboardKpiItem.fromJson(
        json['todaysSales'] as Map<String, dynamic>? ?? {},
      ),
      todaysPurchases: DashboardKpiItem.fromJson(
        json['todaysPurchases'] as Map<String, dynamic>? ?? {},
      ),
      totalReceivables: DashboardKpiItem.fromJson(
        json['totalReceivables'] as Map<String, dynamic>? ?? {},
      ),
      totalPayables: DashboardKpiItem.fromJson(
        json['totalPayables'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DashboardTrendData {
  final String period;
  final List<String> labels;
  final List<double> sales;
  final List<double> purchases;

  const DashboardTrendData({
    required this.period,
    required this.labels,
    required this.sales,
    required this.purchases,
  });

  factory DashboardTrendData.fromJson(Map<String, dynamic> json) {
    return DashboardTrendData(
      period: json['period'] as String? ?? 'this_year',
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sales: (json['sales'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      purchases: (json['purchases'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}

class DashboardBankItem {
  final String id;
  final String name;
  final String accountNumberMasked;
  final double amount;
  final String formattedAmount;
  final String iconColor;
  final String icon;
  final bool isSquare;
  final String category;
  final String status;

  const DashboardBankItem({
    required this.id,
    required this.name,
    required this.accountNumberMasked,
    required this.amount,
    required this.formattedAmount,
    required this.iconColor,
    required this.icon,
    required this.isSquare,
    required this.category,
    required this.status,
  });

  factory DashboardBankItem.fromJson(Map<String, dynamic> json) {
    return DashboardBankItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      accountNumberMasked: json['accountNumberMasked'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formattedAmount'] as String? ?? '₹ 0.00',
      iconColor: json['iconColor'] as String? ?? '#10B981',
      icon: json['icon'] as String? ?? 'account_balance',
      isSquare: json['isSquare'] as bool? ?? false,
      category: json['category'] as String? ?? 'bank',
      status: json['status'] as String? ?? 'Active',
    );
  }
}

class DashboardCashBankSummary {
  final double totalBalance;
  final String formattedTotalBalance;
  final List<DashboardBankItem> accounts;

  const DashboardCashBankSummary({
    required this.totalBalance,
    required this.formattedTotalBalance,
    required this.accounts,
  });

  factory DashboardCashBankSummary.fromJson(Map<String, dynamic> json) {
    return DashboardCashBankSummary(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      formattedTotalBalance:
          json['formattedTotalBalance'] as String? ?? '₹ 0.00',
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardBankItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DashboardInventorySummary {
  final int totalItems;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValuation;
  final String formattedTotalValuation;

  const DashboardInventorySummary({
    required this.totalItems,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalValuation,
    required this.formattedTotalValuation,
  });

  factory DashboardInventorySummary.fromJson(Map<String, dynamic> json) {
    return DashboardInventorySummary(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      inStockCount: (json['inStockCount'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
      totalValuation: (json['totalValuation'] as num?)?.toDouble() ?? 0.0,
      formattedTotalValuation:
          json['formattedTotalValuation'] as String? ?? '₹ 0.00',
    );
  }
}

class DashboardRecentSalesItem {
  final String id;
  final String invoiceNumber;
  final String date;
  final String customerName;
  final double amount;
  final String formattedAmount;
  final String status;
  final bool isPaid;

  const DashboardRecentSalesItem({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.amount,
    required this.formattedAmount,
    required this.status,
    required this.isPaid,
  });

  factory DashboardRecentSalesItem.fromJson(Map<String, dynamic> json) {
    return DashboardRecentSalesItem(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      date: json['date'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Walk-in Customer',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formattedAmount'] as String? ?? '₹ 0.00',
      status: json['status'] as String? ?? 'Paid',
      isPaid: json['isPaid'] as bool? ?? true,
    );
  }
}

class DashboardRecentPurchasesItem {
  final String id;
  final String purchaseNumber;
  final String date;
  final String supplierName;
  final double amount;
  final String formattedAmount;
  final String status;
  final bool isReceived;

  const DashboardRecentPurchasesItem({
    required this.id,
    required this.purchaseNumber,
    required this.date,
    required this.supplierName,
    required this.amount,
    required this.formattedAmount,
    required this.status,
    required this.isReceived,
  });

  factory DashboardRecentPurchasesItem.fromJson(Map<String, dynamic> json) {
    return DashboardRecentPurchasesItem(
      id: json['id'] as String? ?? '',
      purchaseNumber: json['purchaseNumber'] as String? ?? '',
      date: json['date'] as String? ?? '',
      supplierName: json['supplierName'] as String? ?? 'Supplier',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formattedAmount'] as String? ?? '₹ 0.00',
      status: json['status'] as String? ?? 'Received',
      isReceived: json['isReceived'] as bool? ?? true,
    );
  }
}

class DashboardReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String iconColor;
  final String route;
  final int count;
  final String priority;

  const DashboardReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.route,
    required this.count,
    required this.priority,
  });

  factory DashboardReminderItem.fromJson(Map<String, dynamic> json) {
    return DashboardReminderItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'notifications',
      iconColor: json['iconColor'] as String? ?? '#F59E0B',
      route: json['route'] as String? ?? '/dashboard',
      count: (json['count'] as num?)?.toInt() ?? 0,
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

class DashboardOverviewData {
  final DashboardKpiMetrics metrics;
  final DashboardTrendData trend;
  final DashboardCashBankSummary cashAndBank;
  final DashboardInventorySummary inventory;
  final List<DashboardRecentSalesItem> recentSales;
  final List<DashboardRecentPurchasesItem> recentPurchases;
  final List<DashboardReminderItem> reminders;
  final String generatedAt;
  final bool isCached;

  const DashboardOverviewData({
    required this.metrics,
    required this.trend,
    required this.cashAndBank,
    required this.inventory,
    required this.recentSales,
    required this.recentPurchases,
    required this.reminders,
    required this.generatedAt,
    this.isCached = false,
  });

  factory DashboardOverviewData.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewData(
      metrics: DashboardKpiMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>? ?? {},
      ),
      trend: DashboardTrendData.fromJson(
        json['trend'] as Map<String, dynamic>? ?? {},
      ),
      cashAndBank: DashboardCashBankSummary.fromJson(
        json['cashAndBank'] as Map<String, dynamic>? ?? {},
      ),
      inventory: DashboardInventorySummary.fromJson(
        json['inventory'] as Map<String, dynamic>? ?? {},
      ),
      recentSales: (json['recentSales'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardRecentSalesItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentPurchases: (json['recentPurchases'] as List<dynamic>?)
              ?.map((e) => DashboardRecentPurchasesItem.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardReminderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generatedAt'] as String? ?? '',
      isCached: json['isCached'] as bool? ?? false,
    );
  }
}
