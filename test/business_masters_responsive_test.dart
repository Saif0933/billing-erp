import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/customer/presentation/pages/customer_page.dart';
import 'package:frontend/features/customer/presentation/providers/customer_provider.dart';
import 'package:frontend/features/customer/data/models/customer_dto.dart';
import 'package:frontend/features/supplier/presentation/pages/supplier_page.dart';
import 'package:frontend/features/supplier/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/supplier/data/models/supplier_dto.dart';
import 'package:frontend/features/service/presentation/pages/service_page.dart';
import 'package:frontend/features/service/presentation/providers/service_provider.dart';
import 'package:frontend/features/service/data/models/service_dto.dart';
import 'package:frontend/features/product-listing/presentation/pages/product_listing_page.dart';

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

class TestServiceNotifier extends ServiceListNotifier {
  TestServiceNotifier(super.apiService, super.ref, ServiceListState initial) {
    state = initial;
  }
  @override
  Future<void> loadServices({bool refresh = false}) async {}
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

  const sampleCustomerMetrics = CustomerMetricsDto(
    totalCustomers: 25,
    activeCustomers: 22,
    registeredCustomers: 18,
    totalReceivables: 14520.50,
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

  const sampleSupplierMetrics = SupplierMetricsDto(
    totalSuppliers: 15,
    activeSuppliers: 12,
    registeredSuppliers: 10,
    totalPayable: 8520.0,
  );

  const sampleService = Service(
    id: 'srv1',
    name: 'Enterprise IT Consulting & Cloud Deployment',
    code: 'SRV-CLOUD-01',
    sacCode: '998313',
    description: 'Cloud deployment and architecture review',
    rate: 2500.0,
    gstRate: 18.0,
    unit: 'Hour',
    discount: 0.0,
    incomeLedger: 'Service Income',
    isActive: true,
  );

  const sampleServiceMetrics = ServiceMetricsDto(
    totalServices: 10,
    activeServices: 9,
    gstApplicableServices: 8,
    averageRate: 1500.0,
  );

  group('Business Masters Responsive UI Tests', () {
    testWidgets('CustomerPage renders properly on Mobile (390x844) without overflow', (tester) async {
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
                  const CustomerListState(
                    customers: [sampleCustomer],
                    metrics: sampleCustomerMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: CustomerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Directory'), findsOneWidget);
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('Active Customers'), findsOneWidget);
      expect(find.text('GST Registered'), findsOneWidget);
      expect(find.text('Total Receivables'), findsOneWidget);
      expect(find.text(sampleCustomer.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerPage renders properly on Desktop (1440x900) without overflow', (tester) async {
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
                  const CustomerListState(
                    customers: [sampleCustomer],
                    metrics: sampleCustomerMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: CustomerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Directory'), findsOneWidget);
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('GSTIN'), findsOneWidget);
      expect(find.text(sampleCustomer.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SupplierPage renders properly on Mobile (390x844) without overflow', (tester) async {
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
                  const SupplierListState(
                    suppliers: [sampleSupplier],
                    metrics: sampleSupplierMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: SupplierPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Supplier Directory'), findsOneWidget);
      expect(find.text('Total Suppliers'), findsOneWidget);
      expect(find.text('Active Suppliers'), findsOneWidget);
      expect(find.text('Total Payables'), findsOneWidget);
      expect(find.text(sampleSupplier.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SupplierPage renders properly on Desktop (1440x900) without overflow', (tester) async {
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
                  const SupplierListState(
                    suppliers: [sampleSupplier],
                    metrics: sampleSupplierMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: SupplierPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Supplier Directory'), findsOneWidget);
      expect(find.text('Supplier Name'), findsOneWidget);
      expect(find.text(sampleSupplier.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ServicePage renders properly on Mobile (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            serviceProvider.overrideWith((ref) => TestServiceNotifier(
                  ref.watch(serviceApiServiceProvider),
                  ref,
                  const ServiceListState(
                    services: [sampleService],
                    metrics: sampleServiceMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: ServicePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services Directory'), findsOneWidget);
      expect(find.text('Total Services'), findsOneWidget);
      expect(find.text('Active Services'), findsOneWidget);
      expect(find.text('Avg Billing Rate'), findsOneWidget);
      expect(find.text(sampleService.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ServicePage renders properly on Desktop (1440x900) without overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            serviceProvider.overrideWith((ref) => TestServiceNotifier(
                  ref.watch(serviceApiServiceProvider),
                  ref,
                  const ServiceListState(
                    services: [sampleService],
                    metrics: sampleServiceMetrics,
                    isLoading: false,
                  ),
                )),
          ],
          child: const MaterialApp(home: ServicePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services Directory'), findsOneWidget);
      expect(find.text('Service Info'), findsOneWidget);
      expect(find.text(sampleService.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductListingPage renders properly on Mobile (390x844) and Desktop (1440x900) without overflow', (tester) async {
      // Mobile Viewport
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: ProductListingPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Sale / Create Invoice'), findsOneWidget);
      expect(find.text('POS Billing'), findsOneWidget);
      expect(find.text('Catalogue'), findsOneWidget);

      // Switch to Catalogue tab on Mobile
      await tester.tap(find.text('Catalogue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Product List'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Desktop Viewport
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Catalogue Directory'), findsOneWidget);
      expect(find.text('Product List'), findsOneWidget);

      // Switch back to POS tab on Desktop
      await tester.tap(find.text('Barcode POS Billing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Order Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
