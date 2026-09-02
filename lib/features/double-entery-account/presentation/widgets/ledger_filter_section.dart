import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_ledger_provider.dart';

class LedgerFilterSection extends ConsumerStatefulWidget {
  const LedgerFilterSection({super.key});

  @override
  ConsumerState<LedgerFilterSection> createState() => _LedgerFilterSectionState();
}

class _LedgerFilterSectionState extends ConsumerState<LedgerFilterSection> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(generalLedgerFilterProvider.notifier).setSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(generalLedgerFilterProvider);
    final notifier = ref.read(generalLedgerFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accounts = [
      'All Accounts',
      'Cash in Hand',
      'Bank Account',
      'Ramesh Traders',
      'Apex Raw Materials Ltd',
      'Salary Expenses',
      'Acme Enterprises',
      'Global Packaging Ltd',
      'Electricity Board',
      'Krishna Traders',
      'Logistics Express',
      'Depreciation Account',
    ];

    final vouchers = [
      'All Vouchers',
      'Journal Voucher',
      'Sales Invoice',
      'Purchase Invoice',
      'Receipt',
      'Payment',
      'Credit Note',
    ];

    final types = [
      'All Types',
      'Debit Only',
      'Credit Only',
    ];

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
          // Search Input & Filters button row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by account, narration, voucher no...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // [ ≡ Filters ] Button
              InkWell(
                onTap: () => _showFilterBottomSheet(context, ref),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Dropdown Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdownPill<String>(
                  context: context,
                  label: filter.selectedAccount,
                  items: accounts,
                  isDark: isDark,
                  onChanged: (val) {
                    if (val != null) notifier.setSelectedAccount(val);
                  },
                ),
                const SizedBox(width: 8),
                _buildDropdownPill<String>(
                  context: context,
                  label: filter.selectedVoucher,
                  items: vouchers,
                  isDark: isDark,
                  onChanged: (val) {
                    if (val != null) notifier.setSelectedVoucher(val);
                  },
                ),
                const SizedBox(width: 8),
                _buildDropdownPill<String>(
                  context: context,
                  label: filter.selectedType,
                  items: types,
                  isDark: isDark,
                  onChanged: (val) {
                    if (val != null) notifier.setSelectedType(val);
                  },
                ),
                const SizedBox(width: 8),
                _buildDateRangePill(context, ref, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownPill<T>({
    required BuildContext context,
    required String label,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(label) ? label : items.first,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangePill(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (range != null) {
          final fmt =
              '${range.start.day}/${range.start.month} – ${range.end.day}/${range.end.month}';
          ref.read(generalLedgerFilterProvider.notifier).setDateRange(fmt, range);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(generalLedgerFilterProvider);
    final notifier = ref.read(generalLedgerFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Ledger Entries',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.setSelectedAccount('All Accounts');
                      notifier.setSelectedVoucher('All Vouchers');
                      notifier.setSelectedType('All Types');
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                title: const Text('Sort By'),
                trailing: DropdownButton<String>(
                  value: filter.sortBy,
                  items: const [
                    DropdownMenuItem(value: 'Date (Newest)', child: Text('Date (Newest)')),
                    DropdownMenuItem(value: 'Date (Oldest)', child: Text('Date (Oldest)')),
                    DropdownMenuItem(value: 'Amount (High to Low)', child: Text('Amount (High to Low)')),
                    DropdownMenuItem(value: 'Amount (Low to High)', child: Text('Amount (Low to High)')),
                  ],
                  onChanged: (val) {
                    if (val != null) notifier.setSortBy(val);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
