import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gst_provider.dart';

class GstTaxLiabilityCard extends ConsumerWidget {
  const GstTaxLiabilityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(gstLiabilitySummaryProvider);
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
          // Header Row: Liability Summary (FY 2025-26)
          Row(
            children: [
              Text(
                'Liability Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${summary.financialYear})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Chart & Legend Row
          Row(
            children: [
              // Segmented Donut Chart with Center Text
              SizedBox(
                width: 125,
                height: 125,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(125, 125),
                      painter: _GstLiabilityDonutPainter(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Liability',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${_formatCurrency(summary.totalLiability)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Integrated Tax (IGST)', '₹${_formatCurrency(summary.igst)}', const Color(0xFFEF4444), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('Central Tax (CGST)', '₹${_formatCurrency(summary.cgst)}', const Color(0xFF3B82F6), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('State/UT Tax (SGST)', '₹${_formatCurrency(summary.sgst)}', const Color(0xFFF59E0B), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('Cess', '₹${_formatCurrency(summary.cess)}', const Color(0xFF10B981), isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Box: Paid (This FY) vs Balance (This FY)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                // Left: Paid (This FY)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Paid (This FY)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatCurrency(summary.paidThisFy)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
                // Right: Balance (This FY)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Balance (This FY)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatCurrency(summary.balanceThisFy)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color dotColor, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    if (whole.length <= 3) {
      return '$whole.$dec';
    }

    final lastThree = whole.substring(whole.length - 3);
    final otherNumbers = whole.substring(0, whole.length - 3);

    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedOther,$lastThree.$dec';
  }
}

class _GstLiabilityDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // IGST segment (Red - 43%)
    final redPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // CGST segment (Blue - 28%)
    final bluePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // SGST segment (Orange/Yellow - 28%)
    final orangePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Cess segment (Green - 1%)
    final greenPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw arcs
    canvas.drawArc(rect, -math.pi / 2, math.pi * 0.86, false, redPaint); // 43%
    canvas.drawArc(rect, -math.pi / 2 + math.pi * 0.86, math.pi * 0.56, false, bluePaint); // 28%
    canvas.drawArc(rect, -math.pi / 2 + math.pi * 1.42, math.pi * 0.56, false, orangePaint); // 28%
    canvas.drawArc(rect, -math.pi / 2 + math.pi * 1.98, math.pi * 0.02, false, greenPaint); // 1%
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
