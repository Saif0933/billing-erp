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
    final summary = ref.watch(generalJournalDataProvider);
    final filter = ref.watch(journalFilterProvider);
    final notifier = ref.read(journalFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Horizontally Scrollable Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 820, // Full width for clean tabular rendering
              child: Column(
                children: [
                  // Table Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: const [
                              Text('Date', style: _headerStyle),
                              SizedBox(width: 4),
                              Icon(Icons.swap_vert, size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 125, child: Text('Journal No.', style: _headerStyle)),
                        const SizedBox(width: 80, child: Text('Reference', style: _headerStyle)),
                        const Expanded(child: Text('Narration', style: _headerStyle)),
                        const SizedBox(width: 95, child: Text('Debit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        const SizedBox(width: 95, child: Text('Credit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        const SizedBox(width: 80, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                        const SizedBox(width: 40, child: Text('Actions', textAlign: TextAlign.center, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Data Rows
                  if (summary.pagedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Text(
                        'No journal entries match the filter criteria.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    )
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
                        return _buildTableRow(context, item, isDark);
                      },
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

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
                                value: filter.rowsPerPage,
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

                      // Page Indicator: Showing 1 to 10 of 84 entries
                      Text(
                        'Showing 1 to ${summary.pagedItems.length} of ${summary.totalCount} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pagination buttons: |<< < [ 1 ] 2 3 ... 9 > >>|
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
                          _buildPageNumberBtn(
                            page: '1',
                            isActive: summary.currentPage == 1,
                            onTap: () => notifier.setPage(1),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNumberBtn(
                            page: '2',
                            isActive: summary.currentPage == 2,
                            onTap: () => notifier.setPage(2),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNumberBtn(
                            page: '3',
                            isActive: summary.currentPage == 3,
                            onTap: () => notifier.setPage(3),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          Text('...', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500)),
                          const SizedBox(width: 4),
                          _buildPageNumberBtn(
                            page: '9',
                            isActive: summary.currentPage == 9,
                            onTap: () => notifier.setPage(9),
                            isDark: isDark,
                          ),
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

  Widget _buildTableRow(BuildContext context, JournalEntryRowItem item, bool isDark) {
    return InkWell(
      onTap: () => _showJournalDetailDialog(context, item, isDark),
      hoverColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date + Time
            SizedBox(
              width: 100,
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
              width: 125,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.journalNo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Green bold like screenshot
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
              width: 80,
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
              width: 95,
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
              width: 95,
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

            // Status Badge (Posted / Draft)
            SizedBox(
              width: 80,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.status == JournalEntryStatus.posted
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                        : (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status == JournalEntryStatus.posted ? 'Posted' : 'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.status == JournalEntryStatus.posted
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                          : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    ),
                  ),
                ),
              ),
            ),

            // Actions (⋮)
            SizedBox(
              width: 40,
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
                      Share.share(
                        'Journal Entry: ${item.journalNo}\nDate: ${item.date}\nNarration: ${item.narration}\nDebit: ₹${item.debit}\nCredit: ₹${item.credit}',
                      );
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJournalDetailDialog(BuildContext context, JournalEntryRowItem item, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.journalNo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Text('Narration: ${item.narration}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Date: ${item.date} • ${item.time}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('Type: ${item.journalTypeLabel}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Debit: ₹${_formatCurrency(item.debit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  Text('Credit: ₹${_formatCurrency(item.credit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ],
              ),
            ],
          ),
        ),
      ),
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
