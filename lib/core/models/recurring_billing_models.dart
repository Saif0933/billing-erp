import 'billing_models.dart';

enum RecurringFrequency {
  monthly,
  quarterly,
  halfYearly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.halfYearly:
        return 'Half-Yearly';
      case RecurringFrequency.yearly:
        return 'Yearly';
      case RecurringFrequency.custom:
        return 'Custom';
    }
  }
}

enum RecurringScheduleStatus {
  draft,
  active,
  paused,
  expired,
  cancelled;

  String get displayName {
    switch (this) {
      case RecurringScheduleStatus.draft:
        return 'Draft';
      case RecurringScheduleStatus.active:
        return 'Active';
      case RecurringScheduleStatus.paused:
        return 'Paused';
      case RecurringScheduleStatus.expired:
        return 'Expired';
      case RecurringScheduleStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class RecurringSchedule {
  final String id;
  final String customerId;
  final String customerName;
  final List<InvoiceItem> items;
  final RecurringFrequency frequency;
  final int customFrequencyDays; // used if custom
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextBillingDate;
  final DateTime? lastBillingDate;
  final RecurringScheduleStatus status;
  final bool autoGenerateInvoice;
  final String paymentTerms;
  final String notes;

  const RecurringSchedule({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.frequency,
    this.customFrequencyDays = 30,
    required this.startDate,
    required this.endDate,
    required this.nextBillingDate,
    this.lastBillingDate,
    required this.status,
    this.autoGenerateInvoice = true,
    required this.paymentTerms,
    required this.notes,
  });

  RecurringSchedule copyWith({
    String? customerId,
    String? customerName,
    List<InvoiceItem>? items,
    RecurringFrequency? frequency,
    int? customFrequencyDays,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextBillingDate,
    DateTime? lastBillingDate,
    RecurringScheduleStatus? status,
    bool? autoGenerateInvoice,
    String? paymentTerms,
    String? notes,
  }) {
    return RecurringSchedule(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      frequency: frequency ?? this.frequency,
      customFrequencyDays: customFrequencyDays ?? this.customFrequencyDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      lastBillingDate: lastBillingDate ?? this.lastBillingDate,
      status: status ?? this.status,
      autoGenerateInvoice: autoGenerateInvoice ?? this.autoGenerateInvoice,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
    );
  }
}
