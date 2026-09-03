import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/purchase_return_model.dart';
import '../providers/purchase_return_provider.dart';
import 'purchase_return_detail_dialog.dart';

class PurchaseReturnTable extends ConsumerWidget {
  const PurchaseReturnTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(purchaseReturnMetricsProvider);
    final filter = ref.watch(purchaseReturnFilterProvider);
    final notifier = ref.read(purchaseReturnFilterProvider.notifier);
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
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 130, child: Text('Debit Note #', style: _headerStyle)),
                        SizedBox(width: 100, child: Text('Return Date', style: _headerStyle)),
                        SizedBox(width: 180, child: Text('Supplier Name', style: _headerStyle)),
                        SizedBox(width: 130, child: Text('Original Bill #', style: _headerStyle)),
                        Expanded(child: Text('Return Reason', style: _headerStyle)),
                        SizedBox(width: 110, child: Text('Total (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                        SizedBox(width: 40, child: Text('Actions', textAlign: TextAlign.center, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Data Rows
                  if (metrics.filteredItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Text(
                        'No purchase returns found matching the search criteria.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.filteredItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = metrics.filteredItems[index];
                        return _buildTableRow(context, item, ref, isDark);
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
                                  if (val != null) notifier.setPage(1);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Item count info
                      Text(
                        'Showing 1 to ${metrics.filteredItems.length} of ${metrics.totalReturnsCount} returns',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pagination navigation
                      Row(
                        children: [
                          _buildPageNavBtn(icon: Icons.chevron_left, onTap: null, isDark: isDark),
                          const SizedBox(width: 4),
                          _buildPageNumberBtn(page: '1', isActive: true, onTap: () {}, isDark: isDark),
                          const SizedBox(width: 4),
                          _buildPageNavBtn(icon: Icons.chevron_right, onTap: null, isDark: isDark),
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

  Widget _buildTableRow(BuildContext context, PurchaseReturn item, WidgetRef ref, bool isDark) {
    return InkWell(
      onTap: () => PurchaseReturnDetailDialog.show(context, item),
      hoverColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Debit Note #
            SizedBox(
              width: 130,
              child: Row(
                children: [
                  Text(
                    item.debitNoteNumber,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Green bold
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.debitNoteNumber));
                      AppFeedback.showSnackbar(context, message: '${item.debitNoteNumber} copied!');
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

            // Return Date
            SizedBox(
              width: 100,
              child: Text(
                '${item.returnDate.day.toString().padLeft(2, '0')} ${_monthName(item.returnDate.month)} ${item.returnDate.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),

            // Supplier Name
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.supplierName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.supplierGstin.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      'GSTIN: ${item.supplierGstin}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Original Purchase Bill #
            SizedBox(
              width: 130,
              child: Text(
                item.originalPurchaseBillNumber,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),

            // Return Reason
            Expanded(
              child: Text(
                item.returnReason,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Total (₹)
            SizedBox(
              width: 110,
              child: Text(
                '₹${_formatCurrency(item.totalAmount)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),

            // Status Badge
            SizedBox(
              width: 95,
              child: Center(
                child: _buildStatusBadge(item.status, isDark),
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
                    if (val == 'view') {
                      PurchaseReturnDetailDialog.show(context, item);
                    } else if (val == 'confirm') {
                      ref.read(purchaseReturnsProvider.notifier).updateStatus(item.id, PurchaseReturnStatus.confirmed);
                      AppFeedback.showSnackbar(context, message: 'Debit Note ${item.debitNoteNumber} Confirmed!');
                    } else if (val == 'adjust') {
                      ref.read(purchaseReturnsProvider.notifier).updateStatus(item.id, PurchaseReturnStatus.adjusted);
                      AppFeedback.showSnackbar(context, message: 'Debit Note adjusted against supplier payable!');
                    } else if (val == 'cancel') {
                      ref.read(purchaseReturnsProvider.notifier).updateStatus(item.id, PurchaseReturnStatus.cancelled);
                      AppFeedback.showSnackbar(context, message: 'Debit Note Cancelled!');
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 15),
                          SizedBox(width: 8),
                          Text('View Debit Note', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    if (item.status == PurchaseReturnStatus.draft)
                      const PopupMenuItem(
                        value: 'confirm',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('Confirm Note', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    if (item.status == PurchaseReturnStatus.confirmed)
                      const PopupMenuItem(
                        value: 'adjust',
                        child: Row(
                          children: [
                            Icon(Icons.sync_alt, size: 15, color: Color(0xFF15803D)),
                            SizedBox(width: 8),
                            Text('Adjust in Payable', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    if (item.status != PurchaseReturnStatus.cancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('Cancel Debit Note', style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626))),
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

  Widget _buildStatusBadge(PurchaseReturnStatus status, bool isDark) {
    Color bg = const Color(0xFFDCFCE7);
    Color text = const Color(0xFF15803D);
    String label = 'Adjusted';

    switch (status) {
      case PurchaseReturnStatus.adjusted:
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        text = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
        label = 'Adjusted';
        break;
      case PurchaseReturnStatus.confirmed:
        bg = isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE);
        text = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
        label = 'Confirmed';
        break;
      case PurchaseReturnStatus.refunded:
        bg = isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF);
        text = isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA);
        label = 'Refunded';
        break;
      case PurchaseReturnStatus.draft:
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        text = isDark ? Colors.white70 : const Color(0xFF475569);
        label = 'Draft';
        break;
      case PurchaseReturnStatus.cancelled:
        bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        label = 'Cancelled';
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

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
