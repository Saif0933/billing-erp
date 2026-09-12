import '../../../../core/models/billing_models.dart';

/// DTO representing an Expense from the backend API
class ExpenseDto {
  final String id;
  final String category;
  final DateTime expenseDate;
  final String vendorOrPayee;
  final double amount;
  final double gstAmount;
  final double taxableAmount;
  final String paymentMode;
  final String? expenseNumber;
  final String? referenceNumber;
  final String? attachmentUrl;
  final String notes;

  const ExpenseDto({
    required this.id,
    required this.category,
    required this.expenseDate,
    required this.vendorOrPayee,
    required this.amount,
    required this.gstAmount,
    required this.taxableAmount,
    required this.paymentMode,
    this.expenseNumber,
    this.referenceNumber,
    this.attachmentUrl,
    required this.notes,
  });

  static String categoryToUiLabel(String cat) {
    switch (cat.toUpperCase()) {
      case 'RENT':
        return 'Rent';
      case 'ELECTRICITY':
        return 'Electricity';
      case 'INTERNET':
        return 'Internet';
      case 'SALARY':
        return 'Salary';
      case 'TRAVEL':
        return 'Travel';
      case 'ADVERTISEMENT':
        return 'Advertisement';
      case 'OFFICE_EXPENSES':
        return 'Office Expenses';
      case 'REPAIRS_MAINTENANCE':
        return 'Repairs & Maintenance';
      case 'OTHER':
      default:
        return 'Other Expenses';
    }
  }

  static String paymentModeToUiLabel(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'BANK':
        return 'Bank Transfer';
      case 'UPI':
        return 'UPI / QR';
      case 'CARD':
        return 'Card';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return 'Other';
    }
  }

  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    final rawCat = json['category']?.toString() ?? 'OTHER';
    final rawMode = json['paymentMode']?.toString() ?? 'CASH';

    DateTime date;
    try {
      date = json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    final amt = (json['amount'] is num)
        ? (json['amount'] as num).toDouble()
        : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;

    final gst = (json['gstAmount'] is num)
        ? (json['gstAmount'] as num).toDouble()
        : double.tryParse(json['gstAmount']?.toString() ?? '0') ?? 0.0;

    final taxable = (json['taxableAmount'] is num)
        ? (json['taxableAmount'] as num).toDouble()
        : double.tryParse(json['taxableAmount']?.toString() ?? '0') ?? (amt - gst);

    return ExpenseDto(
      id: json['id']?.toString() ?? '',
      category: categoryToUiLabel(rawCat),
      expenseDate: date,
      vendorOrPayee: json['vendorOrPayee']?.toString() ?? 'General Expense',
      amount: amt,
      gstAmount: gst,
      taxableAmount: taxable,
      paymentMode: paymentModeToUiLabel(rawMode),
      expenseNumber: json['expenseNumber']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      notes: json['notes']?.toString() ?? '',
    );
  }

  Expense toDomain() {
    return Expense(
      id: id,
      category: category,
      date: expenseDate,
      vendor: vendorOrPayee,
      amount: amount,
      gst: gstAmount,
      paymentMode: paymentMode,
      attachmentPath: attachmentUrl ?? '',
      notes: notes,
    );
  }
}

/// DTO for aggregated Expense Summary
class ExpenseSummaryDto {
  final double totalRecordedExpenses;
  final double totalGstClaimed;
  final double netCashOutflow;
  final int totalExpenseCount;

  const ExpenseSummaryDto({
    required this.totalRecordedExpenses,
    required this.totalGstClaimed,
    required this.netCashOutflow,
    required this.totalExpenseCount,
  });

  factory ExpenseSummaryDto.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryDto(
      totalRecordedExpenses: (json['totalRecordedExpenses'] is num)
          ? (json['totalRecordedExpenses'] as num).toDouble()
          : double.tryParse(json['totalRecordedExpenses']?.toString() ?? '0') ?? 0.0,
      totalGstClaimed: (json['totalGstClaimed'] is num)
          ? (json['totalGstClaimed'] as num).toDouble()
          : double.tryParse(json['totalGstClaimed']?.toString() ?? '0') ?? 0.0,
      netCashOutflow: (json['netCashOutflow'] is num)
          ? (json['netCashOutflow'] as num).toDouble()
          : double.tryParse(json['netCashOutflow']?.toString() ?? '0') ?? 0.0,
      totalExpenseCount: (json['totalExpenseCount'] is num)
          ? (json['totalExpenseCount'] as num).toInt()
          : int.tryParse(json['totalExpenseCount']?.toString() ?? '0') ?? 0,
    );
  }
}
