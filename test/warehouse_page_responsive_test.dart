import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/inventory/presentation/pages/warehouse_page.dart';

void main() {
  group('WarehousePage Responsive Tests', () {
    testWidgets('Renders properly on Mobile viewport without overflow',
        (WidgetTester tester) async {
      // Set mobile screen size (390 x 844, typical modern smartphone)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WarehousePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile app bar title and tab labels
      expect(find.text('Warehouses & Godowns'), findsOneWidget);
      expect(find.text('Godowns'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Tab 1: Configured Godowns section header & add button
      expect(find.text('Configured Godowns'), findsOneWidget);
      expect(find.text('Add New Godown'), findsOneWidget);

      // Verify mobile cards are rendered with warehouse codes
      expect(find.text('M-WH'), findsWidgets);
      expect(find.text('R-ST'), findsWidgets);

      // Switch to Tab 2: Stock Transfer
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Configurations'), findsOneWidget);
      expect(find.text('Add Items to Transfer'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.text('Confirm Transfer'), findsOneWidget);

      // Switch to Tab 3: History Logs
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Stock Transfer History'), findsOneWidget);
      expect(find.text('No stock transfer logs recorded.'), findsOneWidget);

      // Verify no layout overflow or errors were thrown throughout the mobile experience
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders properly on Desktop viewport with full tables',
        (WidgetTester tester) async {
      // Set desktop screen size (1440 x 900)
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WarehousePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Desktop app bar title and tab labels
      expect(find.text('Multi-Warehouse Control Center'), findsOneWidget);
      expect(find.text('Warehouse Locations'), findsOneWidget);
      expect(find.text('Record Stock Transfer'), findsOneWidget);
      expect(find.text('Transfer History Logs'), findsOneWidget);

      // Tab 1: Configured Warehouses section header
      expect(find.text('Configured Warehouses'), findsOneWidget);
      expect(find.text('Configure New Godown'), findsOneWidget);
      expect(find.text('M-WH'), findsWidgets);
      expect(find.text('R-ST'), findsWidgets);

      // Switch to Tab 2: Stock Transfer
      await tester.tap(find.text('Record Stock Transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Configurations'), findsOneWidget);
      expect(find.text('Add Items to Transfer'), findsOneWidget);
      expect(find.text('Submit & Confirm Stock Transfer'), findsOneWidget);

      // Switch to Tab 3: History Logs
      await tester.tap(find.text('Transfer History Logs'));
      await tester.pumpAndSettle();

      expect(find.text('Warehouse Stock Transfer History'), findsOneWidget);
      expect(find.text('No stock transfer logs recorded.'), findsOneWidget);

      // Verify no layout overflow errors on desktop
      expect(tester.takeException(), isNull);
    });
  });
}
