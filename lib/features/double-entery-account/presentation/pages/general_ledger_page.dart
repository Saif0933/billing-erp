import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_downloader_helper.dart';
import '../providers/general_ledger_provider.dart';
import '../widgets/ledger_filter_section.dart';
import '../widgets/ledger_insights_card.dart';
import '../widgets/ledger_summary_section.dart';
import '../widgets/ledger_table_section.dart';

class GeneralLedgerPage extends ConsumerWidget {
  const GeneralLedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(generalLedgerDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF15803D),
          onRefresh: () => ref.read(generalLedgerNotifierProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Page Title Header matching Screenshot
                _buildPageHeader(context, ref, summary, isDark),
                const SizedBox(height: 16),

                // Summary & 4 KPI Cards Section
                const LedgerSummarySection(),
                const SizedBox(height: 16),

                // Search & 4 Filter Dropdowns Section
                const LedgerFilterSection(),
                const SizedBox(height: 16),

                // Ledger Entries Data Table & Pagination Section
                const LedgerTableSection(),
                const SizedBox(height: 16),

                // Bottom Smart Insights Card
                const LedgerInsightsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
    WidgetRef ref,
    GeneralLedgerSummaryData summary,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Green Book Icon + Title + Subtitle
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 24,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Ledger',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View and analyze all ledger transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Right: [ ⤓ Export ] Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              width: 1,
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          icon: Icon(
            Icons.file_download_outlined,
            size: 16,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
          ),
          label: Text(
            'Export',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          onPressed: () => _exportLedger(context, ref, summary),
        ),
      ],
    );
  }

  Future<void> _exportLedger(
    BuildContext context,
    WidgetRef ref,
    GeneralLedgerSummaryData summary,
  ) async {
    try {
      String? csvContent;
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'general_ledger_$dateStamp.csv';

      final exportResult =
          await ref.read(generalLedgerNotifierProvider.notifier).exportLedger(format: 'csv');
      if (exportResult != null && exportResult['csv'] != null) {
        csvContent = exportResult['csv'].toString();
        if (exportResult['filename'] != null) {
          fileName = exportResult['filename'].toString();
        }
      }

      if (csvContent == null || csvContent.trim().isEmpty) {
        // Build clean CSV table from ledger transactions
        final buffer = StringBuffer();
        buffer.writeln('Date,Time,Voucher No,Voucher Type,Account,Narration,Debit (₹),Credit (₹),Balance (₹),Dr/Cr');
        for (final item in summary.pagedItems) {
          final cleanNarration = '"${item.narration.replaceAll('"', '""')}"';
          final cleanAccount = '"${item.account.replaceAll('"', '""')}"';
          buffer.writeln(
            '=" ${item.date}"," ${item.time}","${item.voucherNo}","${item.voucherType}",$cleanAccount,$cleanNarration,${item.debit > 0 ? item.debit.toStringAsFixed(2) : '0.00'},${item.credit > 0 ? item.credit.toStringAsFixed(2) : '0.00'},${item.balance.toStringAsFixed(2)},${item.isDebitBalance ? 'Dr' : 'Cr'}',
          );
        }
        csvContent = buffer.toString();
      }

      await downloadFileToDevice(
        content: csvContent,
        fileName: fileName,
        mimeType: 'text/csv;charset=utf-8',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ledger exported successfully ($fileName)',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
