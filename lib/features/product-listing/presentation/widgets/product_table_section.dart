import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_listing_models.dart';
import '../providers/product_listing_provider.dart';
import 'product_quick_add_modal.dart';

class ProductTableSection extends ConsumerWidget {
  const ProductTableSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productListingProvider);
    final notifier = ref.read(productListingProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = ['All', 'Groceries', 'Beverages', 'Snacks', 'Personal Care'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title + Category Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 650;

                final titleWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan a product or search to find items',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );

                final filtersWidget = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...categories.map((cat) {
                        final isSelected = state.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => notifier.setCategory(cat),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF15803D)
                                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF15803D)
                                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Categories Dropdown
                      PopupMenuButton<String>(
                        onSelected: (val) => notifier.setCategory(val),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'Dairy', child: Text('Dairy')),
                          const PopupMenuItem(value: 'Biscuits', child: Text('Biscuits')),
                          const PopupMenuItem(value: 'Home Care', child: Text('Home Care')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 12),
                      filtersWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleWidget,
                    const SizedBox(width: 12),
                    filtersWidget,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Product Table Canvas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 820,
              child: Column(
                children: [
                  // Column Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    child: Row(
                      children: const [
                        SizedBox(width: 70, child: Text('Image', style: _headerStyle)),
                        Expanded(flex: 3, child: Text('Product Name', style: _headerStyle)),
                        SizedBox(width: 120, child: Text('Category', style: _headerStyle)),
                        SizedBox(width: 90, child: Text('MRP', style: _headerStyle)),
                        SizedBox(width: 100, child: Text('Selling Price', style: _headerStyle)),
                        SizedBox(width: 80, child: Text('Stock', style: _headerStyle)),
                        SizedBox(width: 90, child: Text('Action', textAlign: TextAlign.center, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Rows
                  if (state.paginatedProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No products found matching your search/filter.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else
                    ...state.paginatedProducts.map((item) => _buildProductRow(context, item, isDark)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Footer Pagination Bar (Responsive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 460;

                final infoText = Text(
                  'Showing 1 to ${state.paginatedProducts.length} of ${state.totalProductsCount} products',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                );

                final paginationButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPageButton(
                      child: const Icon(Icons.chevron_left, size: 16),
                      onTap: state.currentPage > 1 ? () => notifier.setPage(state.currentPage - 1) : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    ...[1, 2, 3, 4, 5].map((pageNum) {
                      final isCurrent = state.currentPage == pageNum;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => notifier.setPage(pageNum),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF15803D)
                                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF15803D)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isCurrent
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    _buildPageButton(
                      child: const Icon(Icons.chevron_right, size: 16),
                      onTap: state.currentPage < 5 ? () => notifier.setPage(state.currentPage + 1) : null,
                      isDark: isDark,
                    ),
                  ],
                );

                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoText,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: paginationButtons,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoText,
                    paginationButtons,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  Widget _buildProductRow(
    BuildContext context,
    ProductListingItem item,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Image Thumbnail
          SizedBox(
            width: 70,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Icon(
                  item.placeholderIcon,
                  size: 24,
                  color: item.iconColor,
                ),
              ),
            ),
          ),

          // 2. Product Name + Barcode
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.barcode,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // 3. Category Badge
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? item.categoryBadgeBg.withValues(alpha: 0.2) : item.categoryBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.categoryBadgeText,
                  ),
                ),
              ),
            ),
          ),

          // 4. MRP
          SizedBox(
            width: 90,
            child: Text(
              '₹ ${item.mrp.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),

          // 5. Selling Price
          SizedBox(
            width: 100,
            child: Text(
              '₹ ${item.sellingPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),

          // 6. Stock
          SizedBox(
            width: 80,
            child: Text(
              '${item.stock}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),

          // 7. Action: [ + Add ] Button
          SizedBox(
            width: 90,
            child: Center(
              child: InkWell(
                onTap: () => ProductQuickAddModal.show(context, item),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D), // Green
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required Widget child,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              color: onTap != null
                  ? (isDark ? Colors.white70 : const Color(0xFF334155))
                  : Colors.grey.shade400,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
