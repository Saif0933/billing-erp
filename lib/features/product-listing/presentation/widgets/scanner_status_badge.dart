import 'package:flutter/material.dart';

/// Visual status indicator for USB/Bluetooth HID Barcode Scanner.
class ScannerStatusBadge extends StatefulWidget {
  final bool isReady;
  final String label;

  const ScannerStatusBadge({
    super.key,
    this.isReady = true,
    this.label = 'USB / Bluetooth Scanner Ready',
  });

  @override
  State<ScannerStatusBadge> createState() => _ScannerStatusBadgeState();
}

class _ScannerStatusBadgeState extends State<ScannerStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isReady
            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isReady
              ? (isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC))
              : (isDark ? Colors.red.shade800 : Colors.red.shade300),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isReady
                      ? Color.fromRGBO(22, 163, 74, _pulseAnimation.value)
                      : Colors.redAccent,
                  boxShadow: widget.isReady
                      ? [
                          BoxShadow(
                            color: Color.fromRGBO(34, 197, 94, _pulseAnimation.value * 0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.isReady ? widget.label : 'Scanner Disconnected',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: widget.isReady
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D))
                  : (isDark ? Colors.red.shade200 : Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
