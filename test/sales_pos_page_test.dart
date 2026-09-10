import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/sales/presentation/pages/pos_page.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('POSPage renders full Sales UI with header, categories, products, and Current Bill', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: POSPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Back Button is present in the top header
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Verify Search Bar and F2 shortcut badge
    expect(find.text('Search product by name, barcode or SKU...'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget);

    // Verify Top Action Buttons
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Hold Bill'), findsOneWidget);
    expect(find.text('Recent Bills'), findsOneWidget);

    // Verify Category Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    expect(find.text('Grocery'), findsOneWidget);

    // Verify Current Bill Panel
    expect(find.text('Current Bill'), findsOneWidget);
    expect(find.text('Bill No. TB/25-26/000123'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsOneWidget);

    // Verify Table Headers
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Rate (₹)'), findsOneWidget);
    expect(find.text('Amount (₹)'), findsOneWidget);

    // Verify Financials matching reference image
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('₹ 203.00'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('₹ 213.16'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Save as Draft'), findsOneWidget);
    expect(find.text('Generate Bill (F8)'), findsOneWidget);
  });

  testWidgets('POSPage category selection filters products correctly', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: POSPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Beverages category
    await tester.tap(find.text('Beverages'));
    await tester.pumpAndSettle();

    // Coca Cola should be visible
    expect(find.text('Coca Cola'), findsOneWidget);

    // Parle-G Biscuit should be filtered out
    expect(find.text('Parle-G Biscuit'), findsNothing);
  });

  testWidgets('POSPage Current Bill displays all cart items clearly on laptop resolution', (tester) async {
    // Typical laptop viewport: 1366 x 768
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: POSPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 4 preloaded cart items are visible in the Current Bill table
    expect(find.text('Parle-G Biscuit'), findsWidgets);
    expect(find.text('Amul Gold Milk'), findsWidgets);
    expect(find.text('Maggi Noodles'), findsWidgets);
    expect(find.text('Coca Cola'), findsWidgets);

    // Verify item indexes #1, #2, #3, #4 exist
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('4'), findsWidgets);

    // Verify total amount calculation
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('₹ 213.16'), findsOneWidget);
  });

  testWidgets('Generate Bill opens SalesBillSuccessDialog with all details visible', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: POSPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Generate Bill (F8)
    await tester.tap(find.text('Generate Bill (F8)'));
    await tester.pumpAndSettle();

    // Dialog title
    expect(find.text('Bill Generated Successfully!'), findsOneWidget);

    // Receipt header
    expect(find.text('TAX BUNNY - RETAIL STORE'), findsOneWidget);
    expect(find.text('Main Branch Terminal'), findsOneWidget);

    // Receipt meta
    expect(find.text('Bill No:'), findsOneWidget);
    expect(find.text('Customer:'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsWidgets);

    // Action buttons
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Print Receipt (Ctrl+P)'), findsOneWidget);
  });
}
