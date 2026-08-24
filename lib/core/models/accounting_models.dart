import 'package:flutter/foundation.dart';

enum AccountType {
  asset('Asset'),
  liability('Liability'),
  equity('Equity'),
  income('Income'),
  expense('Expense');

  final String displayName;
  const AccountType(this.displayName);
}

class Account {
  final String id;
  final String businessId;
  final String code;
  final String name;
  final AccountType type;
  final String groupName; // e.g., 'Current Assets', 'Current Liabilities', 'Indirect Expenses'
  final String? parentId;
  final bool isSystemAccount;
  final bool isActive;
  final double openingDebit;
  final double openingCredit;
  final double currentBalance; // Running tracker in memory
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.businessId,
    required this.code,
    required this.name,
    required this.type,
    required this.groupName,
    this.parentId,
    required this.isSystemAccount,
    required this.isActive,
    required this.openingDebit,
    required this.openingCredit,
    required this.currentBalance,
    required this.createdAt,
  });

  Account copyWith({
    String? name,
    String? code,
    AccountType? type,
    String? groupName,
    String? parentId,
    bool? isSystemAccount,
    bool? isActive,
    double? openingDebit,
    double? openingCredit,
    double? currentBalance,
  }) {
    return Account(
      id: id,
      businessId: businessId,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      groupName: groupName ?? this.groupName,
      parentId: parentId ?? this.parentId,
      isSystemAccount: isSystemAccount ?? this.isSystemAccount,
      isActive: isActive ?? this.isActive,
      openingDebit: openingDebit ?? this.openingDebit,
      openingCredit: openingCredit ?? this.openingCredit,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt,
    );
  }
}

enum JournalStatus {
  draft,
  posted,
  cancelled;
}

class JournalEntry {
  final String id;
  final String businessId;
  final DateTime date;
  final String referenceType; // e.g. 'Invoice', 'Purchase', 'Payment', 'Receipt', 'Expense', 'Production', 'Manual'
  final String referenceId;
  final String narration;
  final JournalStatus status;
  final List<JournalEntryLine> lines;

  const JournalEntry({
    required this.id,
    required this.businessId,
    required this.date,
    required this.referenceType,
    required this.referenceId,
    required this.narration,
    required this.status,
    required this.lines,
  });

  JournalEntry copyWith({
    JournalStatus? status,
    List<JournalEntryLine>? lines,
    String? narration,
  }) {
    return JournalEntry(
      id: id,
      businessId: businessId,
      date: date,
      referenceType: referenceType,
      referenceId: referenceId,
      narration: narration ?? this.narration,
      status: status ?? this.status,
      lines: lines ?? this.lines,
    );
  }
}

class JournalEntryLine {
  final String id;
  final String journalEntryId;
  final String accountId;
  final String accountName;
  final double debit;
  final double credit;
  final String description;

  const JournalEntryLine({
    required this.id,
    required this.journalEntryId,
    required this.accountId,
    required this.accountName,
    required this.debit,
    required this.credit,
    required this.description,
  });
}

class BankAccount {
  final String id;
  final String businessId;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String ifsc;
  final String branch;
  final String accountType; // e.g., 'Savings', 'Current'
  final double openingBalance;
  final double currentBalance;
  final bool isActive;

  const BankAccount({
    required this.id,
    required this.businessId,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.ifsc,
    required this.branch,
    required this.accountType,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
  });

  BankAccount copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? ifsc,
    String? branch,
    String? accountType,
    double? openingBalance,
    double? currentBalance,
    bool? isActive,
  }) {
    return BankAccount(
      id: id,
      businessId: businessId,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      branch: branch ?? this.branch,
      accountType: accountType ?? this.accountType,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum PeriodStatus {
  open,
  locked,
  closed;
}

class AccountingPeriod {
  final String id;
  final String businessId;
  final String name; // e.g. 'FY 2026-27'
  final DateTime startDate;
  final DateTime endDate;
  final PeriodStatus status;

  const AccountingPeriod({
    required this.id,
    required this.businessId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  AccountingPeriod copyWith({
    PeriodStatus? status,
  }) {
    return AccountingPeriod(
      id: id,
      businessId: businessId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
    );
  }
}
