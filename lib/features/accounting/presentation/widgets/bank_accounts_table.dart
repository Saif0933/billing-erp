import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/bank_accounts_provider.dart';

class BankAccountsTable extends ConsumerWidget {
  const BankAccountsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(bankDataProvider);
    final filter = ref.watch(bankFilterProvider);
    final notifier = ref.read(bankFilterProvider.notifier);
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
          // Horizontally Scrollable Table
          LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 920.0;
              final tableWidth = constraints.maxWidth > minTableWidth
                  ? constraints.maxWidth
                  : minTableWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: const [
                            Expanded(child: Text('Bank Account', style: _headerStyle)),
                            SizedBox(width: 140, child: Text('Account Number', style: _headerStyle)),
                            SizedBox(width: 100, child: Text('Account Type', style: _headerStyle)),
                            SizedBox(width: 110, child: Text('Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            SizedBox(width: 115, child: Text('Cleared Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            SizedBox(width: 95, child: Text('Uncleared (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                            SizedBox(width: 80, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                            SizedBox(width: 50, child: Text('Actions', textAlign: TextAlign.center, style: _headerStyle)),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),

                  // Data Rows or Loading / Error / Empty States
                  if (summary.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    )
                  else if (summary.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 36, color: Color(0xFFEF4444)),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load bank accounts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                              label: const Text('Retry', style: TextStyle(color: Colors.white)),
                              onPressed: () =>
                                  ref.read(bankAccountsNotifierProvider.notifier).fetchBankAccounts(),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (summary.displayedAccounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 40,
                              color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No bank accounts found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.displayedAccounts.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = summary.displayedAccounts[index];
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

          // Dynamic Pagination Footer Row
          LayoutBuilder(
            builder: (context, constraints) {
              final totalCount = summary.totalCount > 0 ? summary.totalCount : summary.totalAccounts;
              final start = totalCount > 0
                  ? ((summary.currentPage - 1) * filter.rowsPerPage) + 1
                  : 0;
              final end = (start + summary.displayedAccounts.length - 1).clamp(0, totalCount);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth > 32 ? constraints.maxWidth - 32 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rows per page
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

                      // Showing X to Y of Z accounts
                      Text(
                        totalCount > 0
                            ? 'Showing $start to $end of $totalCount accounts'
                            : 'No accounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pagination buttons: < [ 1 ] [ 2 ] ... >
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
                          ...List.generate(summary.totalPages, (index) {
                            final pageNum = index + 1;
                            final isActive = pageNum == summary.currentPage;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildPageNumberBtn(
                                page: '$pageNum',
                                isActive: isActive,
                                onTap: () => notifier.setPage(pageNum),
                                isDark: isDark,
                              ),
                            );
                          }),
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
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  Widget _buildTableRow(BuildContext context, WidgetRef ref, BankAccountItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Bank Logo & Name + Subtitle
          Expanded(
            child: Row(
              children: [
                _buildBankLogo(item.logoType),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bankName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.accountTypeLabel,
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

          // Account Number + Copy Icon
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Text(
                  item.accountNumberMasked,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.fullAccountNumber));
                    AppFeedback.showSnackbar(context, message: '${item.bankName} Account number copied!');
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Account Type Pill (Current / Savings / Overdraft)
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildTypePill(item, isDark),
            ),
          ),

          // Balance (₹)
          SizedBox(
            width: 110,
            child: Text(
              '₹${_formatCurrency(item.currentBalance)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),

          // Cleared Balance (₹)
          SizedBox(
            width: 115,
            child: Text(
              '₹${_formatCurrency(item.clearedBalance)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0284C7),
              ),
            ),
          ),

          // Uncleared (₹)
          SizedBox(
            width: 95,
            child: Text(
              '₹${_formatCurrency(item.unclearedBalance)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEA580C),
              ),
            ),
          ),

          // Status Badge (Active)
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
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
                  if (val == 'view') {
                    _showStatementDialog(context, item, isDark);
                  } else if (val == 'reconcile') {
                    _showReconcileDialog(context, ref, item, isDark);
                  } else if (val == 'toggle_status') {
                    _confirmToggleStatus(context, ref, item);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref, item);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details', style: TextStyle(fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'reconcile',
                    child: Text('Reconcile Account', style: TextStyle(fontSize: 12.5)),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Text(
                      item.status == 'Active' ? 'Mark Inactive' : 'Mark Active',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogo(String logoType) {
    Color bg = const Color(0xFF1E3A8A);
    String label = 'SBI';

    if (logoType == 'hdfc') {
      bg = const Color(0xFF004C8F);
      label = 'HDFC';
    } else if (logoType == 'icici') {
      bg = const Color(0xFFB91C1C);
      label = 'i';
    } else if (logoType == 'axis') {
      bg = const Color(0xFF831843);
      label = 'A';
    } else if (logoType == 'bob') {
      bg = const Color(0xFFEA580C);
      label = 'BOB';
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTypePill(BankAccountItem item, bool isDark) {
    if (item.category == BankAccountCategory.current && item.accountTypeLabel.contains('Overdraft')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Current',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
          ),
        ),
      );
    }

    if (item.category == BankAccountCategory.current) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Current',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Savings',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
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

  void _showStatementDialog(BuildContext context, BankAccountItem item, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _buildBankLogo(item.logoType),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.bankName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    item.accountTypeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            _buildDetailRow('Account Number', item.fullAccountNumber, isDark, copyable: true, context: context),
            _buildDetailRow('IFSC Code', item.ifsc, isDark, copyable: true, context: context),
            if (item.branch.isNotEmpty) _buildDetailRow('Branch', item.branch, isDark),
            _buildDetailRow('Current Balance', '₹${_formatCurrency(item.currentBalance)}', isDark, isHighlight: true),
            _buildDetailRow('Cleared Balance', '₹${_formatCurrency(item.clearedBalance)}', isDark),
            _buildDetailRow('Uncleared Balance', '₹${_formatCurrency(item.unclearedBalance)}', isDark),
            _buildDetailRow('Status', item.status, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool copyable = false,
    bool isHighlight = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight
                      ? const Color(0xFF15803D)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              if (copyable && context != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    AppFeedback.showSnackbar(context, message: '$label copied!');
                  },
                  child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showReconcileDialog(BuildContext context, WidgetRef ref, BankAccountItem item, bool isDark) {
    final balanceController = TextEditingController(text: item.clearedBalance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reconcile ${item.bankName}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the cleared balance from your latest bank statement to reconcile.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Statement Balance (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newBal = double.tryParse(balanceController.text.trim());
              if (newBal == null) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(bankAccountsNotifierProvider.notifier)
                    .reconcileAccount(item.id, statementBalance: newBal);
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: 'Account reconciled successfully!');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: 'Reconciliation failed: $e', isError: true);
                }
              }
            },
            child: const Text('Reconcile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context, WidgetRef ref, BankAccountItem item) {
    final newStatus = item.status == 'Active' ? 'Inactive' : 'Active';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark Account as $newStatus?'),
        content: Text('Are you sure you want to mark ${item.bankName} as $newStatus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(bankAccountsNotifierProvider.notifier).toggleStatus(item.id);
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: '${item.bankName} status changed to $newStatus');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: 'Failed to update status: $e', isError: true);
                }
              }
            },
            child: Text('Mark $newStatus', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BankAccountItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Bank Account'),
        content: Text(
          'Are you sure you want to delete "${item.bankName}" (${item.accountNumberMasked})? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final success = await ref.read(bankAccountsNotifierProvider.notifier).deleteAccount(item.id);
                if (context.mounted) {
                  if (success) {
                    AppFeedback.showSnackbar(context, message: 'Bank account deleted successfully!');
                  } else {
                    AppFeedback.showSnackbar(context, message: 'Failed to delete bank account', isError: true);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: 'Error deleting account: $e', isError: true);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
