import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/sales_ui_models.dart';

class SalesCategoryBar extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final List<SalesCategory>? categories;

  const SalesCategoryBar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryList = (categories != null && categories!.isNotEmpty)
        ? categories!
        : kSalesCategories;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final isSelected = selectedCategoryId == category.id;

          final selectedBg = isDark ? AppColors.accent : const Color(0xFF064E3B);
          final unselectedBg = isDark ? AppColors.surfaceDark : Colors.white;
          final selectedBorder = isDark ? AppColors.accent : const Color(0xFF064E3B);
          final unselectedBorder = isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);
          final selectedFg = isDark ? AppColors.primary : Colors.white;
          final unselectedFg = isDark ? AppColors.textDarkSecondary : const Color(0xFF374151);
          final unselectedIcon = isDark ? AppColors.textDarkMuted : const Color(0xFF4B5563);

          return InkWell(
            onTap: () => onCategorySelected(category.id),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? selectedBorder : unselectedBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isDark ? AppColors.accent : const Color(0xFF064E3B))
                              .withValues(alpha: isDark ? 0.3 : 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.id != 'all') ...[
                    Icon(
                      category.icon,
                      size: 16,
                      color: isSelected ? selectedFg : unselectedIcon,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? selectedFg : unselectedFg,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
