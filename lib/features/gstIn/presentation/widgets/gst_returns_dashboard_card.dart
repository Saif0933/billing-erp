import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/gst_models.dart';
import '../providers/gst_provider.dart';

class GstReturnsDashboardCard extends ConsumerWidget {
  const GstReturnsDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(gstReturnsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'Upcoming & Recent Returns',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Table Canvas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 620,
              child: Column(
                children: [
                  // Table Column Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    child: Row(
                      children: const [
                        SizedBox(width: 85, child: Text('Return Type', style: _headerStyle)),
                        SizedBox(width: 85, child: Text('Tax Period', style: _headerStyle)),
                        SizedBox(width: 95, child: Text('Due Date', style: _headerStyle)),
                        SizedBox(width: 90, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle)),
                        SizedBox(width: 105, child: Text('Liability (₹)', textAlign: TextAlign.right, style: _headerStyle)),
                        SizedBox(width: 120, child: Text('Actions', textAlign: TextAlign.right, style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // 5 Exact Rows
                  ...returns.map((item) => _buildTableRow(context, item, isDark)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Bottom Link: View All Returns ->
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () {
                ref.read(gstActiveTabProvider.notifier).setTab('Returns');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'View All Returns',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFF15803D)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  Widget _buildTableRow(BuildContext context, GstReturnRecord item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Return Type
          SizedBox(
            width: 85,
            child: Text(
              item.returnType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),

          // Tax Period
          SizedBox(
            width: 85,
            child: Text(
              item.taxPeriod,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),

          // Due Date
          SizedBox(
            width: 95,
            child: Text(
              item.dueDate,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),

          // Status Badge (Not Filed light red, Filed light green)
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: item.status == GstReturnStatus.notFiled
                      ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2))
                      : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status == GstReturnStatus.notFiled ? 'Not Filed' : 'Filed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.status == GstReturnStatus.notFiled
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ),

          // Liability (₹)
          SizedBox(
            width: 105,
            child: Text(
              item.liabilityAmount != null ? _formatCurrency(item.liabilityAmount!) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: item.liabilityAmount != null
                    ? (item.status == GstReturnStatus.notFiled ? const Color(0xFFDC2626) : (isDark ? Colors.white : const Color(0xFF0F172A)))
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ),
          ),

          // Action Button + ⋮ Menu
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    AppFeedback.showSnackbar(
                      context,
                      message: item.status == GstReturnStatus.notFiled
                          ? 'Opening ${item.returnType} preparation wizard...'
                          : 'Viewing filed ${item.returnType} summary...',
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status == GstReturnStatus.notFiled
                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                          : (isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.3) : const Color(0xFFF0F9FF)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.status == GstReturnStatus.notFiled
                            ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1))
                            : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Text(
                      item.status == GstReturnStatus.notFiled ? 'Prepare' : 'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.status == GstReturnStatus.notFiled
                            ? (isDark ? Colors.white : const Color(0xFF334155))
                            : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {},
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'json', child: Text('Download JSON', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(value: 'excel', child: Text('Export to Excel', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    if (whole.length <= 3) {
      return '$whole.$dec';
    }

    final lastThree = whole.substring(whole.length - 3);
    final otherNumbers = whole.substring(0, whole.length - 3);

    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedOther,$lastThree.$dec';
  }
}
