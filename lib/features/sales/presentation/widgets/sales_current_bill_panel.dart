import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/sales_ui_models.dart';

class SalesCurrentBillPanel extends StatefulWidget {
  final String billNumber;
  final String customerName;
  final List<SalesCartItem> cartItems;
  final double discountPercent;
  final double discountAmount;
  final String? note;
  final ValueChanged<int> onIncrementQty;
  final ValueChanged<int> onDecrementQty;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onSelectCustomer;
  final VoidCallback onAddCustomer;
  final VoidCallback onAddNote;
  final VoidCallback onClearCart;
  final VoidCallback onSaveDraft;
  final VoidCallback onGenerateBill;
  final bool isSubmitting;
  final VoidCallback? onSettingsTap;

  const SalesCurrentBillPanel({
    super.key,
    required this.billNumber,
    required this.customerName,
    required this.cartItems,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.note,
    this.isSubmitting = false,
    required this.onIncrementQty,
    required this.onDecrementQty,
    required this.onRemoveItem,
    required this.onSelectCustomer,
    required this.onAddCustomer,
    required this.onAddNote,
    required this.onClearCart,
    required this.onSaveDraft,
    required this.onGenerateBill,
    this.onSettingsTap,
  });

  @override
  State<SalesCurrentBillPanel> createState() => _SalesCurrentBillPanelState();
}

class _SalesCurrentBillPanelState extends State<SalesCurrentBillPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get totalItemsCount =>
      widget.cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      widget.cartItems.fold(0.0, (sum, item) => sum + item.amount);

  double get effectiveDiscount => widget.discountAmount > 0
      ? widget.discountAmount
      : (subtotal * widget.discountPercent) / 100.0;

  double get taxableSubtotal =>
      (subtotal - effectiveDiscount).clamp(0.0, double.infinity);

  // Dynamic CGST and SGST calculated from items' actual GST rates
  double get cgst {
    if (subtotal <= 0) return 0.0;
    final discountRatio = taxableSubtotal / subtotal;
    final totalTax = widget.cartItems.fold(0.0, (sum, it) {
      final taxable = it.amount * discountRatio;
      return sum + (taxable * (it.gstRate / 200.0));
    });
    return ((totalTax * 100).round()) / 100.0;
  }

  double get sgst {
    if (subtotal <= 0) return 0.0;
    final discountRatio = taxableSubtotal / subtotal;
    final totalTax = widget.cartItems.fold(0.0, (sum, it) {
      final taxable = it.amount * discountRatio;
      return sum + (taxable * (it.gstRate / 200.0));
    });
    return ((totalTax * 100).round()) / 100.0;
  }

  double get grandTotal => taxableSubtotal + cgst + sgst;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Current Bill, Bill No., Settings Icon
          _buildHeader(isDark),
          const SizedBox(height: 8),

          // Customer Selector
          _buildCustomerSelector(isDark),
          const SizedBox(height: 8),

          // Cart Table Header
          _buildCartTableHeader(isDark),
          const SizedBox(height: 4),

          // Scrollable Cart Table Items
          Expanded(
            child: widget.cartItems.isEmpty
                ? _buildEmptyCartView(isDark)
                : _buildCartItemsList(isDark),
          ),

          const SizedBox(height: 4),

          // Actions Row: "+ Add Note" & "Clear Cart"
          _buildCartQuickActions(isDark),
          const SizedBox(height: 6),

          // Note indicator if note is present
          if (widget.note != null && widget.note!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: isDark ? AppColors.accentLight : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: ${widget.note}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.accentLight : const Color(0xFF15803D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Financial Breakdown
          _buildFinancialBreakdown(isDark),
          const SizedBox(height: 8),

          // Bottom Buttons: Save as Draft & Generate Bill (F8)
          _buildBottomButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Current Bill',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : const Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bill No. ${widget.billNumber}',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: widget.onSettingsTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: isDark ? AppColors.textDarkMuted : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerSelector(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onSelectCustomer,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onAddCustomer,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.add,
              color: isDark ? AppColors.textDarkPrimary : const Color(0xFF374151),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartTableHeader(bool isDark) {
    final headerColor = isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 350;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFF3F4F6),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ),
              SizedBox(
                width: isNarrow ? 64 : 76,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ),
              if (!isNarrow) ...[
                SizedBox(
                  width: 52,
                  child: Text(
                    'Rate (₹)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: isNarrow ? 54 : 60,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemsList(bool isDark) {
    final itemNameColor = isDark ? AppColors.textDarkPrimary : const Color(0xFF1F2937);
    final itemUnitColor = isDark ? AppColors.textDarkMuted : const Color(0xFF9CA3AF);
    final stepperBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6);
    final stepperIcons = isDark ? AppColors.textDarkSecondary : const Color(0xFF4B5563);
    final stepperText = isDark ? AppColors.textDarkPrimary : const Color(0xFF111827);
    final rateColor = isDark ? AppColors.textDarkSecondary : const Color(0xFF374151);
    final amountColor = isDark ? AppColors.textDarkPrimary : const Color(0xFF111827);
    final deleteColor = isDark ? AppColors.textDarkMuted : const Color(0xFF9CA3AF);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 350;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: widget.cartItems.length > 2,
          thickness: 4,
          radius: const Radius.circular(4),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 2),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : const Color(0xFFF3F4F6),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // # Index
                    SizedBox(
                      width: 18,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Product Name & Weight
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: item.product.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: itemNameColor,
                          ),
                          children: [
                            TextSpan(
                              text: ' ${item.product.weight}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: itemUnitColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quantity Stepper: [-  Qty  +]
                    Container(
                      width: isNarrow ? 64 : 76,
                      height: 24,
                      decoration: BoxDecoration(
                        color: stepperBg,
                        borderRadius: BorderRadius.circular(5),
                        border: isDark ? Border.all(color: AppColors.borderDark) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => widget.onDecrementQty(index),
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: isNarrow ? 18 : 22,
                              height: 24,
                              child: Center(
                                child: Icon(
                                  Icons.remove,
                                  size: 12,
                                  color: stepperIcons,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: stepperText,
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onIncrementQty(index),
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: isNarrow ? 18 : 22,
                              height: 24,
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  size: 12,
                                  color: stepperIcons,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Rate (omitted on narrow screens)
                    if (!isNarrow) ...[
                      SizedBox(
                        width: 52,
                        child: Text(
                          item.rate.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: rateColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Amount
                    SizedBox(
                      width: isNarrow ? 54 : 60,
                      child: Text(
                        item.amount.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ),

                    // Delete button
                    SizedBox(
                      width: 24,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 15,
                          color: deleteColor,
                        ),
                        splashRadius: 12,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        hoverColor: const Color(0xFFFEE2E2).withValues(alpha: isDark ? 0.2 : 1.0),
                        onPressed: () => widget.onRemoveItem(index),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyCartView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 40,
            color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Bill is empty',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Click on products to add to cart',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textDarkMuted : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartQuickActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: widget.onAddNote,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: 14,
                  color: isDark ? AppColors.accent : const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.accent : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: widget.cartItems.isEmpty ? null : widget.onClearCart,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: widget.cartItems.isEmpty
                      ? (isDark ? AppColors.textDarkMuted : const Color(0xFFD1D5DB))
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  'Clear Cart',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.cartItems.isEmpty
                        ? (isDark ? AppColors.textDarkMuted : const Color(0xFFD1D5DB))
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBreakdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF3F4F6),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'Total Items',
            value: '$totalItemsCount',
            isBold: false,
            isDark: isDark,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'Subtotal',
            value: '₹ ${subtotal.toStringAsFixed(2)}',
            isBold: true,
            isDark: isDark,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: '% Discount',
            value: '₹ ${effectiveDiscount.toStringAsFixed(2)}',
            icon: Icons.percent,
            iconColor: const Color(0xFF3B82F6),
            valueColor: isDark ? AppColors.accentLight : const Color(0xFF059669),
            isBold: false,
            isDark: isDark,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'CGST',
            value: '₹ ${cgst.toStringAsFixed(2)}',
            icon: Icons.receipt_outlined,
            iconColor: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
            isBold: false,
            isDark: isDark,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'SGST',
            value: '₹ ${sgst.toStringAsFixed(2)}',
            icon: Icons.receipt_outlined,
            iconColor: isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280),
            isBold: false,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          Divider(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            height: 1,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDarkPrimary : const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '₹ ${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.accent : const Color(0xFF059669),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
    bool isBold = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: (iconColor ?? (isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280)))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 11,
                    color: iconColor ?? (isDark ? AppColors.textDarkMuted : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isDark ? AppColors.textDarkSecondary : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (isDark ? AppColors.textDarkPrimary : const Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    final draftBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final draftBorder = isDark ? AppColors.borderDark : const Color(0xFFD1D5DB);
    final draftFg = isDark ? AppColors.textDarkPrimary : const Color(0xFF374151);

    final genButtonColor = widget.cartItems.isEmpty
        ? (isDark ? const Color(0xFF334155) : const Color(0xFF9CA3AF))
        : (widget.isSubmitting
            ? const Color(0xFF047857)
            : (isDark ? AppColors.accent : const Color(0xFF059669)));

    final genTextColor = isDark
        ? (widget.cartItems.isEmpty ? AppColors.textDarkMuted : AppColors.primary)
        : Colors.white;

    return Row(
      children: [
        // Save as Draft Button
        Expanded(
          flex: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.cartItems.isEmpty || widget.isSubmitting
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    widget.onSaveDraft();
                  },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: draftBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: draftBorder),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 17,
                      color: draftFg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Save as Draft',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: draftFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Generate Bill (F8) Button
        Expanded(
          flex: 6,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.cartItems.isEmpty || widget.isSubmitting
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    widget.onGenerateBill();
                  },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: genButtonColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: widget.cartItems.isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: (isDark ? AppColors.accent : const Color(0xFF059669))
                              .withValues(alpha: isDark ? 0.35 : 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: widget.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: genTextColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generating Bill...',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: genTextColor,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.print_outlined,
                            size: 18,
                            color: genTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generate Bill (F8)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: genTextColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
