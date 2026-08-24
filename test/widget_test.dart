import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/app_button.dart';
import 'package:frontend/shared/widgets/app_input_fields.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('Renders label and triggers callback', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      expect(tapped, isTrue);
    });

    testWidgets('Loading state disables callback', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              onPressed: () => tapped = true,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Submit'));
      expect(tapped, isFalse);
    });
  });

  group('AppTextField Widget Tests', () {
    testWidgets('Renders label and accepts input text', (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Username',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'bunny');
      expect(controller.text, 'bunny');
    });
  });
}
