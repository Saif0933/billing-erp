import 'package:flutter/material.dart';

class SalesTopHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBarcodeScan;
  final VoidCallback onSelectCustomer;
  final VoidCallback onHoldBill;
  final VoidCallback onRecentBills;
  final VoidCallback? onMoreOptions;
  final VoidCallback? onNotificationTap;
  final FocusNode? searchFocusNode;
  final VoidCallback? onBackTap;

  const SalesTopHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBarcodeScan,
    required this.onSelectCustomer,
    required this.onHoldBill,
    required this.onRecentBills,
    this.onMoreOptions,
    this.onNotificationTap,
    this.searchFocusNode,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1000;
    final isMobile = screenWidth < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: isMobile
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context, isCompact),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: InkWell(
        onTap: onBackTap ??
            () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: searchFocusNode,
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                hintText: 'Search product by name, barcode or SKU...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Tooltip(
            message: 'Scan Barcode (F2)',
            child: InkWell(
              onTap: onBarcodeScan,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'F2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Center(
            child: Text(
              'TS',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Tax Bunny',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Main Branch',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: Color(0xFF6B7280),
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      children: [
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Color(0xFF4B5563),
            size: 22,
          ),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isCompact) {
    return Row(
      children: [
        _buildBackButton(context),
        const SizedBox(width: 14),
        Expanded(child: _buildSearchBar(context)),
        const SizedBox(width: 14),
        _buildTopActionButton(
          icon: Icons.person_outline,
          label: 'Customer',
          badge: 'F4',
          onTap: onSelectCustomer,
        ),
        const SizedBox(width: 8),
        _buildTopActionButton(
          icon: Icons.pause_circle_outline,
          label: 'Hold Bill',
          onTap: onHoldBill,
        ),
        const SizedBox(width: 8),
        if (!isCompact) ...[
          _buildTopActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Recent Bills',
            onTap: onRecentBills,
          ),
          const SizedBox(width: 8),
        ],
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF4B5563)),
            onPressed: onMoreOptions,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        _buildNotificationBell(),
        const SizedBox(width: 12),
        _buildUserProfile(),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBackButton(context),
            Row(
              children: [
                _buildNotificationBell(),
                const SizedBox(width: 8),
                _buildUserProfile(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSearchBar(context)),
            const SizedBox(width: 8),
            _buildTopActionButton(
              icon: Icons.person_outline,
              label: '',
              badge: 'F4',
              onTap: onSelectCustomer,
            ),
            const SizedBox(width: 6),
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF4B5563)),
                onPressed: onMoreOptions,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
