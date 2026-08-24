import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcut {
  final LogicalKeyboardKey key;
  final bool control;
  final bool shift;
  final bool alt;
  final VoidCallback onTrigger;
  final String description;

  const AppShortcut({
    required this.key,
    this.control = false,
    this.shift = false,
    this.alt = false,
    required this.onTrigger,
    required this.description,
  });

  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    
    final bool ctrlPressed = HardwareKeyboard.instance.isControlPressed;
    final bool shiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final bool altPressed = HardwareKeyboard.instance.isAltPressed;

    return event.logicalKey == key &&
        ctrlPressed == control &&
        shiftPressed == shift &&
        altPressed == alt;
  }
}

class GlobalShortcutListener extends StatefulWidget {
  final Widget child;
  final List<AppShortcut> shortcuts;

  const GlobalShortcutListener({
    super.key,
    required this.child,
    required this.shortcuts,
  });

  @override
  State<GlobalShortcutListener> createState() => _GlobalShortcutListenerState();
}

class _GlobalShortcutListenerState extends State<GlobalShortcutListener> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    for (final shortcut in widget.shortcuts) {
      if (shortcut.matches(event)) {
        shortcut.onTrigger();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
