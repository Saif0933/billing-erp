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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_outlined, color: Color(0xFF15803D), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.voucherType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          ),
                        ),
                        Text(
                          'Ref: ${item.voucherNo}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Metadata Grid
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Column(
                children: [
                  _buildMetaRow('Date & Time', '${item.date} • ${item.time}', isDark),
                  const SizedBox(height: 8),
                  _buildMetaRow('Account Name', item.account, isDark),
                  const SizedBox(height: 8),
                  _buildMetaRow('Narration / Notes', item.narration, isDark),
                  const SizedBox(height: 8),
                  _buildMetaRow('Voucher Status', 'Posted & Verified', isDark),
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
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Account Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Debit (Dr)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Credit (Cr)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item.account, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.debit > 0 ? '₹${item.debit.toStringAsFixed(2)}' : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: item.debit > 0 ? FontWeight.bold : FontWeight.normal,
                              color: item.debit > 0 ? const Color(0xFF16A34A) : null,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.credit > 0 ? '₹${item.credit.toStringAsFixed(2)}' : '-',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: item.credit > 0 ? FontWeight.bold : FontWeight.normal,
                              color: item.credit > 0 ? const Color(0xFFDC2626) : null,
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

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Ref'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.voucherNo));
                    AppFeedback.showSnackbar(context, message: 'Reference number copied');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  onPressed: () {
                    Share.share(
                      'Voucher: ${item.voucherType}\nRef: ${item.voucherNo}\nDate: ${item.date} ${item.time}\nAccount: ${item.account}\nDebit: ₹${item.debit.toStringAsFixed(2)}\nCredit: ₹${item.credit.toStringAsFixed(2)}',
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
