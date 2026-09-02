import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bank_accounts_provider.dart';

class BankRecentTransactionsCard extends ConsumerWidget {
  const BankRecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(bankDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Recent Transactions + [ View All -> ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transaction Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.recentTransactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 16,
              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final tx = summary.recentTransactions[index];
              return _buildTransactionRow(tx, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BankTransactionItem tx, bool isDark) {
    return Row(
      children: [
        // Bank Icon
        _buildTxBankLogo(tx.logoType),
        const SizedBox(width: 10),

        // Title + Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${tx.subtitle} • ${tx.reference}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Amount + Date + Status Pill
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tx.isCredit ? '+' : '-'} ₹${_formatCurrency(tx.amount)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: tx.isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.date,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: tx.isCleared
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                        : (isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.isCleared ? 'Cleared' : 'Uncleared',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: tx.isCleared
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                          : (isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTxBankLogo(String logoType) {
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
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
