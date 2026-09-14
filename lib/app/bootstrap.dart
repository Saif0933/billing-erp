import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/firebase_api_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env.development");
  } catch (_) {}

  SharedPreferences sharedPrefs;
  try {
    sharedPrefs = await SharedPreferences.getInstance();
  } catch (e) {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
  );

  // Initialize Firebase Cloud Messaging & Core
  try {
    await container.read(firebaseApiServiceProvider).initialize();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Probe and lock onto active backend URL at startup
  try {
    await container
        .read(apiClientProvider)
        .detectWorkingBaseUrl()
        .timeout(const Duration(milliseconds: 1000));
  } catch (_) {}

  return container;
}
