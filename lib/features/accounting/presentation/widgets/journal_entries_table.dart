import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/general_journal_provider.dart';

class JournalEntriesTable extends ConsumerWidget {
  const JournalEntriesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generalJournalNotifierProvider);
    final summary = state.data;
    final notifier = ref.read(generalJournalNotifierProvider.notifier);
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
          // Horizontally Scrollable Table Content that expands to fill full card on desktop
          LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 900.0;
              final tableWidth = constraints.maxWidth > minTableWidth
                  ? constraints.maxWidth
                  : minTableWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Row(
                                children: const [
                                  Text('Date', style: _headerStyle),
                                  SizedBox(width: 4),
                                  Icon(Icons.swap_vert, size: 14, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 140, child: Text('Journal No.', style: _headerStyle)),
                            const SizedBox(width: 90, child: Text('Reference', style: _headerStyle)),
                            const Expanded(child: Text('Narration', style: _headerStyle)),
                            const SizedBox(width: 105, child: Text('Debit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            const SizedBox(width: 105, child: Text('Credit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            const SizedBox(width: 90, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                            const SizedBox(width: 50, child: Text('Actions', textAlign: TextAlign.center, style: _headerStyle)),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),

                      // Loading State
                      if (state.isLoading && summary.pagedItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF15803D)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Loading journal entries...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      // Error State
                      else if (state.error != null && summary.pagedItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                'Failed to load journal entries',
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
                                onPressed: () => notifier.fetchJournalEntries(isRefresh: true),
                              ),
                            ],
                          ),
                        )
                      // Empty State
                      else if (summary.pagedItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 44,
                                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No journal entries match the filter criteria.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try clearing search filters or changing the date range',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                                label: const Text('Reset Filters'),
                                onPressed: () => notifier.reset(),
                              ),
                            ],
                          ),
                        )
                      // Table Data Rows
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.pagedItems.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final item = summary.pagedItems[index];
                            return _buildTableRow(context, ref, item, isDark);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),

          // Pagination Footer Row
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth > 32 ? constraints.maxWidth - 32 : 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rows per page dropdown
                      Row(
                        children: [
                          Text(
                            'Rows per page:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: state.rowsPerPage,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 10, child: Text('10')),
                                  DropdownMenuItem(value: 20, child: Text('20')),
                                  DropdownMenuItem(value: 50, child: Text('50')),
                                ],
                                onChanged: (val) {
                                  if (val != null) notifier.setRowsPerPage(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Page Indicator
                      Text(
                        'Showing ${summary.pagedItems.isNotEmpty ? ((summary.currentPage - 1) * state.rowsPerPage + 1) : 0} to ${((summary.currentPage - 1) * state.rowsPerPage + summary.pagedItems.length)} of ${summary.totalCount} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pagination Navigation buttons
                      Row(
                        children: [
                          _buildPageNavBtn(
                            icon: Icons.first_page,
                            onTap: summary.currentPage > 1 ? () => notifier.setPage(1) : null,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNavBtn(
                            icon: Icons.chevron_left,
                            onTap: summary.currentPage > 1
                                ? () => notifier.setPage(summary.currentPage - 1)
                                : null,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          ..._buildDynamicPageButtons(summary.currentPage, summary.totalPages, notifier, isDark),
                          const SizedBox(width: 4),
                          _buildPageNavBtn(
                            icon: Icons.chevron_right,
                            onTap: summary.currentPage < summary.totalPages
                                ? () => notifier.setPage(summary.currentPage + 1)
                                : null,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNavBtn(
                            icon: Icons.last_page,
                            onTap: summary.currentPage < summary.totalPages
                                ? () => notifier.setPage(summary.totalPages)
                                : null,
                            isDark: isDark,
                          ),
                        ],
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

  static const _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  List<Widget> _buildDynamicPageButtons(
    int currentPage,
    int totalPages,
    GeneralJournalNotifier notifier,
    bool isDark,
  ) {
    final widgets = <Widget>[];
    final maxPagesToShow = 5;

    int start = (currentPage - (maxPagesToShow ~/ 2)).clamp(1, totalPages);
    int end = (start + maxPagesToShow - 1).clamp(1, totalPages);
    if (end - start < maxPagesToShow - 1) {
      start = (end - maxPagesToShow + 1).clamp(1, totalPages);
    }

    if (start > 1) {
      widgets.add(_buildPageNumberBtn(page: '1', isActive: currentPage == 1, onTap: () => notifier.setPage(1), isDark: isDark));
      if (start > 2) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('...', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500)),
        ));
      }
    }

    for (int p = start; p <= end; p++) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _buildPageNumberBtn(page: '$p', isActive: currentPage == p, onTap: () => notifier.setPage(p), isDark: isDark),
      ));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('...', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500)),
        ));
      }
      widgets.add(_buildPageNumberBtn(page: '$totalPages', isActive: currentPage == totalPages, onTap: () => notifier.setPage(totalPages), isDark: isDark));
    }

    return widgets;
  }

  Widget _buildTableRow(BuildContext context, WidgetRef ref, JournalEntryItemDto item, bool isDark) {
    return InkWell(
      onTap: () => _showJournalDetailDialog(context, item, isDark),
      hoverColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date + Time
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Journal No + Type
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.journalNo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.journalTypeLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Reference
            SizedBox(
              width: 90,
              child: Text(
                item.reference,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),

            // Narration
            Expanded(
              child: Text(
                item.narration,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Debit (₹)
            SizedBox(
              width: 105,
              child: Text(
                _formatCurrency(item.debit),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),

            // Credit (₹)
            SizedBox(
              width: 105,
              child: Text(
                _formatCurrency(item.credit),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),

            // Status Badge (Posted / Draft / Voided)
            SizedBox(
              width: 90,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.status == JournalEntryStatus.posted
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                        : item.status == JournalEntryStatus.draft
                            ? (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
                            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status == JournalEntryStatus.posted
                        ? 'Posted'
                        : item.status == JournalEntryStatus.draft
                            ? 'Draft'
                            : 'Voided',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.status == JournalEntryStatus.posted
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                          : item.status == JournalEntryStatus.draft
                              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ),
            ),

            // Actions (⋮)
            SizedBox(
              width: 50,
              child: Center(
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val == 'copy') {
                      Clipboard.setData(ClipboardData(text: item.journalNo));
                      AppFeedback.showSnackbar(context, message: 'Journal No. copied!');
                    } else if (val == 'share') {
                      // ignore: deprecated_member_use
                      Share.share(
                        'Journal Entry: ${item.journalNo}\nDate: ${item.date}\nNarration: ${item.narration}\nDebit: ₹${item.debit}\nCredit: ₹${item.credit}',
                      );
                    } else if (val == 'view') {
                      _showJournalDetailDialog(context, item, isDark);
                    } else if (val == 'void') {
                      _confirmVoid(context, ref, item);
                    } else if (val == 'delete') {
                      _confirmDelete(context, ref, item);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 15),
                          SizedBox(width: 8),
                          Text('View Details', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 15),
                          SizedBox(width: 8),
                          Text('Copy Journal No', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 15),
                          SizedBox(width: 8),
                          Text('Share', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    if (item.status != JournalEntryStatus.voided)
                      const PopupMenuItem(
                        value: 'void',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 15, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Void Entry', style: TextStyle(fontSize: 12.5, color: Colors.orange)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete Entry', style: TextStyle(fontSize: 12.5, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref, JournalEntryItemDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Journal Entry'),
        content: Text('Are you sure you want to void journal "${item.journalNo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Void Entry'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref.read(generalJournalNotifierProvider.notifier).voidJournalEntry(item.id);
      if (context.mounted) {
        if (ok) {
          AppFeedback.showSnackbar(context, message: 'Journal entry voided successfully.');
        } else {
          final err = ref.read(generalJournalNotifierProvider).error ?? 'Failed to void journal entry';
          AppFeedback.showSnackbar(context, message: err, isError: true);
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, JournalEntryItemDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Journal Entry'),
        content: Text('Are you sure you want to delete journal "${item.journalNo}"? This action cannot be undone.'),
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
      final ok = await ref.read(generalJournalNotifierProvider.notifier).deleteJournalEntry(item.id);
      if (context.mounted) {
        if (ok) {
          AppFeedback.showSnackbar(context, message: 'Journal entry deleted successfully.');
        } else {
          final err = ref.read(generalJournalNotifierProvider).error ?? 'Failed to delete journal entry';
          AppFeedback.showSnackbar(context, message: err, isError: true);
        }
      }
    }
  }

  void _showJournalDetailDialog(
    BuildContext context,
    JournalEntryItemDto item,
    bool isDark,
  ) {
    final screenSize = MediaQuery.sizeOf(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: screenSize.height * 0.9,
          ),
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 460;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15803D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: Color(0xFF15803D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.journalNo,
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.journalTypeLabel} • Ref: ${item.reference}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Metadata Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Narration',
                            item.narration,
                            isDark,
                            isMobile,
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow(
                            'Date & Time',
                            '${item.date} • ${item.time}',
                            isDark,
                            isMobile,
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow(
                            'Status',
                            item.status == JournalEntryStatus.posted
                                ? 'Posted'
                                : item.status == JournalEntryStatus.draft
                                    ? 'Draft'
                                    : 'Voided',
                            isDark,
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Double-Entry Legs breakdown if available
                    if (item.lines.isNotEmpty) ...[
                      const Text(
                        'Double-Entry Distribution',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: item.lines.map((l) {
                            final isDebit = l.debitAmount > 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.accountName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDebit
                                        ? 'Dr ₹${_formatCurrency(l.debitAmount)}'
                                        : 'Cr ₹${_formatCurrency(l.creditAmount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDebit
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Total Debit & Credit Summary Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 6,
                        spacing: 12,
                        children: [
                          Text(
                            'Total Debit: ₹${_formatCurrency(item.debit)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            'Total Credit: ₹${_formatCurrency(item.credit)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons (Responsive Wrap)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy No.'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.journalNo));
                            AppFeedback.showSnackbar(ctx, message: 'Journal No. copied!');
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share'),
                          onPressed: () {
                            // ignore: deprecated_member_use
                            Share.share(
                              'Journal Entry: ${item.journalNo}\nDate: ${item.date} ${item.time}\nNarration: ${item.narration}\nDebit: ₹${item.debit}\nCredit: ₹${item.credit}',
                            );
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 95 : 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11.5 : 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 11.5 : 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? (isDark ? Colors.white : const Color(0xFF334155))
              : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _buildPageNumberBtn({
    required String page,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFDCFCE7)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: const Color(0xFF86EFAC), width: 1) : null,
        ),
        child: Text(
          page,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF15803D) : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
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
