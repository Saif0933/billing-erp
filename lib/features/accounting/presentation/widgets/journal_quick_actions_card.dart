import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/general_journal_provider.dart';
import 'new_journal_dialog.dart';

class JournalQuickActionsCard extends ConsumerWidget {
  const JournalQuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(generalJournalNotifierProvider.notifier);
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
          // Header: Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Action Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              final tileWidth = isSmall
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 8) / 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 1. New Journal
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.add_circle,
                      iconColor: const Color(0xFF16A34A),
                      title: 'New Journal',
                      subtitle: 'Create new entry',
                      onTap: () => NewJournalDialog.show(context),
                      isDark: isDark,
                    ),
                  ),

                  // 2. Journal Templates
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Journal Templates',
                      subtitle: 'Filter templates',
                      onTap: () => notifier.setSelectedTab('Journal Templates'),
                      isDark: isDark,
                    ),
                  ),

                  // 3. Export Day Book
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.file_download_outlined,
                      iconColor: const Color(0xFF9333EA),
                      title: 'Export Day Book',
                      subtitle: 'Download CSV file',
                      onTap: () async {
                        AppFeedback.showSnackbar(context, message: 'Exporting journal entries...');
                        final exportData = await notifier.exportJournals(format: 'csv');
                        if (context.mounted) {
                          final csv = exportData['csv']?.toString() ?? '';
                          if (csv.isNotEmpty) {
                            Share.share(csv);
                            AppFeedback.showSnackbar(context, message: 'Journal Book exported successfully!');
                          }
                        }
                      },
                      isDark: isDark,
                    ),
                  ),

                  // 4. Recurring Journals
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.sync,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Recurring Journals',
                      subtitle: 'Filter recurring entries',
                      onTap: () => notifier.setSelectedTab('Recurring Journals'),
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
