import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_listing_models.dart';
import '../providers/product_listing_provider.dart';
import 'product_quick_add_modal.dart';

class RecentScansCard extends ConsumerWidget {
  const RecentScansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentScans = ref.watch(productListingProvider).recentScans;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: 🕒 Recent Scans + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ref.read(productListingProvider.notifier).setCategory('All');
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of Recent Scans
          if (recentScans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent scans yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentScans.take(4).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = recentScans[index];
                return _buildRecentScanItem(context, item, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentScanItem(
    BuildContext context,
    ProductListingItem item,
    bool isDark,
  ) {
    return Row(
      children: [
        // Product Thumbnail Box
        Container(
          width: 40,
          height: 40,
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
              size: 20,
              color: item.iconColor,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Product Name + Barcode + Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.barcode,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${_getRelativeTime(item.lastScannedAt)}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Price
        Text(
          '₹${item.sellingPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 6),

        // Green Circular/Rounded Plus Button
        InkWell(
          onTap: () => ProductQuickAddModal.show(context, item),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF15803D), // Green
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.add,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getRelativeTime(DateTime? date) {
    if (date == null) return '2 mins ago';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }
}
