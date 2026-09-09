import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/product-listing/data/repositories/mock_product_repository.dart';
import 'package:frontend/features/product-listing/presentation/pages/product_listing_page.dart';
import 'package:frontend/features/product-listing/presentation/providers/billing_cart_provider.dart';

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
      expect(find.text('Scanned Products (0)'), findsOneWidget);
      expect(find.text('No Products Added Yet'), findsOneWidget);

      // Simulate TVS-E device scanning Maggi (8901000100712)
      await simulateBarcodeScan(tester, '8901000100712');

      // Product is added!
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, '8901000100712');
      expect(find.text('Scanned Products (1)'), findsOneWidget);
      expect(find.textContaining('Maggi 2-Minute Noodles'), findsWidgets);
    });

    testWidgets('TVS-E scanner scan of physical unrecognized barcode auto-creates item and adds to invoice', (tester) async {
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

      // Product is auto-created and added to cart immediately without 404!
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, unknownBarcode);
      expect(find.text('Scanned Products (1)'), findsOneWidget);
      expect(find.textContaining('Item #$unknownBarcode'), findsWidgets);
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

      // Switched back to POS billing view and item is present in cart!
      expect(find.text('Order Summary'), findsOneWidget);
      final cartState = container.read(billingCartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.product.barcode, '5449000200427');
      expect(find.textContaining('Coca Cola'), findsWidgets);
    });
  });
}
