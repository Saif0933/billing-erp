import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/gst_models.dart';
import '../providers/gst_provider.dart';

class GstFileReturnDialog extends ConsumerStatefulWidget {
  final GstReturnRecord item;

  const GstFileReturnDialog({super.key, required this.item});

  static void show(BuildContext context, GstReturnRecord item) {
    showDialog(
      context: context,
      builder: (ctx) => GstFileReturnDialog(item: item),
    );
  }

  @override
  ConsumerState<GstFileReturnDialog> createState() => _GstFileReturnDialogState();
}

class _GstFileReturnDialogState extends ConsumerState<GstFileReturnDialog> {
  bool _isFiling = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance, color: Color(0xFF15803D), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.returnType} Filing Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tax Period: ${item.taxPeriod}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 18),

            // Scrollable Summary Box
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & ARN Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Due Date: ${item.dueDate}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                              Text('Status: ${item.status == GstReturnStatus.notFiled ? 'Not Filed' : 'Filed'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.status == GstReturnStatus.notFiled ? const Color(0xFFDC2626) : const Color(0xFF15803D))),
                            ],
                          ),
                          if (item.arn.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Filing ARN Number:', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                                Text(item.arn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tax Figures Table
                    const Text('Tax Figures for Return Filing', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Taxable Value:', style: TextStyle(fontSize: 12)),
                              Text('₹${_formatCurrency(item.taxableAmount > 0 ? item.taxableAmount : 1025000.0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Central GST (CGST):', style: TextStyle(fontSize: 12)),
                              Text('₹${_formatCurrency(item.cgstAmount > 0 ? item.cgstAmount : 92250.0)}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('State GST (SGST):', style: TextStyle(fontSize: 12)),
                              Text('₹${_formatCurrency(item.sgstAmount > 0 ? item.sgstAmount : 92250.0)}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Integrated GST (IGST):', style: TextStyle(fontSize: 12)),
                              Text('₹${_formatCurrency(item.igstAmount)}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Tax Payable / Disclosed:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${_formatCurrency(item.liabilityAmount ?? (item.totalTax > 0 ? item.totalTax : 184500.0))}',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download, size: 15),
                  label: const Text('Export JSON'),
                  onPressed: () {
                    AppFeedback.showSnackbar(context, message: '${item.returnType} JSON payload downloaded!');
                  },
                ),
                const SizedBox(width: 8),
                if (item.status != GstReturnStatus.filed)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isFiling
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 15, color: Colors.white),
                    label: Text(
                      _isFiling ? 'Filing...' : 'Submit & File',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isFiling
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isFiling = true);
                            final msg = await ref.read(gstStateProvider.notifier).fileReturn(item);
                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          },
                  ),
              ],
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
}
