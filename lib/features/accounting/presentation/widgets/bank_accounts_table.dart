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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                children: [
                  // Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 200, child: Text('Bank Account', style: _headerStyle)),
                        SizedBox(width: 140, child: Text('Account Number', style: _headerStyle)),
                        SizedBox(width: 100, child: Text('Account Type', style: _headerStyle)),
                        SizedBox(width: 110, child: Text('Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 110, child: Text('Cleared Balance (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Uncleared (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 75, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                        SizedBox(width: 38, child: Text('Actions', textAlign: TextAlign.center, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Data Rows
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

                      // Showing 1 to 5 of 5 accounts
                      Text(
                        'Showing 1 to ${summary.displayedAccounts.length} of ${summary.totalAccounts} accounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pagination buttons: < [ 1 ] >
                      Row(
                        children: [
                          _buildPageNavBtn(
                            icon: Icons.chevron_left,
                            onTap: null,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNumberBtn(
                            page: '1',
                            isActive: true,
                            onTap: () {},
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildPageNavBtn(
                            icon: Icons.chevron_right,
                            onTap: null,
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

  Widget _buildTableRow(BuildContext context, BankAccountItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Bank Logo & Name + Subtitle
          SizedBox(
            width: 200,
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
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ),

          // Cleared Balance (₹)
          SizedBox(
            width: 110,
            child: Text(
              '₹${_formatCurrency(item.clearedBalance)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
            width: 75,
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
            width: 38,
            child: Center(
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'view', child: Text('View Statement', style: TextStyle(fontSize: 12.5))),
                  PopupMenuItem(value: 'reconcile', child: Text('Reconcile Account', style: TextStyle(fontSize: 12.5))),
                  PopupMenuItem(value: 'edit', child: Text('Edit Details', style: TextStyle(fontSize: 12.5))),
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
}
