import 'package:flutter/material.dart';
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
  final VoidCallback? onSettingsTap;

  const SalesCurrentBillPanel({
    super.key,
    required this.billNumber,
    required this.customerName,
    required this.cartItems,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.note,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Current Bill, Bill No., Settings Icon
          _buildHeader(),
          const SizedBox(height: 8),

          // Customer Selector
          _buildCustomerSelector(),
          const SizedBox(height: 8),

          // Cart Table Header
          _buildCartTableHeader(),
          const SizedBox(height: 4),

          // Scrollable Cart Table Items
          Expanded(
            child: widget.cartItems.isEmpty
                ? _buildEmptyCartView()
                : _buildCartItemsList(),
          ),

          const SizedBox(height: 4),

          // Actions Row: "+ Add Note" & "Clear Cart"
          _buildCartQuickActions(),
          const SizedBox(height: 6),

          // Note indicator if note is present
          if (widget.note != null && widget.note!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: ${widget.note}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Financial Breakdown
          _buildFinancialBreakdown(),
          const SizedBox(height: 8),

          // Bottom Buttons: Save as Draft & Generate Bill (F8)
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            'Current Bill',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
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
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
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
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerSelector() {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.add,
              color: Color(0xFF374151),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.5),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 18,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Product',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(
            width: 76,
            child: Text(
              'Qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              'Rate (₹)',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'Amount (₹)',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
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
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFFF3F4F6),
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
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      children: [
                        TextSpan(
                          text: ' ${item.product.weight}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quantity Stepper: [-  Qty  +]
                Container(
                  width: 76,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => widget.onDecrementQty(index),
                        borderRadius: BorderRadius.circular(4),
                        child: const SizedBox(
                          width: 22,
                          height: 24,
                          child: Center(
                            child: Icon(
                              Icons.remove,
                              size: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onIncrementQty(index),
                        borderRadius: BorderRadius.circular(4),
                        child: const SizedBox(
                          width: 22,
                          height: 24,
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Rate
                SizedBox(
                  width: 52,
                  child: Text(
                    item.rate.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                // Amount
                SizedBox(
                  width: 60,
                  child: Text(
                    item.amount.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),

                // Delete button
                SizedBox(
                  width: 24,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                    splashRadius: 12,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    hoverColor: const Color(0xFFFEE2E2),
                    onPressed: () => widget.onRemoveItem(index),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.shopping_cart_outlined,
            size: 40,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 8),
          Text(
            'Current Bill is empty',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Click on products to add to cart',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: widget.onAddNote,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: const [
                Icon(Icons.add, size: 14, color: Color(0xFF059669)),
                SizedBox(width: 4),
                Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
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
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  'Clear Cart',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.cartItems.isEmpty
                        ? const Color(0xFFD1D5DB)
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

  Widget _buildFinancialBreakdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'Total Items',
            value: '$totalItemsCount',
            isBold: false,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'Subtotal',
            value: '₹ ${subtotal.toStringAsFixed(2)}',
            isBold: true,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: '% Discount',
            value: '₹ ${effectiveDiscount.toStringAsFixed(2)}',
            icon: Icons.percent,
            iconColor: const Color(0xFF3B82F6),
            valueColor: const Color(0xFF059669),
            isBold: false,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'CGST',
            value: '₹ ${cgst.toStringAsFixed(2)}',
            icon: Icons.receipt_outlined,
            iconColor: const Color(0xFF6B7280),
            isBold: false,
          ),
          const SizedBox(height: 3),
          _buildSummaryRow(
            label: 'SGST',
            value: '₹ ${sgst.toStringAsFixed(2)}',
            icon: Icons.receipt_outlined,
            iconColor: const Color(0xFF6B7280),
            isBold: false,
          ),
          const SizedBox(height: 6),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '₹ ${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
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
                  color: (iconColor ?? const Color(0xFF6B7280)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 11,
                    color: iconColor ?? const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        // Save as Draft Button
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: widget.cartItems.isEmpty ? null : widget.onSaveDraft,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.description_outlined,
                      size: 17,
                      color: Color(0xFF374151),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Save as Draft',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
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
          child: InkWell(
            onTap: widget.cartItems.isEmpty ? null : widget.onGenerateBill,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669), // Solid green matching screenshot
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33059669),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.print_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Generate Bill (F8)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
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
    );
  }
}
