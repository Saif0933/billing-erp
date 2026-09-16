import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/chart_of_accounts_provider.dart';

class CoaTreeTable extends ConsumerWidget {
  const CoaTreeTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartOfAccountsNotifierProvider);
    final summary = state.data;
    final notifier = ref.read(chartOfAccountsNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Horizontally scrollable tree table that expands to fill card width
          LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 850.0;
              final tableWidth = constraints.maxWidth > minTableWidth
                  ? constraints.maxWidth
                  : minTableWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table Header Row: Account Name | Account Code | Account Type ▾ | Balance (₹) | Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 5,
                              child: Text(
                                'Account Name',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 100,
                              child: Text(
                                'Account Code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Account Type',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down, size: 13, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 140,
                              child: Text(
                                'Balance (₹)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40), // Space for chevron / action menu
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),

                      // Loading state
                      if (state.isLoading && summary.displayedGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Loading Chart of Accounts...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      // Error state
                      else if (state.error != null && summary.displayedGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                'Failed to load accounts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF15803D),
                                ),
                                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                                onPressed: () => notifier.fetchChartOfAccounts(isRefresh: true),
                              ),
                            ],
                          ),
                        )
                      // Empty state
                      else if (summary.displayedGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 44,
                                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No accounts found.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try changing search keyword or filter category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      // Accounts List
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.displayedGroups.length,
                          itemBuilder: (context, index) {
                            final group = summary.displayedGroups[index];
                            final isExpanded = state.expandedGroupCodes.contains(group.code);

                            return _buildGroupRow(
                              context: context,
                              ref: ref,
                              group: group,
                              isExpanded: isExpanded,
                              onToggle: () => notifier.toggleGroupExpansion(group.code),
                              isDark: isDark,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRow({
    required BuildContext context,
    required WidgetRef ref,
    required CoaAccountItem group,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final iconData = _getGroupIcon(group.code);
    final iconColor = _getGroupColor(group.type);
    final iconBg = _getGroupBgColor(group.type, isDark);

    return Column(
      children: [
        // Parent Group Row
        InkWell(
          onTap: onToggle,
          hoverColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon + Name + Description
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                group.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Code (e.g. 1000)
                SizedBox(
                  width: 100,
                  child: Text(
                    group.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),

                // Type Badge (e.g. Asset, Liability, etc.)
                SizedBox(
                  width: 110,
                  child: Center(
                    child: _buildTypeBadge(group.type, isDark),
                  ),
                ),

                // Balance
                SizedBox(
                  width: 140,
                  child: Text(
                    '₹${_formatCurrency(group.balance)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),

                // Expand/Collapse Chevron
                SizedBox(
                  width: 40,
                  child: Center(
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
        ),

        // Children Sub-Accounts (Animated Expansion)
        if (isExpanded && group.children.isNotEmpty)
          ...group.children.asMap().entries.map((entry) {
            final idx = entry.key;
            final child = entry.value;
            final isLast = idx == group.children.length - 1;

            return Column(
              children: [
                _buildChildRow(context, ref, child, isLast, isDark),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                    indent: 48,
                  ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildChildRow(
    BuildContext context,
    WidgetRef ref,
    CoaAccountItem child,
    bool isLast,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        // Navigate directly to General Ledger
        context.push('/ledger');
      },
      hoverColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Indented Tree Branch with connector & green dot
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Green bullet dot
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        if (child.description.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            child.description,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Child Code (e.g. 1001)
            SizedBox(
              width: 100,
              child: Text(
                child.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),

            // Child Type Badge
            SizedBox(
              width: 110,
              child: Center(
                child: _buildTypeBadge(child.type, isDark),
              ),
            ),

            // Child Balance
            SizedBox(
              width: 140,
              child: Text(
                '₹${_formatCurrency(child.balance)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),

            // Row Action More Button (⋮)
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val == 'view_ledger') {
                    context.push('/ledger');
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref, child);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view_ledger',
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, size: 15, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text('View Ledger', style: TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Account', style: TextStyle(fontSize: 12.5, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, CoaAccountItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${item.name}" (${item.code})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref.read(chartOfAccountsNotifierProvider.notifier).deleteAccount(item.id);
      if (context.mounted) {
        if (ok) {
          AppFeedback.showSnackbar(context, message: 'Account "${item.name}" deleted successfully.');
        } else {
          final err = ref.read(chartOfAccountsNotifierProvider).error ?? 'Failed to delete account';
          AppFeedback.showSnackbar(context, message: err, isError: true);
        }
      }
    }
  }

  Widget _buildTypeBadge(CoaAccountType type, bool isDark) {
    Color bg;
    Color text;
    String label;

    switch (type) {
      case CoaAccountType.asset:
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        text = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
        label = 'Asset';
        break;
      case CoaAccountType.liability:
        bg = isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE);
        text = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
        label = 'Liability';
        break;
      case CoaAccountType.equity:
        bg = isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF);
        text = isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA);
        label = 'Equity';
        break;
      case CoaAccountType.income:
        bg = isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5);
        text = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
        label = 'Income';
        break;
      case CoaAccountType.expense:
        bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        label = 'Expense';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  IconData _getGroupIcon(String code) {
    if (code.startsWith('1')) return Icons.account_balance_rounded;
    if (code.startsWith('2')) return Icons.groups_rounded;
    if (code.startsWith('3')) return Icons.trending_up_rounded;
    if (code.startsWith('4')) return Icons.bar_chart_rounded;
    if (code.startsWith('5')) return Icons.trending_down_rounded;
    return Icons.more_horiz_rounded;
  }

  Color _getGroupColor(CoaAccountType type) {
    switch (type) {
      case CoaAccountType.asset:
        return const Color(0xFF16A34A);
      case CoaAccountType.liability:
        return const Color(0xFF0284C7);
      case CoaAccountType.equity:
        return const Color(0xFF9333EA);
      case CoaAccountType.income:
        return const Color(0xFFEA580C);
      case CoaAccountType.expense:
        return const Color(0xFFDC2626);
    }
  }

  Color _getGroupBgColor(CoaAccountType type, bool isDark) {
    if (isDark) {
      switch (type) {
        case CoaAccountType.asset:
          return const Color(0xFF064E3B);
        case CoaAccountType.liability:
          return const Color(0xFF0C4A6E);
        case CoaAccountType.equity:
          return const Color(0xFF581C87);
        case CoaAccountType.income:
          return const Color(0xFF7C2D12);
        case CoaAccountType.expense:
          return const Color(0xFF7F1D1D);
      }
    } else {
      switch (type) {
        case CoaAccountType.asset:
          return const Color(0xFFDCFCE7);
        case CoaAccountType.liability:
          return const Color(0xFFE0F2FE);
        case CoaAccountType.equity:
          return const Color(0xFFF3E8FF);
        case CoaAccountType.income:
          return const Color(0xFFFFEDD5);
        case CoaAccountType.expense:
          return const Color(0xFFFEE2E2);
      }
    }
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
