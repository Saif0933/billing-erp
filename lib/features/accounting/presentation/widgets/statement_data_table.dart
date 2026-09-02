import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/financial_statements_provider.dart';

class StatementDataTable extends ConsumerWidget {
  const StatementDataTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialStatementsDataProvider);
    final filter = ref.watch(financialStatementFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header inside Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filter.reportTypeLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'For the period ${filter.dateRangeLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Actions: [ ⬇ Export ] + [ 🖨 Print ] + [ ⋮ ]
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOutlinedBtn(
                      icon: Icons.file_download_outlined,
                      label: 'Export',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Exporting report as PDF...');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildOutlinedBtn(
                      icon: Icons.print_outlined,
                      label: 'Print',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Sending report to printer...');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val == 'share') {
                            Share.share(
                              '${filter.reportTypeLabel}\nTotal Income: ₹13,00,430.00\nTotal Expenses: ₹10,06,950.00\nNet Profit: ₹2,93,480.00',
                            );
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'share', child: Text('Share Statement', style: TextStyle(fontSize: 12.5))),
                          PopupMenuItem(value: 'excel', child: Text('Export to Excel', style: TextStyle(fontSize: 12.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 780,
              child: Column(
                children: [
                  // Table Column Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    child: Row(
                      children: const [
                        Expanded(child: SizedBox()),
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('01 Apr – 31 May 2026', style: _colHeaderStyle),
                              Text('( Current Period )', style: _colSubHeaderStyle),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('01 Feb – 31 Mar 2026', style: _colHeaderStyle),
                              Text('( Previous Period )', style: _colSubHeaderStyle),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text('% Change', textAlign: TextAlign.right, style: _colHeaderStyle),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Section 1: INCOME
                  _buildSectionHeader('INCOME', const Color(0xFF15803D), isDark),
                  ...summary.incomeItems.map((item) => _buildDataRow(item, isDark)),
                  _buildTotalRow(summary.totalIncomeItem, isDark, isIncome: true),
                  const SizedBox(height: 10),

                  // Section 2: EXPENSES
                  _buildSectionHeader('EXPENSES', const Color(0xFFDC2626), isDark),
                  ...summary.expenseItems.map((item) => _buildDataRow(item, isDark)),
                  _buildTotalRow(summary.totalExpenseItem, isDark, isIncome: false),
                  const SizedBox(height: 12),

                  // Section 3: NET PROFIT BANNER ROW
                  _buildNetProfitBannerRow(summary.netProfitItem, isDark),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Footer Note: ⓘ All amounts are in INR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  'All amounts are in INR',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _colHeaderStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
  );

  static const _colSubHeaderStyle = TextStyle(
    fontSize: 10.5,
    color: Color(0xFF64748B),
  );

  Widget _buildSectionHeader(String title, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(StatementLineItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.currentAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.previousAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${item.percentChange.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_upward, size: 12, color: Color(0xFF16A34A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(StatementLineItem item, bool isDark, {required bool isIncome}) {
    final textColor = isIncome
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.currentAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.previousAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${item.percentChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_upward,
                  size: 12,
                  color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitBannerRow(StatementLineItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Net Profit',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.currentAmount)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: Text(
              '₹${_formatCurrency(item.previousAmount)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${item.percentChange.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_upward, size: 13, color: Color(0xFF15803D)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
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
