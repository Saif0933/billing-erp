import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';

class StatementQuickActionsCard extends ConsumerWidget {
  const StatementQuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Action Grid (5 Tiles)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final tileWidth = isSmall
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 32) / 5;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 1. Custom Report
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.note_add_outlined,
                      iconColor: const Color(0xFF16A34A),
                      title: 'Custom Report',
                      subtitle: 'Create custom statement',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Custom Statement Designer opened!');
                      },
                      isDark: isDark,
                    ),
                  ),

                  // 2. Schedule Report
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.schedule_send_outlined,
                      iconColor: const Color(0xFF9333EA),
                      title: 'Schedule Report',
                      subtitle: 'Automate report delivery',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Schedule report modal opened!');
                      },
                      isDark: isDark,
                    ),
                  ),

                  // 3. Export to Excel
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.table_view_outlined,
                      iconColor: const Color(0xFF16A34A),
                      title: 'Export to Excel',
                      subtitle: 'Download in Excel',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Exporting Excel workbook...');
                      },
                      isDark: isDark,
                    ),
                  ),

                  // 4. Print Report
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.print_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Print Report',
                      subtitle: 'Print current report',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Printing current report...');
                      },
                      isDark: isDark,
                    ),
                  ),

                  // 5. Save Layout
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.space_dashboard_outlined,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Save Layout',
                      subtitle: 'Save current settings',
                      onTap: () {
                        AppFeedback.showSnackbar(context, message: 'Current report layout saved as preset!');
                      },
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
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
