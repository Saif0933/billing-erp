import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_statements_provider.dart';

class StatementSummaryCard extends ConsumerWidget {
  const StatementSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialStatementsDataProvider);
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
          // Header: Financial Summary (Current Period)
          Row(
            children: [
              Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Current Period)',
                style: TextStyle(
                  fontSize: 12.5,
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
              // Segmented Donut Chart
              SizedBox(
                width: 95,
                height: 95,
                child: CustomPaint(
                  painter: _FinancialSummaryDonutPainter(
                    income: summary.totalIncome,
                    expenses: summary.totalExpenses,
                    profit: summary.netProfit,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow('Total Income', '₹${_formatCurrency(summary.totalIncome)}', const Color(0xFF16A34A), isDark),
                    const SizedBox(height: 6),
                    _buildLegendRow('Total Expenses', '₹${_formatCurrency(summary.totalExpenses)}', const Color(0xFFDC2626), isDark),
                    const SizedBox(height: 6),
                    _buildLegendRow('Net Profit', '₹${_formatCurrency(summary.netProfit)}', const Color(0xFF2563EB), isDark),
                    const SizedBox(height: 6),
                    _buildLegendRow('Net Profit Margin', '${summary.netProfitMargin}%', const Color(0xFFEA580C), isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Banner: ✔ Your profit increased by ... compared to previous period
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    summary.profitGrowthPercent >= 0
                        ? 'Your profit increased by ${summary.profitGrowthPercent.toStringAsFixed(2)}% compared to previous period'
                        : 'Your profit decreased by ${summary.profitGrowthPercent.abs().toStringAsFixed(2)}% compared to previous period',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color dotColor, bool isDark) {
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
        const SizedBox(width: 6),
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

class _FinancialSummaryDonutPainter extends CustomPainter {
  final double income;
  final double expenses;
  final double profit;

  _FinancialSummaryDonutPainter({
    required this.income,
    required this.expenses,
    required this.profit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final safeProfit = profit > 0 ? profit : 0.0;
    final total = income + expenses + safeProfit;

    if (total <= 0) return;

    final incomeAngle = (income / total) * 2 * math.pi;
    final expenseAngle = (expenses / total) * 2 * math.pi;
    final profitAngle = (safeProfit / total) * 2 * math.pi;

    final greenPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final redPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final bluePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    canvas.drawArc(rect, startAngle, incomeAngle, false, greenPaint);
    startAngle += incomeAngle;
    canvas.drawArc(rect, startAngle, expenseAngle, false, redPaint);
    startAngle += expenseAngle;
    if (profitAngle > 0) {
      canvas.drawArc(rect, startAngle, profitAngle, false, bluePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialSummaryDonutPainter oldDelegate) =>
      oldDelegate.income != income ||
      oldDelegate.expenses != expenses ||
      oldDelegate.profit != profit;
}

