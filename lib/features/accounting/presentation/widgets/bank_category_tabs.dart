import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bank_accounts_provider.dart';

class BankCategoryTabs extends ConsumerWidget {
  const BankCategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bankFilterProvider);
    final notifier = ref.read(bankFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      'All Accounts',
      'Current Accounts',
      'Savings Accounts',
      'Credit Accounts',
      'Inactive Accounts',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = filter.selectedTab == tab;

          return InkWell(
            onTap: () => notifier.setSelectedTab(tab),
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
                tab,
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
