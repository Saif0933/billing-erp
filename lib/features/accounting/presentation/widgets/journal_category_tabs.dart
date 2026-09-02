import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_journal_provider.dart';

class JournalCategoryTabs extends ConsumerWidget {
  const JournalCategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(journalFilterProvider);
    final notifier = ref.read(journalFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      'Journal List',
      'Drafts',
      'Recurring Journals',
      'Journal Templates',
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
