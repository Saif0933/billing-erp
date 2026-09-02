import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_ledger_provider.dart';
import 'ledger_voucher_detail_dialog.dart';

class LedgerTableSection extends ConsumerWidget {
  const LedgerTableSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(generalLedgerDataProvider);
    final filter = ref.watch(generalLedgerFilterProvider);
    final notifier = ref.read(generalLedgerFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Ledger Entries [ 128 Entries ] and ⇅ Sort by: Date (Newest) ▾
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ledger Entries',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${summary.totalEntries} Entries',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildSortDropdown(context, filter, notifier, isDark),
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ledger Entries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${summary.totalEntries} Entries',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildSortDropdown(context, filter, notifier, isDark),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Table Container
        Container(
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
                  width: 780, // Full width for clean tabular rendering
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 100, child: Text('Date', style: _headerStyle)),
                            SizedBox(width: 130, child: Text('Voucher No.', style: _headerStyle)),
                            SizedBox(width: 130, child: Text('Account', style: _headerStyle)),
                            Expanded(child: Text('Narration', style: _headerStyle)),
                            SizedBox(width: 90, child: Text('Debit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            SizedBox(width: 90, child: Text('Credit (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            SizedBox(width: 100, child: Text('Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
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
                            'No transactions match your search/filter.',
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

              // Pagination Footer Row (Scrollable horizontally on narrow devices to prevent overflow)
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
                                      DropdownMenuItem(value: 5, child: Text('5')),
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

                          // Page Indicator: Page 1 of 13
                          Text(
                            'Page ${summary.currentPage} of ${summary.totalPages}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Pagination buttons: < [ 1 ] 2 3 >
                          Row(
                            children: [
                              _buildPageNavBtn(
                                icon: Icons.chevron_left,
                                onTap: summary.currentPage > 1
                                    ? () => notifier.setPage(summary.currentPage - 1)
                                    : null,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildPageNumberBtn(
                                page: 1,
                                isActive: summary.currentPage == 1,
                                onTap: () => notifier.setPage(1),
                                isDark: isDark,
                              ),
                              if (summary.totalPages >= 2) ...[
                                const SizedBox(width: 4),
                                _buildPageNumberBtn(
                                  page: 2,
                                  isActive: summary.currentPage == 2,
                                  onTap: () => notifier.setPage(2),
                                  isDark: isDark,
                                ),
                              ],
                              if (summary.totalPages >= 3) ...[
                                const SizedBox(width: 4),
                                _buildPageNumberBtn(
                                  page: 3,
                                  isActive: summary.currentPage == 3,
                                  onTap: () => notifier.setPage(3),
                                  isDark: isDark,
                                ),
                              ],
                              const SizedBox(width: 4),
                              _buildPageNavBtn(
                                icon: Icons.chevron_right,
                                onTap: summary.currentPage < summary.totalPages
                                    ? () => notifier.setPage(summary.currentPage + 1)
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
        ),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  Widget _buildTableRow(BuildContext context, LedgerItem item, bool isDark) {
    return InkWell(
      onTap: () {
        LedgerVoucherDetailDialog.show(context, item);
      },
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

            // Voucher No + Voucher Type
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.voucherNo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Emerald green like in image
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.voucherType,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Account
            SizedBox(
              width: 130,
              child: Text(
                item.account,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Narration
            Expanded(
              child: Text(
                item.narration,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Debit (₹)
            SizedBox(
              width: 90,
              child: Text(
                item.debit > 0 ? _formatCurrency(item.debit) : '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: item.debit > 0 ? FontWeight.bold : FontWeight.normal,
                  color: item.debit > 0 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
              ),
            ),

            // Credit (₹)
            SizedBox(
              width: 90,
              child: Text(
                item.credit > 0 ? _formatCurrency(item.credit) : '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: item.credit > 0 ? FontWeight.bold : FontWeight.normal,
                  color: item.credit > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                ),
              ),
            ),

            // Balance (₹) + Dr/Cr badge below
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(item.balance),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isDebitBalance ? 'Dr' : 'Cr',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: item.isDebitBalance ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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

  Widget _buildSortDropdown(
    BuildContext context,
    GeneralLedgerFilterState filter,
    GeneralLedgerNotifier notifier,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.swap_vert,
          size: 16,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
        ),
        const SizedBox(width: 2),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: filter.sortBy,
            isDense: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
            items: const [
              DropdownMenuItem(value: 'Date (Newest)', child: Text('Sort by: Date (Newest)')),
              DropdownMenuItem(value: 'Date (Oldest)', child: Text('Sort by: Date (Oldest)')),
              DropdownMenuItem(value: 'Amount (High to Low)', child: Text('Sort by: Amount (High to Low)')),
              DropdownMenuItem(value: 'Amount (Low to High)', child: Text('Sort by: Amount (Low to High)')),
            ],
            onChanged: (val) {
              if (val != null) notifier.setSortBy(val);
            },
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
    required int page,
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
              ? const Color(0xFFDCFCE7) // Active light green in image
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: const Color(0xFF86EFAC), width: 1)
              : null,
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? const Color(0xFF15803D)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
