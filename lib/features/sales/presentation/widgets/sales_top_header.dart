import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SalesTopHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBarcodeScan;
  final VoidCallback onSelectCustomer;
  final VoidCallback onHoldBill;
  final VoidCallback onRecentBills;
  final VoidCallback? onMoreOptions;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onToggleTheme;
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
    this.onToggleTheme,
    this.searchFocusNode,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1000;
    final isMobile = screenWidth < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? _buildMobileLayout(context, isDark)
          : _buildDesktopLayout(context, isCompact, isDark),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
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
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.transparent : const Color(0x06000000),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isDark ? AppColors.textDarkPrimary : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, {bool isMobile = false}) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: isDark ? AppColors.textDarkMuted : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: searchFocusNode,
              controller: searchController,
              onChanged: onSearchChanged,
              cursorColor: isDark ? AppColors.accent : const Color(0xFF059669),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textDarkPrimary : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: bgColor,
                hintText: isMobile ? 'Search or scan...' : 'Search product by name, barcode or SKU...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textDarkMuted : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Tooltip(
            message: isMobile ? 'Scan with Camera' : 'Scan Barcode (F2)',
            child: InkWell(
              onTap: onBarcodeScan,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : (isMobile ? const Color(0xFFECFDF5) : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : (isMobile ? const Color(0xFFA7F3D0) : const Color(0xFFD1D5DB)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMobile ? Icons.camera_alt_outlined : Icons.qr_code_scanner,
                      color: isDark ? AppColors.accentLight : const Color(0xFF059669),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMobile ? 'Scan' : 'F2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.accentLight : const Color(0xFF059669),
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF374151),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkPrimary : const Color(0xFF374151),
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.accent.withValues(alpha: 0.4) : const Color(0xFFA7F3D0),
            ),
          ),
          child: Center(
            child: Text(
              'TS',
              style: TextStyle(
                color: isDark ? AppColors.accentLight : const Color(0xFF065F46),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tax Bunny',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Main Branch',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
        ),
      ],
    );
  }

  Widget _buildThemeToggleButton(bool isDark) {
    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: IconButton(
        onPressed: onToggleTheme,
        icon: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: isDark ? AppColors.accent : const Color(0xFF4B5563),
          size: 21,
        ),
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildNotificationBell(bool isDark) {
    return Stack(
      children: [
        IconButton(
          onPressed: onNotificationTap,
          icon: Icon(
            Icons.notifications_none_outlined,
            color: isDark ? AppColors.textDarkSecondary : const Color(0xFF4B5563),
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

  Widget _buildDesktopLayout(BuildContext context, bool isCompact, bool isDark) {
    return Row(
      children: [
        _buildBackButton(context, isDark),
        const SizedBox(width: 14),
        Expanded(child: _buildSearchBar(context, isDark)),
        const SizedBox(width: 14),
        _buildTopActionButton(
          icon: Icons.person_outline,
          label: 'Customer',
          badge: 'F4',
          onTap: onSelectCustomer,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildTopActionButton(
          icon: Icons.pause_circle_outline,
          label: 'Hold Bill',
          onTap: onHoldBill,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        if (!isCompact) ...[
          _buildTopActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Recent Bills',
            onTap: onRecentBills,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
        ],
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF4B5563),
            ),
            onPressed: onMoreOptions,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 10),
        if (onToggleTheme != null) ...[
          _buildThemeToggleButton(isDark),
          const SizedBox(width: 6),
        ],
        _buildNotificationBell(isDark),
        const SizedBox(width: 12),
        _buildUserProfile(isDark),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBackButton(context, isDark),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onToggleTheme != null) ...[
                    _buildThemeToggleButton(isDark),
                    const SizedBox(width: 4),
                  ],
                  _buildNotificationBell(isDark),
                  const SizedBox(width: 8),
                  Flexible(child: _buildUserProfile(isDark)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSearchBar(context, isDark, isMobile: true)),
            const SizedBox(width: 8),
            _buildTopActionButton(
              icon: Icons.person_outline,
              label: '',
              badge: null,
              onTap: onSelectCustomer,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: isDark ? AppColors.textDarkSecondary : const Color(0xFF4B5563),
                ),
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
