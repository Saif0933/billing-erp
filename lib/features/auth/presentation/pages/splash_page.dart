import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F4D3F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3FAF6),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Maintain ideal proportions on wider screens (tablet/desktop/web)
            final containerWidth = math.min(screenWidth, 520.0);
            final containerHeight = screenHeight;

            // Geometry relative to splash_clean_extended.png (576 x 1244)
            const double imgW = 576.0;
            const double imgH = 1244.0;
            // Spinner center in extended canvas (top pad = 110, orig center = 810)
            const double spinnerCenterX = 288.0;
            const double spinnerCenterY = 920.0;
            const double spinnerDiameter = 38.0;

            final scale = math.max(
              containerWidth / imgW,
              containerHeight / imgH,
            );

            final renderedW = imgW * scale;
            final renderedH = imgH * scale;

            final dx = (containerWidth - renderedW) / 2.0;
            final dy = (containerHeight - renderedH) / 2.0;

            final spinnerLeft =
                dx + (spinnerCenterX - spinnerDiameter / 2.0) * scale;
            final spinnerTop =
                dy + (spinnerCenterY - spinnerDiameter / 2.0) * scale;
            final scaledSpinnerSize = spinnerDiameter * scale;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8F7F0),
                    Color(0xFFFDFEFD),
                    Color(0xFF0E463E),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: containerWidth,
                  height: containerHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full Splash Artwork
                      Image.asset(
                        'assets/images/splash_clean_extended.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        width: containerWidth,
                        height: containerHeight,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/splash_screen.png',
                            fit: BoxFit.contain,
                          );
                        },
                      ),

                      // Live Animated Spinner Ring matching design
                      Positioned(
                        left: spinnerLeft,
                        top: spinnerTop,
                        width: scaledSpinnerSize,
                        height: scaledSpinnerSize,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _GradientSpinnerPainter(
                                angle: _controller.value * 2 * math.pi,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradientSpinnerPainter extends CustomPainter {
  final double angle;

  _GradientSpinnerPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(2.5, size.width * 0.095);
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final sweepAngle = 1.55 * math.pi; // ~280 degrees arc matching the artwork
    final startAngle = angle;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0x00A7F3D0), // Faded mint
          Color(0x806EE7B7), // Medium mint
          Color(0xFF00C853), // Vibrant emerald green
        ],
        stops: const [0.0, 0.45, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientSpinnerPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
