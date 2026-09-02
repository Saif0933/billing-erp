import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_journal_provider.dart';

class JournalSearchFilterBar extends ConsumerStatefulWidget {
  const JournalSearchFilterBar({super.key});

  @override
  ConsumerState<JournalSearchFilterBar> createState() => _JournalSearchFilterBarState();
}

class _JournalSearchFilterBarState extends ConsumerState<JournalSearchFilterBar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(journalFilterProvider.notifier).setSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(journalFilterProvider);
    final notifier = ref.read(journalFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final typeOptions = ['All Types', 'Standard', 'Adjustment', 'Recurring', 'Template'];
    final statusOptions = ['All Status', 'Posted', 'Draft', 'Voided'];

    return Column(
      children: [
        // Row 1: Search bar + Filters button + More button
        Row(
          children: [
            // Search Input
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                    hintText: 'Search by journal no., narration, reference...',
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
            const SizedBox(width: 8),

            // [ ≡ Filters ] Button
            InkWell(
              onTap: () => _showFilterBottomSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
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
            const SizedBox(width: 8),

            // [ ⋮ ] More Options Menu Button
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'reset') {
                    _searchController.clear();
                    notifier.reset();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Export All Journals', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 8),
                        Text('Reset Filters', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Date Range pill + Type pill + Status pill + Reset button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Date Range Pill
              _buildDateRangePill(context, filter.dateRangeLabel, isDark),
              const SizedBox(width: 8),

              // Type Pill
              _buildDropdownPill(
                label: filter.selectedType,
                items: typeOptions,
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) notifier.setSelectedType(val);
                },
              ),
              const SizedBox(width: 8),

              // Status Pill
              _buildDropdownPill(
                label: filter.selectedStatus,
                items: statusOptions,
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) notifier.setSelectedStatus(val);
                },
              ),
              const SizedBox(width: 8),

              // Reset Button
              InkWell(
                onTap: () {
                  _searchController.clear();
                  notifier.reset();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePill(BuildContext context, String label, bool isDark) {
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (range != null) {
          final fmt =
              '${range.start.day.toString().padLeft(2, '0')} ${_monthName(range.start.month)} – ${range.end.day.toString().padLeft(2, '0')} ${_monthName(range.end.month)} ${range.end.year}';
          ref.read(journalFilterProvider.notifier).setDateRange(fmt, range);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill({
    required String label,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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

  void _showFilterBottomSheet(BuildContext context) {
    final filter = ref.read(journalFilterProvider);
    final notifier = ref.read(journalFilterProvider.notifier);
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
                    'Filter Journals',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.reset();
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

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
