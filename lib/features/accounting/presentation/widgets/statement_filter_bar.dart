import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_statements_provider.dart';

class StatementFilterBar extends ConsumerWidget {
  const StatementFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(financialStatementFilterProvider);
    final notifier = ref.read(financialStatementFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reportTypes = [
      'Profit & Loss Statement',
      'Balance Sheet',
      'Cash Flow Statement',
      'Statement of Changes in Equity',
    ];

    final compareOptions = [
      'Previous Period',
      'Previous Year',
      'Custom Period',
      'None',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Report Type Dropdown
          _buildDropdownFilter(
            label: 'Report Type',
            value: filter.reportTypeLabel,
            items: reportTypes,
            onChanged: (val) {
              if (val != null) {
                FinancialReportType type = FinancialReportType.profitAndLoss;
                if (val == 'Balance Sheet') type = FinancialReportType.balanceSheet;
                if (val == 'Cash Flow Statement') type = FinancialReportType.cashFlow;
                if (val == 'Statement of Changes in Equity') type = FinancialReportType.equityChanges;
                notifier.setReportType(type, val);
              }
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),

          // Date Range Picker Box
          _buildDateRangeBox(context, filter.dateRangeLabel, notifier, isDark),
          const SizedBox(width: 12),

          // Compare With Dropdown
          _buildDropdownFilter(
            label: 'Compare With',
            value: filter.compareWith,
            items: compareOptions,
            onChanged: (val) {
              if (val != null) notifier.setCompareWith(val);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),

          // Filters Button
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeBox(
    BuildContext context,
    String label,
    FinancialStatementNotifier notifier,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (range != null) {
              final fmt =
                  '${range.start.day.toString().padLeft(2, '0')} ${_monthName(range.start.month)} ${range.start.year} – ${range.end.day.toString().padLeft(2, '0')} ${_monthName(range.end.month)} ${range.end.year}';
              notifier.setDateRange(fmt);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
