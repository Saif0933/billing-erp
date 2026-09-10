import 'package:flutter/material.dart';
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
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0x1A10B981)
                  : const Color(0x06000000),
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
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.isLowStock ? 'Low Stock' : 'In Stock',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: p.isLowStock
                          ? const Color(0xFFD97706)
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),

            // Centered Product Image
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 80,
                  child: p.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildFallbackIcon(p);
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(p),
                          ),
                        )
                      : _buildFallbackIcon(p),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Product Name
            Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            // Unit/Variant Size
            Text(
              p.weight,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
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
                      color: const Color(0xFF059669), // Vibrant green matching image
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26059669),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  Widget _buildFallbackIcon(SalesProductItem p) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: p.themeColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        p.placeholderIcon,
        color: p.themeColor,
        size: 38,
      ),
    );
  }
}
