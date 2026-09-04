import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_cart_provider.dart';
import 'product_not_found_dialog.dart';
import 'scanner_status_badge.dart';

/// Prominent Barcode Scanner & Search Bar designed specifically for
/// USB HID, Bluetooth HID, and manual keyboard barcode entry.
class BarcodeScannerBar extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;

  const BarcodeScannerBar({
    super.key,
    required this.focusNode,
    required this.controller,
  });

  @override
  ConsumerState<BarcodeScannerBar> createState() => _BarcodeScannerBarState();
}

class _BarcodeScannerBarState extends ConsumerState<BarcodeScannerBar> {
  bool _hasInputText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }
  }

  Future<void> _handleBarcodeSubmission(String barcode) async {
    final raw = barcode.trim();
    if (raw.isEmpty) return;

    // Clear input field immediately so the next scan is ready
    widget.controller.clear();

    // Ensure focus is kept on scanner field
    widget.focusNode.requestFocus();

    final result = await ref.read(billingCartProvider.notifier).processBarcode(raw);

    if (!mounted) return;

    if (!result.isSuccess && result.notFoundBarcode != null) {
      // Show non-blocking Product Not Found dialog
      await ProductNotFoundDialog.show(
        context,
        barcode: result.notFoundBarcode!,
        onDismissed: () {
          // Regain focus after modal close
          widget.focusNode.requestFocus();
        },
      );
    } else {
      // Always retain focus for rapid continuous scanning
      widget.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingCartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Status Header: Label + Live Scanner Status Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.barcode_reader,
                  size: 20,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Barcode Scanner Input',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            ScannerStatusBadge(isReady: state.isScannerReady),
          ],
        ),
        const SizedBox(height: 8),

        // Main Barcode Input Field
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.focusNode.hasFocus
                  ? const Color(0xFF15803D)
                  : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              width: widget.focusNode.hasFocus ? 2 : 1.2,
            ),
            boxShadow: widget.focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFF15803D).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Left Scan Icon with subtle pulse
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 24,
                  color: widget.focusNode.hasFocus
                      ? const Color(0xFF15803D)
                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ),

              // Text Field capturing USB/Bluetooth HID keystrokes & Manual input
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Scan barcode with USB/Bluetooth scanner or type & press Enter...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (value) => _handleBarcodeSubmission(value),
                ),
              ),

              // Loading Spinner if processing
              if (state.isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF15803D)),
                  ),
                ),

              // Clear Button if input has text
              if (_hasInputText && !state.isProcessing)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  tooltip: 'Clear Input',
                  onPressed: () {
                    widget.controller.clear();
                    widget.focusNode.requestFocus();
                  },
                ),

              // Submit / Add Button
              Container(
                margin: const EdgeInsets.all(4),
                child: ElevatedButton.icon(
                  onPressed: () => _handleBarcodeSubmission(widget.controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D), // Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Quick-Simulate Barcode Chips for Easy Testing Without Physical Scanner
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Text(
                'Quick Test:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickChip('Coca Cola (5449000200427)', '5449000200427', isDark),
              _buildQuickChip('Maggi (8901000100712)', '8901000100712', isDark),
              _buildQuickChip('Parle-G (8901719570017)', '8901719570017', isDark),
              _buildQuickChip('Amul Milk (8901262000012)', '8901262000012', isDark),
              _buildQuickChip('Tata Salt (8901058852271)', '8901058852271', isDark),
              _buildQuickChip('Unknown Barcode (9999999999999)', '9999999999999', isDark, isUnknown: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String title, String barcode, bool isDark, {bool isUnknown = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _handleBarcodeSubmission(barcode),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUnknown
                ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isUnknown
                  ? (isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D))
                  : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnknown ? Icons.help_outline : Icons.bolt,
                size: 13,
                color: isUnknown ? const Color(0xFFD97706) : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isUnknown
                      ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
