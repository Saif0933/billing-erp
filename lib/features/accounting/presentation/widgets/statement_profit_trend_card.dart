import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_statements_provider.dart';

class StatementProfitTrendCard extends ConsumerWidget {
  const StatementProfitTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialStatementsDataProvider);
    final filter = ref.watch(financialStatementFilterProvider);
    final notifier = ref.read(financialStatementFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Profit Trend + [ Last 6 Months ▾ ] Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filter.trendPeriod,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Last 6 Months', child: Text('Last 6 Months')),
                      DropdownMenuItem(value: 'Last 12 Months', child: Text('Last 12 Months')),
                      DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setTrendPeriod(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Line Chart with Canvas Painted Month Labels & Tooltip Box
          Stack(
            children: [
              SizedBox(
                height: 165,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ProfitTrendLinePainter(
                    points: summary.trendPoints,
                    isDark: isDark,
                  ),
                ),
              ),

              // Tooltip on top right (over May 2026)
              Positioned(
                right: 8,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'May 2026',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '• Net Profit: ₹2,93,480.00',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Legend at Bottom: ■ Net Profit (₹)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Net Profit (₹)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfitTrendLinePainter extends CustomPainter {
  final List<ProfitTrendPoint> points;
  final bool isDark;

  _ProfitTrendLinePainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 32.0;
    const rightPad = 12.0;
    const topPad = 15.0;
    const bottomPad = 24.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    // Y-Axis Gridlines & labels (₹0, ₹1L, ₹2L, ₹3L, ₹4L)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    const maxVal = 400000.0;
    final textStyle = TextStyle(
      fontSize: 9.5,
      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
    );

    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartHeight - (i / 4.0) * chartHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final label = i == 0 ? '₹0' : '₹${i}L';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - 6));
    }

    if (points.isEmpty) return;

    // Build path for line and gradient fill
    final linePath = Path();
    final fillPath = Path();

    final stepX = chartWidth / (points.length - 1);
    final offsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = leftPad + i * stepX;
      final ratio = (points[i].amount / maxVal).clamp(0.0, 1.0);
      final y = topPad + chartHeight - (ratio * chartHeight);
      offsets.add(Offset(x, y));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, topPad + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Paint X-axis month label directly under each point (never causes Flex overflow)
      final monthLabel = points[i].month;
      final displayLabel = size.width < 340 ? monthLabel.split(' ').first : monthLabel;
      final mTextPainter = TextPainter(
        text: TextSpan(
          text: displayLabel,
          style: TextStyle(
            fontSize: size.width < 340 ? 8.5 : 9.5,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      mTextPainter.paint(
        canvas,
        Offset(x - (mTextPainter.width / 2), topPad + chartHeight + 6),
      );
    }

    fillPath.lineTo(offsets.last.dx, topPad + chartHeight);
    fillPath.close();

    // Draw gradient fill
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF16A34A).withValues(alpha: 0.25),
          const Color(0xFF16A34A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(leftPad, topPad, size.width - rightPad, topPad + chartHeight));

    canvas.drawPath(fillPath, gradientPaint);

    // Draw trend line
    final linePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw dots on points
    final dotPaint = Paint()..color = const Color(0xFF16A34A);
    final dotBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final off in offsets) {
      canvas.drawCircle(off, 4.5, dotPaint);
      canvas.drawCircle(off, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
