import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_return_provider.dart';

class PurchaseReturnToolbar extends ConsumerStatefulWidget {
  const PurchaseReturnToolbar({super.key});

  @override
  ConsumerState<PurchaseReturnToolbar> createState() => _PurchaseReturnToolbarState();
}

class _PurchaseReturnToolbarState extends ConsumerState<PurchaseReturnToolbar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(purchaseReturnFilterProvider.notifier).setSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(purchaseReturnFilterProvider);
    final notifier = ref.read(purchaseReturnFilterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses = ['All', 'Draft', 'Confirmed', 'Adjusted', 'Refunded', 'Cancelled'];

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
                hintText: 'Search by Debit Note #, Supplier, Original Bill...',
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

        // Status Filter Dropdown
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filter.selectedStatus,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              items: statuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status == 'All' ? 'All Statuses' : status));
              }).toList(),
              onChanged: (val) {
                if (val != null) notifier.setSelectedStatus(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Reset Button
        InkWell(
          onTap: () {
            _searchController.clear();
            notifier.reset();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.refresh,
              size: 18,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
