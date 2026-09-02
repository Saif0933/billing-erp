import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_of_accounts_provider.dart';

class CoaSearchToolbar extends ConsumerStatefulWidget {
  const CoaSearchToolbar({super.key});

  @override
  ConsumerState<CoaSearchToolbar> createState() => _CoaSearchToolbarState();
}

class _CoaSearchToolbarState extends ConsumerState<CoaSearchToolbar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(coaFilterProvider.notifier).setSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(coaFilterProvider.notifier);
    final filter = ref.watch(coaFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
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
                hintText: 'Search accounts by name or code...',
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
              if (val == 'expand_all') {
                notifier.expandAll();
              } else if (val == 'collapse_all') {
                notifier.collapseAll();
              } else if (val == 'toggle_zeros') {
                notifier.setShowZeroBalances(!filter.showZeroBalances);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'expand_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_more, size: 16),
                    SizedBox(width: 8),
                    Text('Expand All Groups', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collapse_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_less, size: 16),
                    SizedBox(width: 8),
                    Text('Collapse All Groups', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_zeros',
                child: Row(
                  children: [
                    Icon(filter.showZeroBalances ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
                    const SizedBox(width: 8),
                    const Text('Show Zero Balances', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final filter = ref.read(coaFilterProvider);
    final notifier = ref.read(coaFilterProvider.notifier);
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
                    'Filter Accounts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.setSelectedCategory('All Accounts');
                      notifier.setSearchQuery('');
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
                    DropdownMenuItem(value: 'Code (Ascending)', child: Text('Code (Ascending)')),
                    DropdownMenuItem(value: 'Code (Descending)', child: Text('Code (Descending)')),
                    DropdownMenuItem(value: 'Balance (High to Low)', child: Text('Balance (High to Low)')),
                    DropdownMenuItem(value: 'Name (A to Z)', child: Text('Name (A to Z)')),
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
