import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_of_accounts_provider.dart';

class CoaCategoryTabs extends ConsumerWidget {
  const CoaCategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(coaFilterProvider);
    final notifier = ref.read(coaFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      'All Accounts',
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = filter.selectedCategory == cat;

          return InkWell(
            onTap: () => notifier.setSelectedCategory(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
