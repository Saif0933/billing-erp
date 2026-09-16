import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/general_ledger_provider.dart';

class LedgerVoucherDetailDialog extends StatelessWidget {
  final LedgerItem item;

  const LedgerVoucherDetailDialog({super.key, required this.item});

  static void show(BuildContext context, LedgerItem item) {
    showDialog(
      context: context,
      builder: (ctx) => LedgerVoucherDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: screenSize.height * 0.9,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 480;

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
                          Icons.receipt_outlined,
                          color: Color(0xFF15803D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.voucherType,
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textLightPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ref: ${item.voucherNo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Metadata Grid
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          'Date & Time',
                          '${item.date} • ${item.time}',
                          isDark,
                          isMobile,
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'Account Name',
                          item.account,
                          isDark,
                          isMobile,
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'Narration / Notes',
                          item.narration,
                          isDark,
                          isMobile,
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          'Voucher Status',
                          'Posted & Verified',
                          isDark,
                          isMobile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Double Entry Transaction Legs Table
                  const Text(
                    'Double-Entry Accounting Legs',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.smBorder,
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: 8,
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Account Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Debit (Dr)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Credit (Cr)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (item.legs.isNotEmpty)
                          ...item.legs.map((leg) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          leg.accountName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (leg.narration != null &&
                                            leg.narration!.isNotEmpty)
                                          Text(
                                            leg.narration!,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      leg.debit > 0
                                          ? '₹${leg.debit.toStringAsFixed(2)}'
                                          : '-',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: leg.debit > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: leg.debit > 0
                                            ? const Color(0xFF16A34A)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      leg.credit > 0
                                          ? '₹${leg.credit.toStringAsFixed(2)}'
                                          : '-',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: leg.credit > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: leg.credit > 0
                                            ? const Color(0xFFDC2626)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.account,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.debit > 0
                                        ? '₹${item.debit.toStringAsFixed(2)}'
                                        : '-',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: item.debit > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: item.debit > 0
                                          ? const Color(0xFF16A34A)
                                          : null,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.credit > 0
                                        ? '₹${item.credit.toStringAsFixed(2)}'
                                        : '-',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: item.credit > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: item.credit > 0
                                          ? const Color(0xFFDC2626)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons (Responsive Wrap for Mobile, Tablet, Desktop)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Ref'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.voucherNo));
                          AppFeedback.showSnackbar(
                            context,
                            message: 'Reference number copied',
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        onPressed: () {
                          // ignore: deprecated_member_use
                          Share.share(
                            'Voucher: ${item.voucherType}\nRef: ${item.voucherNo}\nDate: ${item.date} ${item.time}\nAccount: ${item.account}\nDebit: ₹${item.debit.toStringAsFixed(2)}\nCredit: ₹${item.credit.toStringAsFixed(2)}',
                          );
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildMetaRow(
    String label,
    String value,
    bool isDark,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 115 : 140,
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
            ),
          ),
        ),
      ],
    );
  }
}
