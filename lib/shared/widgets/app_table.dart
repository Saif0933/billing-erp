import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/responsive/responsive.dart';
import 'app_states.dart';

class TableColumnSpec<T> {
  final String label;
  final Widget Function(T) cellBuilder;
  final bool isNumeric;
  final int flex;

  const TableColumnSpec({
    required this.label,
    required this.cellBuilder,
    this.isNumeric = false,
    this.flex = 1,
  });
}

class AppTable<T> extends StatelessWidget {
  final List<T> items;
  final List<TableColumnSpec<T>> columns;
  final bool isLoading;
  final String emptyMessage;
  final Widget Function(T)? mobileCardBuilder;
  final int currentPage;
  final int totalPages;
  final void Function(int)? onPageChanged;
  final List<T> selectedItems;
  final void Function(List<T>)? onSelectionChanged;

  const AppTable({
    super.key,
    required this.items,
    required this.columns,
    this.isLoading = false,
    this.emptyMessage = 'No records found.',
    this.mobileCardBuilder,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.selectedItems = const [],
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: AppLoader(message: 'Loading table data...'),
      );
    }

    if (items.isEmpty) {
      return AppEmptyState(
        title: 'Empty List',
        description: emptyMessage,
        icon: Icons.list_alt,
      );
    }

    final isMobile = Responsive.isMobile(context);

    if (isMobile && mobileCardBuilder != null) {
      return _buildMobileList(context);
    }

    if (isMobile) {
      final double minWidth = columns.length * 120.0;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth > MediaQuery.sizeOf(context).width
              ? minWidth
              : MediaQuery.sizeOf(context).width,
          child: _buildDesktopTable(context),
        ),
      );
    }

    return _buildDesktopTable(context);
  }

  Widget _buildMobileList(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return mobileCardBuilder!(items[index]);
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPaginationRow(context),
        ]
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasSelection = onSelectionChanged != null;
    final bool allSelected = items.isNotEmpty && selectedItems.length == items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppRadius.smBorder,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              Container(
                color: isDark ? AppColors.primaryDark : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                child: Row(
                  children: [
                    if (hasSelection) ...[
                      Checkbox(
                        value: allSelected,
                        onChanged: (val) {
                          if (val == true) {
                            onSelectionChanged!(List.from(items));
                          } else {
                            onSelectionChanged!([]);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    ...columns.map((col) {
                      return Expanded(
                        flex: col.flex,
                        child: Align(
                          alignment: col.isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            col.label,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItems.contains(item);

                  return Container(
                    color: isSelected
                        ? (isDark ? AppColors.accent.withOpacity(0.1) : AppColors.primary.withOpacity(0.05))
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    child: Row(
                      children: [
                        if (hasSelection) ...[
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              final updated = List<T>.from(selectedItems);
                              if (val == true) {
                                updated.add(item);
                              } else {
                                updated.remove(item);
                              }
                              onSelectionChanged!(updated);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        ...columns.map((col) {
                          return Expanded(
                            flex: col.flex,
                            child: Align(
                              alignment: col.isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: DefaultTextStyle(
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                ),
                                child: col.cellBuilder(item),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPaginationRow(context),
        ]
      ],
    );
  }

  Widget _buildPaginationRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $currentPage of $totalPages',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 1 && onPageChanged != null
                  ? () => onPageChanged!(currentPage - 1)
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages && onPageChanged != null
                  ? () => onPageChanged!(currentPage + 1)
                  : null,
            ),
          ],
        )
      ],
    );
  }
}
