import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/product-listing/data/repositories/mock_product_repository.dart';
import 'package:frontend/features/product-listing/presentation/pages/product_listing_page.dart';
import 'package:frontend/features/product-listing/presentation/providers/billing_cart_provider.dart';
import 'package:frontend/features/product-listing/presentation/widgets/product_not_found_dialog.dart';
import 'package:frontend/features/product-listing/presentation/widgets/scanned_products_table.dart';
import 'package:frontend/features/product-listing/domain/entities/product.dart';
import 'package:frontend/features/supplier/presentation/pages/supplier_form_page.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> simulateBarcodeScan(WidgetTester tester, String barcode) async {
    for (int i = 0; i < barcode.length; i++) {
      final char = barcode[i];
      LogicalKeyboardKey key;
      switch (char) {
        case '0': key = LogicalKeyboardKey.digit0; break;
        case '1': key = LogicalKeyboardKey.digit1; break;
        case '2': key = LogicalKeyboardKey.digit2; break;
        case '3': key = LogicalKeyboardKey.digit3; break;
        case '4': key = LogicalKeyboardKey.digit4; break;
        case '5': key = LogicalKeyboardKey.digit5; break;
        case '6': key = LogicalKeyboardKey.digit6; break;
        case '7': key = LogicalKeyboardKey.digit7; break;
        case '8': key = LogicalKeyboardKey.digit8; break;
        case '9': key = LogicalKeyboardKey.digit9; break;
        default: key = LogicalKeyboardKey.keyA; break;
      }
      await tester.sendKeyEvent(key, character: char);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('TVS-E Hardware Barcode Scanner Tests', () {
    testWidgets('TVS-E scanner hardware key burst immediately adds product to active cart', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(MockProductRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial state: cart is empty
      expect(find.text('Products to List (0)'), findsOneWidget);
      expect(find.text('No Products Added Yet'), findsOneWidget);

      // Simulate TVS-E device scanning Maggi (8901000100712)
      await simulateBarcodeScan(tester, '8901000100712');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Product is added!
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, '8901000100712');
      expect(cartState.items.first.quantity, 1);
      expect(find.byType(ProductNotFoundDialog), findsNothing);
      expect(find.text('Products to List (1)'), findsOneWidget);
      expect(find.textContaining('Maggi 2-Minute Noodles'), findsWidgets);

      // Scanning the same database product AGAIN directly increments quantity and NEVER opens dialog
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 650)));
      await simulateBarcodeScan(tester, '8901000100712');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProductNotFoundDialog), findsNothing);
      expect(container.read(billingCartProvider).items.first.quantity, 2);
    });

    testWidgets('TVS-E scanner scan of physical unrecognized barcode opens List New Product dialog without 404 crash', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(MockProductRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Simulate TVS-E device scanning an unknown physical barcode
      const unknownBarcode = '8906001234567';
      await simulateBarcodeScan(tester, unknownBarcode);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ProductNotFoundDialog opens gracefully without 404 crash!
      expect(find.text('List New Product'), findsOneWidget);
      expect(find.textContaining(unknownBarcode), findsWidgets);

      // Fill in product name, category, sub-category, variant, gst rate, unit price, and quantity
      final nameField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Kurkure') == true),
      );
      final categoryField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Groceries') == true),
      );
      final subCategoryField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Chips') == true),
      );
      final variantField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('500g') == true),
      );
      final gstRateField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.suffixText?.contains('% GST') == true),
      );
      final priceField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Enter price') == true),
      );
      final quantityField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '1'),
      );

      await tester.enterText(nameField, 'Amul Butter 100g');
      await tester.enterText(categoryField, 'Dairy');
      await tester.enterText(subCategoryField, 'Dairy Products');
      await tester.enterText(variantField, '100g Bar');
      await tester.enterText(gstRateField, '12.0');
      await tester.enterText(priceField, '58.00');
      await tester.enterText(quantityField, '5');
      await tester.pump();

      // Tap "Add to Listing" button
      final addBtn = find.widgetWithText(ElevatedButton, 'Add to Listing');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now product is in the listing with manual category, gst rate, subCategory, variant, and quantity 5!
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, unknownBarcode);
      expect(cartState.items.first.product.category, 'Dairy');
      expect(cartState.items.first.product.subCategory, 'Dairy Products');
      expect(cartState.items.first.product.variant, '100g Bar');
      expect(cartState.items.first.product.gstRate, 12.0);
      expect(cartState.items.first.quantity, 5);
      expect(find.text('Products to List (1)'), findsOneWidget);
      expect(find.textContaining('Amul Butter 100g'), findsWidgets);
      expect(find.text('100g Bar'), findsWidgets);

      // Rescan the SAME barcode: it is now in the listing & DB
      // Must directly increment quantity in list section and NOT open ProductNotFoundDialog!
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 650)));
      await simulateBarcodeScan(tester, unknownBarcode);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProductNotFoundDialog), findsNothing);
      expect(container.read(billingCartProvider).items.first.quantity, 6);
      expect(find.text('Products to List (1)'), findsOneWidget);
    });

    testWidgets('TVS-E scanner scan while on Catalogue tab auto-switches to POS billing and adds item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(MockProductRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Catalogue tab
      await tester.tap(find.text('Catalogue Directory'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Product List'), findsOneWidget);

      // Simulate TVS-E scan of Coca Cola (5449000200427)
      await simulateBarcodeScan(tester, '5449000200427');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switched back to POS billing view and item is present in cart!
      expect(find.text('Listing Summary'), findsOneWidget);
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, '5449000200427');
      expect(find.textContaining('Coca Cola'), findsWidgets);
    });

    testWidgets('Products to list section allows increasing and decreasing item quantity', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(MockProductRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scan Maggi
      await simulateBarcodeScan(tester, '8901000100712');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(billingCartProvider).items.first.quantity, 1);

      // Tap quantity increment (+) in ScannedProductsTable
      final addQtyBtn = find.descendant(
        of: find.byType(ScannedProductsTable),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.add && w.size == 13.0),
      );
      expect(addQtyBtn, findsOneWidget);
      await tester.tap(addQtyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Quantity increased to 2
      expect(container.read(billingCartProvider).items.first.quantity, 2);

      // Tap quantity decrement (-) in ScannedProductsTable
      final removeQtyBtn = find.descendant(
        of: find.byType(ScannedProductsTable),
        matching: find.byIcon(Icons.remove),
      );
      expect(removeQtyBtn, findsOneWidget);
      await tester.tap(removeQtyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Quantity decreased back to 1
      expect(container.read(billingCartProvider).items.first.quantity, 1);
    });

    testWidgets('List New Product dialog opens SupplierFormPage as modal dialog without losing filled product details', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(MockProductRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scan unknown barcode to open ProductNotFoundDialog
      const unknownBarcode = '8906009999999';
      await simulateBarcodeScan(tester, unknownBarcode);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('List New Product'), findsOneWidget);

      // Enter product name
      final nameField = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Kurkure') == true),
      );
      await tester.enterText(nameField, 'Draft Product ABC');
      await tester.pump();

      // Click outside dialog to verify barrierDismissible is false and dialog is NOT dismissed
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('List New Product'), findsOneWidget);
      expect(find.text('Draft Product ABC'), findsOneWidget);

      // Tap "New" supplier button in ProductSupplierField
      final newSupplierBtn = find.descendant(
        of: find.byType(ProductNotFoundDialog),
        matching: find.widgetWithText(OutlinedButton, 'New'),
      );
      expect(newSupplierBtn, findsOneWidget);
      await tester.ensureVisible(newSupplierBtn);
      await tester.tap(newSupplierBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // SupplierFormPage dialog is now open on top!
      expect(find.byType(SupplierFormPage), findsOneWidget);
      expect(find.text('New Supplier Profile'), findsOneWidget);

      // Tap Cancel on SupplierFormPage dialog
      final cancelSupplierBtn = find.descendant(
        of: find.byType(SupplierFormPage),
        matching: find.widgetWithText(OutlinedButton, 'Cancel'),
      );
      expect(cancelSupplierBtn, findsOneWidget);
      await tester.tap(cancelSupplierBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // SupplierFormPage is closed and we are still in ProductNotFoundDialog with 'Draft Product ABC' intact!
      expect(find.byType(SupplierFormPage), findsNothing);
      expect(find.text('List New Product'), findsOneWidget);
      expect(find.text('Draft Product ABC'), findsOneWidget);
    });

    testWidgets('Existing product barcode stock addition accumulates stock and quantity in database', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockProductRepository();
      // Coca Cola (5449000200427) has initial stock = 60
      final initialProduct = await repo.findProductByBarcode('5449000200427');
      expect(initialProduct, isNotNull);
      expect(initialProduct!.stock, 60);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListingPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Scan Coca Cola (5449000200427)
      await simulateBarcodeScan(tester, '5449000200427');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(billingCartProvider).items.length, 1);
      expect(container.read(billingCartProvider).items.first.quantity, 1);

      // Increase quantity to 5 via increment button (tap 4 times)
      final addQtyBtn = find.byIcon(Icons.add);
      expect(addQtyBtn, findsOneWidget);
      for (int i = 0; i < 4; i++) {
        await tester.tap(addQtyBtn);
        await tester.pump();
      }
      expect(container.read(billingCartProvider).items.first.quantity, 5);

      // 2. Save products to database
      final saveBtn = find.textContaining('Save Products to Database');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify that database product stock has been incremented: 60 + 5 = 65!
      final updatedProduct = await repo.findProductByBarcode('5449000200427');
      expect(updatedProduct, isNotNull);
      expect(updatedProduct!.stock, 65);

      // Dismiss the success dialog if present
      final okBtn = find.widgetWithText(ElevatedButton, 'OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // 3. Scan again and add custom product with same barcode
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 650)));
      await container.read(billingCartProvider.notifier).addCustomProductAndAddToCart(
        const Product(
          id: 'prod_custom_test_coke',
          name: 'Coca Cola 500ml',
          barcode: '5449000200427',
          sku: 'CC-500ML',
          category: 'Beverages',
          sellingPrice: 40.00,
          purchasePrice: 32.00,
          mrp: 50.00,
          gstRate: 18.0,
          stock: 10,
          unit: 'btl',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify stock accumulated: 65 + 10 = 75!
      final reUpdatedProduct = await repo.findProductByBarcode('5449000200427');
      expect(reUpdatedProduct, isNotNull);
      expect(reUpdatedProduct!.stock, 75);
    });
  });
}

