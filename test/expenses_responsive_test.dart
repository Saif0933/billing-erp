import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/expenses/presentation/pages/expense_page.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';

class TestBillingNotifier extends BillingNotifier {
  TestBillingNotifier(super.ref, [List<Expense> initialExpenses = const []]) {
    state = state.copyWith(expenses: initialExpenses);
  }

  @override
  Future<void> addExpense(Expense exp) async {
    state = state.copyWith(expenses: [...state.expenses, exp]);
  }
}

void main() {
  late SharedPreferences prefs;

  final sampleExpenses = [
    Expense(
      id: 'exp_1',
      category: 'Rent',
      date: DateTime(2026, 9, 1),
      vendor: 'Commercial Real Estate Landlords LLP',
      amount: 45000.0,
      gst: 8100.0,
      paymentMode: 'Bank',
      attachmentPath: '',
      notes: 'Monthly head office branch rental payment',
    ),
    Expense(
      id: 'exp_2',
      category: 'Electricity',
      date: DateTime(2026, 9, 3),
      vendor: 'State Electricity Distribution Board',
      amount: 12450.50,
      gst: 0.0,
      paymentMode: 'UPI',
      attachmentPath: '',
      notes: '',
    ),
    Expense(
      id: 'exp_3',
      category: 'Salary',
      date: DateTime(2026, 9, 5),
      vendor: 'Staff Payroll Account - Batch #42',
      amount: 280000.0,
      gst: 0.0,
      paymentMode: 'Bank',
      attachmentPath: '',
      notes: 'Engineering & operations employee salaries',
    ),
    Expense(
      id: 'exp_4',
      category: 'Office Expenses',
      date: DateTime(2026, 9, 7),
      vendor: 'Very Long Stationery & Enterprise Supplies Vendor Private Limited',
      amount: 6780.0,
      gst: 1220.40,
      paymentMode: 'Cash',
      attachmentPath: '',
      notes: 'Pantry supplies, printer ink and stationery refills',
    ),
  ];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Expenses Page Responsive Layout Tests', () {
    testWidgets('ExpensePage renders cleanly on Mobile (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);


      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            billingRepositoryProvider.overrideWith((ref) => TestBillingNotifier(ref, sampleExpenses)),
          ],
          child: const MaterialApp(home: ExpensePage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Business Expenses'), findsOneWidget);
      expect(find.text('Record Expense'), findsOneWidget);
      expect(find.text('Total Recorded Operating Expenses'), findsOneWidget);
      expect(find.text('Commercial Real Estate Landlords LLP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpensePage renders cleanly on narrow Mobile (360x800) with populated list without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            billingRepositoryProvider.overrideWith((ref) => TestBillingNotifier(ref, sampleExpenses)),
          ],
          child: const MaterialApp(home: ExpensePage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Business Expenses'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Staff Payroll Account - Batch #42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpensePage renders cleanly on Desktop (1440x900) with full data table without overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            billingRepositoryProvider.overrideWith((ref) => TestBillingNotifier(ref, sampleExpenses)),
          ],
          child: const MaterialApp(home: ExpensePage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Business Expenses'), findsOneWidget);
      expect(find.text('Record Expense'), findsOneWidget);
      expect(find.text('Total Recorded Operating Expenses'), findsOneWidget);
      // Table column headers
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Vendor / Payee'), findsOneWidget);
      expect(find.text('Tax Included (GST) (₹)'), findsOneWidget);
      expect(find.text('Total Amount (₹)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Record Expense Dialog opens and renders cleanly on narrow Mobile (360x800) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            billingRepositoryProvider.overrideWith((ref) => TestBillingNotifier(ref, sampleExpenses)),
          ],
          child: const MaterialApp(home: ExpensePage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Record Expense"
      final recordBtn = find.text('Record Expense');
      expect(recordBtn, findsOneWidget);
      await tester.tap(recordBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify dialog is visible
      expect(find.text('Record Basic Expense'), findsOneWidget);
      expect(find.text('Expense Category *'), findsOneWidget);
      expect(find.text('Vendor / Payee Name *'), findsOneWidget);
      expect(find.text('Expense Amount (₹) *'), findsOneWidget);
      expect(find.text('GST Tax Included (₹)'), findsOneWidget);
      expect(find.text('Payment Mode'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
