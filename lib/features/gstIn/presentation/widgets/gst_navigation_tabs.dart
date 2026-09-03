import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gst_provider.dart';

class GstNavigationTabs extends ConsumerWidget {
  const GstNavigationTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(gstActiveTabProvider);
    final notifier = ref.read(gstActiveTabProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      {'label': 'Overview', 'icon': Icons.space_dashboard_outlined},
      {'label': 'Returns', 'icon': Icons.post_add_outlined},
      {'label': 'Payments', 'icon': Icons.payment_outlined},
      {'label': 'Ledger', 'icon': Icons.menu_book_outlined},
      {'label': 'Documents', 'icon': Icons.insert_drive_file_outlined},
      {'label': 'GSTIN Details', 'icon': Icons.badge_outlined},
      {'label': 'Compliance', 'icon': Icons.shield_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final isSelected = activeTab == label;

          return InkWell(
            onTap: () => notifier.setTab(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
