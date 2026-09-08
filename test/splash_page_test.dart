import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders image and animated spinner without errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashPage(),
      ),
    );

    // Initial frame
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump some frames to ensure animation runs smoothly without throwing
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
