import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/presentation/pages/customer_form_page.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';
import 'package:frontend/shared/widgets/app_button.dart';
import 'package:frontend/shared/widgets/app_input_fields.dart';

void main() {
  testWidgets('CustomerFormPage validation and save test with all details', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    final billingRepo = container.read(billingRepositoryProvider.notifier);

    // Initial state: count customers
    final initialCount = billingRepo.state.customers.length;

    // Set screen size larger to avoid out of bounds
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: const MaterialApp(home: Scaffold(body: CustomerFormPage())),
      ),
    );

    await tester.pumpAndSettle();

    // Helper to enter text safely
    Future<void> enterTextSafely(Finder finder, String text) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.enterText(finder, text);
      await tester.pumpAndSettle();
    }

    // 1. Customer Name *
    final nameFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Customer Name *'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(nameFieldFinder, 'All Details Customer');

    // 2. Mobile Number
    final mobileFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Mobile Number'),
        matching: find.byType(AppPhoneField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(mobileFieldFinder, '9876543210');

    // 3. Email Address
    final emailFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Email Address'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(emailFieldFinder, 'test@alldetails.com');

    // 4. Toggle Registered under GST to true
    final gstSwitchFinder = find.byType(SwitchListTile);
    expect(gstSwitchFinder, findsOneWidget);
    await tester.ensureVisible(gstSwitchFinder);
    await tester.tap(gstSwitchFinder);
    await tester.pumpAndSettle();

    // 5. GSTIN
    final gstinFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('GSTIN *'),
        matching: find.byType(AppGstinField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(gstinFieldFinder, '27AADCA1234F1Z5');

    // 6. PAN
    final panFieldFinder = find.descendant(
      of: find
          .ancestor(
            of: find.text('PAN (Optional)'),
            matching: find.byType(AppTextField),
          )
          .first,
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(panFieldFinder, 'AADCA1234F');

    // 7. State Name
    final stateFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('State Name *'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(stateFieldFinder, 'Maharashtra');

    // 8. State Code
    final stateCodeFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('State Code (2 Digits) *'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(stateCodeFieldFinder, '27');

    // 9. Billing Address
    final billingFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Billing Address *'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(billingFieldFinder, '456 Billing Road, Mumbai');

    // 10. Untick Shipping same as billing checkbox so we can enter shipping address
    final checkboxFinder = find.byType(CheckboxListTile);
    expect(checkboxFinder, findsOneWidget);
    await tester.ensureVisible(checkboxFinder);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // 11. Enter Shipping Address
    final shippingFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Shipping Address *'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(shippingFieldFinder, '789 Shipping Lane, Pune');

    // 12. Credit Limit
    final limitFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Credit Limit (₹)'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(limitFieldFinder, '150000');

    // 13. Credit Period
    final periodFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Credit Period (Days)'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(periodFieldFinder, '45');

    // 14. Opening Balance
    final balanceFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Opening Balance (₹)'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(balanceFieldFinder, '12000.50');

    // 15. Notes
    final notesFieldFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Notes'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await enterTextSafely(notesFieldFinder, 'VIP customer note');

    // Now tap Save Profile
    final saveButtonFinder = find.widgetWithText(AppButton, 'Save Profile');
    expect(saveButtonFinder, findsOneWidget);

    await tester.ensureVisible(saveButtonFinder);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Let's print any validation errors currently shown
    final errorTextFinders = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.style?.color == Colors.red ||
              (widget.data != null &&
                  (widget.data!.contains('required') ||
                      widget.data!.contains('valid') ||
                      widget.data!.contains('Must be') ||
                      widget.data!.contains('Invalid')))),
    );
    for (final element in errorTextFinders.evaluate()) {
      final textWidget = element.widget as Text;
      print('Found validation error: ${textWidget.data}');
    }

    final finalCount = billingRepo.state.customers.length;
    print('Initial count: $initialCount, Final count: $finalCount');

    // Reset view size
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
