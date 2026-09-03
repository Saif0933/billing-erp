import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';

class GstQuickActionsCard extends ConsumerWidget {
  const GstQuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      {
        'title': 'Prepare GSTR-1',
        'subtitle': 'Sales Return',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF16A34A),
        'bg': isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
      },
      {
        'title': 'Prepare GSTR-3B',
        'subtitle': 'Summary Return',
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF2563EB),
        'bg': isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
      },
      {
        'title': 'View GSTR-2B',
        'subtitle': 'ITC Statement',
        'icon': Icons.alt_route_rounded,
        'color': const Color(0xFF9333EA),
        'bg': isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
      },
      {
        'title': 'Payment History',
        'subtitle': 'View Payments',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFEA580C),
        'bg': isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
      },
      {
        'title': 'Download Returns',
        'subtitle': 'Filed Returns',
        'icon': Icons.download_rounded,
        'color': const Color(0xFF0D9488),
        'bg': isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
      },
      {
        'title': 'Update GSTIN Details',
        'subtitle': 'Edit Information',
        'icon': Icons.settings_outlined,
        'color': isDark ? Colors.white70 : const Color(0xFF475569),
        'bg': isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        // 6 Action Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 650;
            final isMedium = constraints.maxWidth < 950;
            final cardWidth = isSmall
                ? (constraints.maxWidth - 8) / 2
                : (isMedium
                    ? (constraints.maxWidth - 16) / 3
                    : (constraints.maxWidth - 40) / 6);

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((act) {
                final title = act['title'] as String;
                final subtitle = act['subtitle'] as String;
                final icon = act['icon'] as IconData;
                final color = act['color'] as Color;
                final bg = act['bg'] as Color;

                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    onTap: () {
                      AppFeedback.showSnackbar(context, message: 'Opening $title...');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 20, color: color),
                          ),
                          const SizedBox(width: 10),
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
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
