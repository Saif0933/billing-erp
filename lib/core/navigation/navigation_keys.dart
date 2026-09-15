import 'package:flutter/material.dart';

/// Global root keys accessible across the application for overlays, navigation, and messengers
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
