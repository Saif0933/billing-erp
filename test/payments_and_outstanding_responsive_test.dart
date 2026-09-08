import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/customer/presentation/providers/customer_provider.dart';
import 'package:frontend/features/supplier/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/payments/presentation/pages/receipt_entry_page.dart';
import 'package:frontend/features/payments/presentation/pages/payment_entry_page.dart';
import 'package:frontend/features/accounting/presentation/pages/outstanding_page.dart';
import 'package:frontend/features/accounting/presentation/providers/outstanding_provider.dart';
import 'package:frontend/features/accounting/data/models/outstanding_dto.dart';

class TestCustomerNotifier extends CustomerListNotifier {
  TestCustomerNotifier(super.apiService, super.ref, CustomerListState initial) {
    state = initial;
  }
  @override
  Future<void> loadCustomers({bool refresh = false}) async {}
}

class TestSupplierNotifier extends SupplierListNotifier {
  TestSupplierNotifier(super.apiService, super.ref, SupplierListState initial) {
    state = initial;
  }
  @override
  Future<void> loadSuppliers({bool refresh = false}) async {}
}

class TestOutstandingNotifier extends OutstandingNotifier {
  TestOutstandingNotifier(super.apiService, super.ref, OutstandingState initial) {
    state = initial;
  }

  @override
  Future<void> loadData() async {}
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const sampleCustomer = Customer(
    id: 'c1',
    name: 'Sharma Electronics & Electricals Ltd',
    type: 'Wholesale',
    gstin: '27AAAAA0000A1Z5',
    pan: 'AAAAA0000A',
    mobile: '9876543210',
    email: 'contact@sharmaelec.com',
    billingAddress: 'Mumbai, Maharashtra',
    shippingAddress: 'Mumbai, Maharashtra',
    state: 'Maharashtra',
    stateCode: '27',
    creditLimit: 50000.0,
    creditPeriod: 30,
    openingBalance: 0.0,
    currentBalance: 12500.0,
    customerGroup: 'Wholesale',
    notes: 'Premium customer',
    isRegistered: true,
  );

  const sampleSupplier = Supplier(
    id: 's1',
    name: 'National Raw Materials & Steel Traders Pvt Ltd',
    gstin: '24BBBBB1111B1Z2',
    pan: 'BBBBB1111B',
    mobile: '9123456780',
    email: 'sales@nationalmaterials.com',
    address: 'Ahmedabad, Gujarat',
    state: 'Gujarat',
    stateCode: '24',
    creditTerms: 45,
    openingBalance: 0.0,
    currentBalance: 8520.0,
    supplierGroup: 'Raw Materials',
    notes: 'Primary steel supplier',
  );

  final sampleOutstandingItems = [
    OutstandingItemDto(
      id: 'inv_101',
      refNumber: 'INV-2026-0001',
      date: DateTime(2026, 8, 15),
      dueDate: DateTime(2026, 9, 1),
      partyId: 'c1',
      partyName: 'Sharma Electronics & Electricals Ltd',
      partyMobile: '9876543210',
      amount: 45000.0,
      paidAmount: 10000.0,
      balance: 35000.0,
      ageDays: 24,
      statusLabel: 'OVERDUE',
      bucket: '0-30',
    ),
    OutstandingItemDto(
      id: 'inv_102',
      refNumber: 'INV-2026-0002',
      date: DateTime(2026, 7, 10),
      dueDate: DateTime(2026, 7, 25),
      partyId: 'c2',
      partyName: 'Apex Digital Hub',
      partyMobile: '9822001122',
      amount: 22000.0,
      paidAmount: 0.0,
      balance: 22000.0,
      ageDays: 60,
      statusLabel: 'OVERDUE',
      bucket: '31-60',
    ),
  ];

  final sampleSummary = OutstandingSummaryResponseDto(
    receivables: OutstandingCategorySummaryDto(
      totalOutstanding: 57000.0,
      dueToday: 12000.0,
      totalOverdue: 45000.0,
      totalPending: 0.0,
      count: 2,
      ageingBuckets: const AgeingBucketsDto(
        bucket0To30: 35000.0,
        bucket31To60: 22000.0,
        bucket61To90: 0.0,
        bucket91Plus: 0.0,
      ),
    ),
    payables: OutstandingCategorySummaryDto(
      totalOutstanding: 85000.0,
      dueToday: 0.0,
      totalOverdue: 85000.0,
      totalPending: 0.0,
      count: 1,
      ageingBuckets: const AgeingBucketsDto(
        bucket0To30: 85000.0,
        bucket31To60: 0.0,
        bucket61To90: 0.0,
        bucket91Plus: 0.0,
      ),
    ),
    netWorkingCapital: -28000.0,
  );

  group('ReceiptEntryPage Responsive Layout Tests', () {
    testWidgets('ReceiptEntryPage renders cleanly on Mobile without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            customerProvider.overrideWith((ref) => TestCustomerNotifier(
                  ref.watch(customerApiServiceProvider),
                  ref,
                  const CustomerListState(customers: [sampleCustomer]),
                )),
          ],
          child: const MaterialApp(home: ReceiptEntryPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Payment Receipt'), findsOneWidget);
      expect(find.text('Receipt Parameters'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ReceiptEntryPage renders cleanly on Desktop without overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            customerProvider.overrideWith((ref) => TestCustomerNotifier(
                  ref.watch(customerApiServiceProvider),
                  ref,
                  const CustomerListState(customers: [sampleCustomer]),
                )),
          ],
          child: const MaterialApp(home: ReceiptEntryPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Payment Receipt'), findsOneWidget);
      expect(find.text('Receipt Parameters'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PaymentEntryPage Responsive Layout Tests', () {
    testWidgets('PaymentEntryPage renders cleanly on Mobile without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            supplierProvider.overrideWith((ref) => TestSupplierNotifier(
                  ref.watch(supplierApiServiceProvider),
                  ref,
                  const SupplierListState(suppliers: [sampleSupplier]),
                )),
          ],
          child: const MaterialApp(home: PaymentEntryPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Payment Outward'), findsOneWidget);
      expect(find.text('Payment Parameters'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PaymentEntryPage renders cleanly on Desktop without overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            supplierProvider.overrideWith((ref) => TestSupplierNotifier(
                  ref.watch(supplierApiServiceProvider),
                  ref,
                  const SupplierListState(suppliers: [sampleSupplier]),
                )),
          ],
          child: const MaterialApp(home: PaymentEntryPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Payment Outward'), findsOneWidget);
      expect(find.text('Payment Parameters'), findsOneWidget);
      expect(find.text('Save Entry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('OutstandingPage Responsive Layout Tests', () {
    testWidgets('OutstandingPage renders on Mobile (390x844) with cards and metrics', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            outstandingProvider.overrideWith((ref) => TestOutstandingNotifier(
                  ref.watch(outstandingApiServiceProvider),
                  ref,
                  OutstandingState(
                    selectedTab: 'Receivables',
                    summary: sampleSummary,
                    items: sampleOutstandingItems,
                    bucketFilter: 'ALL',
                  ),
                )),
          ],
          child: const MaterialApp(home: OutstandingPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Outstanding Analysis'), findsOneWidget);
      expect(find.text('Receivables'), findsOneWidget);
      expect(find.text('Payables'), findsOneWidget);
      expect(find.text('Total Outstanding Balance'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OutstandingPage renders on narrow Mobile (360x800) with active bucket filter without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            outstandingProvider.overrideWith((ref) => TestOutstandingNotifier(
                  ref.watch(outstandingApiServiceProvider),
                  ref,
                  OutstandingState(
                    selectedTab: 'Receivables',
                    summary: sampleSummary,
                    items: sampleOutstandingItems,
                    bucketFilter: '0-30', // bucket filter active
                  ),
                )),
          ],
          child: const MaterialApp(home: OutstandingPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear Bucket Filter'), findsOneWidget);
      expect(find.text('Ageing Analysis Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OutstandingPage renders on Desktop (1440x900) with wide data table', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            outstandingProvider.overrideWith((ref) => TestOutstandingNotifier(
                  ref.watch(outstandingApiServiceProvider),
                  ref,
                  OutstandingState(
                    selectedTab: 'Receivables',
                    summary: sampleSummary,
                    items: sampleOutstandingItems,
                    bucketFilter: 'ALL',
                  ),
                )),
          ],
          child: const MaterialApp(home: OutstandingPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Outstanding Analysis'), findsOneWidget);
      expect(find.text('Receivables (Customers)'), findsOneWidget);
      expect(find.text('Payables (Suppliers)'), findsOneWidget);
      expect(find.text('Ref Code'), findsOneWidget);
      expect(find.text('Party Name / Contact'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
