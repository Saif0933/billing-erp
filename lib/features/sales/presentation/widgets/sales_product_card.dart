import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/sales_ui_models.dart';

class SalesProductCard extends StatefulWidget {
  final SalesProductItem product;
  final VoidCallback onAdd;

  const SalesProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  State<SalesProductCard> createState() => _SalesProductCardState();
}

class _SalesProductCardState extends State<SalesProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.product;

    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = _isHovered
        ? (isDark ? AppColors.accent : const Color(0xFF10B981))
        : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB));
    final titleColor = isDark ? AppColors.textDarkPrimary : const Color(0xFF111827);
    final unitColor = isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280);
    final priceColor = isDark ? AppColors.textDarkPrimary : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? (isDark
                      ? AppColors.accent.withValues(alpha: 0.22)
                      : const Color(0x1A10B981))
                  : (isDark ? Colors.transparent : const Color(0x06000000)),
              blurRadius: _isHovered ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stock Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: p.isLowStock
                        ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.6) : const Color(0xFFFEF3C7))
                        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.isLowStock ? 'Low Stock' : 'In Stock',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: p.isLowStock
                          ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706))
                          : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D)),
                    ),
                  ),
                ),
              ],
            ),

            // Centered Product Image
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 75),
                  child: p.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildFallbackIcon(p, isDark);
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(p, isDark),
                          ),
                        )
                      : _buildFallbackIcon(p, isDark),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Product Name
            Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

            // Unit/Variant Size
            Text(
              p.weight,
              style: TextStyle(
                fontSize: 11.5,
                color: unitColor,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 5),

            // Price & Add Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '₹ ${p.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: priceColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onAdd,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accent : const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.accent : const Color(0xFF059669))
                              .withValues(alpha: isDark ? 0.35 : 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(SalesProductItem p, bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: p.themeColor.withValues(alpha: isDark ? 0.18 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        p.placeholderIcon,
        color: p.themeColor,
        size: 32,
      ),
    );
  }
}
