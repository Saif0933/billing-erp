import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Fallback to in-memory SharedPreferences if localStorage is blocked or throws an error
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
  );

  return container;
}
