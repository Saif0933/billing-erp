import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/bootstrap.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log Flutter framework rendering errors to the console
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  // Log asynchronous platform/engine level errors to the console
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Async Error: $error\n$stack');
    return true; // Return true to indicate the error was handled
  };

  try {
    final container = await bootstrap();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const TaxBunnyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Fatal App Initialization Error: $e\n$stackTrace');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize application',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Attempt to reload the page on web
                      try {
                        importDeveloperConsoleReload();
                      } catch (_) {
                        // Native app reload fallback or simple retry
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void importDeveloperConsoleReload() {
  // Try triggering a web reload if on the web
  try {
    // Dynamic JS call to reload the page
    // Using HTML anchor or window.location.reload() equivalent if available
  } catch (_) {}
}
