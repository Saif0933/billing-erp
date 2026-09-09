import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/platform-admin/presentation/pages/platform_admin_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PlatformAdminShellPage renders dashboard cleanly at desktop viewport (1440x900)', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: PlatformAdminShellPage(initialTab: 'dashboard'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('Platform Admin'), findsOneWidget);
    expect(find.text('SUPERADMIN'), findsOneWidget);
    expect(find.text('Multi-Tenant SaaS Infrastructure'), findsOneWidget);

    // Verify sidebar navigation
    expect(find.text('Executive Dashboard'), findsWidgets);
    expect(find.text('Organizations (Tenants)'), findsOneWidget);
    expect(find.text('SaaS Subscriptions'), findsOneWidget);
    expect(find.text('Tenant Onboarding'), findsOneWidget);
    expect(find.text('Product Listing'), findsOneWidget);

    // Verify dashboard content is visible and rendered without errors
    expect(find.text('Platform SuperAdmin'), findsOneWidget);
    expect(find.text('ALL SYSTEMS NORMAL'), findsOneWidget);
    expect(find.text('MONTHLY RECURRING (MRR)'), findsOneWidget);
    expect(find.text('ACTIVE ORGANIZATIONS'), findsOneWidget);
    expect(find.text('TOTAL PLATFORM USERS'), findsOneWidget);
    expect(find.text('SYSTEM HEALTH & UPTIME'), findsOneWidget);
    expect(find.text('Active Tenant Organizations'), findsOneWidget);
  });

  testWidgets('PlatformAdminShellPage renders dashboard cleanly at mobile viewport (390x844)', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const MaterialApp(
          home: PlatformAdminShellPage(initialTab: 'dashboard'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify mobile header
    expect(find.text('Platform Admin'), findsOneWidget);
    expect(find.text('SUPERADMIN'), findsOneWidget);

    // Verify hamburger menu exists on mobile
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Verify bottom navigation bar exists on mobile
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify dashboard content is visible
    expect(find.text('Platform SuperAdmin'), findsOneWidget);
    expect(find.text('MONTHLY RECURRING (MRR)'), findsOneWidget);
  });
}
