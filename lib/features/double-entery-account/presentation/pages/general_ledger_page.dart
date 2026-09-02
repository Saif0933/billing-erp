import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Page Title Header matching Screenshot
              _buildPageHeader(context, summary, isDark),
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
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
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
          onPressed: () => _exportLedger(context, summary),
        ),
      ],
    );
  }

  void _exportLedger(BuildContext context, GeneralLedgerSummaryData summary) {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('GENERAL LEDGER STATEMENT');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln('========================================');
    buffer.writeln('Total Debit:    ₹${summary.totalDebit.toStringAsFixed(2)}');
    buffer.writeln('Total Credit:   ₹${summary.totalCredit.toStringAsFixed(2)}');
    buffer.writeln('Closing Balance: ₹${summary.closingBalance.toStringAsFixed(2)}');
    buffer.writeln('Total Entries:  ${summary.totalEntries}');
    buffer.writeln('Status:         ${summary.isBalanced ? "Balanced (Dr = Cr)" : "Unbalanced"}');
    buffer.writeln('----------------------------------------');
    for (final item in summary.pagedItems) {
      buffer.writeln(
        '${item.date} ${item.time} | ${item.voucherNo} | ${item.account} | Dr: ${item.debit} | Cr: ${item.credit} | Bal: ${item.balance} ${item.isDebitBalance ? "Dr" : "Cr"}',
      );
    }
    buffer.writeln('========================================');

    Share.share(buffer.toString());
  }
}
