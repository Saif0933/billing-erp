import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/billing_cart_provider.dart';
import '../providers/product_listing_provider.dart';
import '../widgets/barcode_scanner_bar.dart';
import '../widgets/empty_scanner_state.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/product_not_found_dialog.dart';
import '../widgets/scanned_product_card.dart';
import '../widgets/scanned_products_table.dart';
import '../widgets/product_scanner_card.dart';
import '../widgets/recent_scans_card.dart';
import '../widgets/product_table_section.dart';

enum ProductListingViewMode {
  scanAndList,
  catalogueDirectory,
}

class ProductListingPage extends ConsumerStatefulWidget {
  const ProductListingPage({super.key});

  @override
  ConsumerState<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends ConsumerState<ProductListingPage> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  final StringBuffer _hardwareScanBuffer = StringBuffer();
  DateTime _lastHardwareKeyTime = DateTime.now();
  DateTime? _lastHandledScanTime;
  String? _lastHandledBarcode;

  ProductListingViewMode _viewMode = ProductListingViewMode.scanAndList;
  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Maintain live clock
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _currentDateTime = DateTime.now());
    });

    // Register global hardware keyboard interceptor for TVS-E & USB/Bluetooth HID scanners
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);

    // Automatically focus the barcode input on load for immediate USB/Bluetooth scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestScannerFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _clockTimer?.cancel();
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _requestScannerFocus() {
    if (mounted && _viewMode == ProductListingViewMode.scanAndList) {
      _barcodeFocusNode.requestFocus();
    }
  }

  String? _getCharFromLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) return '0';
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) return '1';
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) return '2';
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) return '3';
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) return '4';
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) return '5';
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) return '6';
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) return '7';
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) return '8';
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) return '9';
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) return '-';
    if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) return '.';
    if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) return '/';
    if (key.keyLabel.length == 1) return key.keyLabel;
    return null;
  }

  /// Global interceptor capturing TVS-E and USB/Bluetooth HID barcode scanner keystrokes
  /// directly from hardware before focus displacement or race conditions occur.
  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final elapsedMs = now.difference(_lastHardwareKeyTime).inMilliseconds;
    _lastHardwareKeyTime = now;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.character == '\n' ||
        event.character == '\r';

    // Check if another text field (e.g. dialog text field) is actively focused
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isAnotherFieldFocused = primaryFocus != null &&
        primaryFocus != _barcodeFocusNode &&
        primaryFocus.context?.widget is EditableText;

    if (isEnter) {
      final bufferBarcode = _hardwareScanBuffer.toString().trim();
      _hardwareScanBuffer.clear();

      final inputBarcode = _barcodeController.text.trim();
      final codeToProcess = bufferBarcode.isNotEmpty ? bufferBarcode : inputBarcode;

      if (codeToProcess.length >= 2) {
        _onBarcodeScanned(codeToProcess);
        return true; // Consume Enter key so it doesn't trigger buttons or dialog submits
      }
      return false;
    }

    // If another text field is focused and keys arrive at normal human typing speed,
    // let user type normally into that field.
    if (isAnotherFieldFocused && elapsedMs > 100) {
      _hardwareScanBuffer.clear();
      return false;
    }

    String? char = event.character;
    if (char == null || char.isEmpty || char == '\u0000') {
      char = _getCharFromLogicalKey(event.logicalKey);
    }

    if (char != null && char.isNotEmpty && RegExp(r'^[A-Za-z0-9\-_./]$').hasMatch(char)) {
      // Reset buffer if elapsed time between keystrokes exceeds 450ms
      if (elapsedMs > 450) {
        _hardwareScanBuffer.clear();
      }
      _hardwareScanBuffer.write(char);

      // Echo to text field for immediate visual feedback if scanner input field is not focused
      if (!_barcodeFocusNode.hasFocus) {
        _barcodeController.text = _hardwareScanBuffer.toString();
        _barcodeController.selection = TextSelection.collapsed(
          offset: _barcodeController.text.length,
        );
      }
      return false;
    }

    return false;
  }

  /// Unified barcode scanner processor — lists products (does not sell).
  Future<void> _onBarcodeScanned(String barcode) async {
    final clean = barcode.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
    if (clean.isEmpty) return;

    final now = DateTime.now();
    if (_lastHandledBarcode == clean &&
        _lastHandledScanTime != null &&
        now.difference(_lastHandledScanTime!).inMilliseconds < 600) {
      return;
    }
    _lastHandledBarcode = clean;
    _lastHandledScanTime = now;

    _hardwareScanBuffer.clear();
    _barcodeController.clear();

    if (_viewMode != ProductListingViewMode.scanAndList) {
      if (mounted) {
        setState(() => _viewMode = ProductListingViewMode.scanAndList);
      }
    }

    final result = await ref.read(billingCartProvider.notifier).processBarcode(clean);

    try {
      ref.read(productListingProvider.notifier).handleScannedBarcode(clean);
    } catch (_) {}

    _requestScannerFocus();

    if (!mounted) return;

    // New EAN — ask for name, unit price & GST manually
    if (!result.isSuccess && result.notFoundBarcode != null) {
      await ProductNotFoundDialog.show(
        context,
        barcode: result.notFoundBarcode!,
        onDismissed: () {
          _requestScannerFocus();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.products)) {
      return const LockedFeaturePage(featureName: 'Product Catalogue');
    }

    final cartState = ref.watch(billingCartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 16,
            vertical: MediaQuery.sizeOf(context).width < 600 ? 12 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header: Product Listing + View Switcher
              _buildHeader(context, cartState, isDark),
              const SizedBox(height: 14),

              if (cartState.lastMessage != null)
                _buildStatusBanner(cartState, isDark),

              if (_viewMode == ProductListingViewMode.scanAndList)
                _buildScanAndListLayout(context, cartState, isDark)
              else
                _buildCatalogueDirectoryLayout(),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Header: Product Listing title + view mode tabs
  Widget _buildHeader(BuildContext context, BillingCartState cartState, bool isDark) {
    final dateStr = DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_currentDateTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final isVeryNarrow = constraints.maxWidth < 450;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Product Listing',
                  style: TextStyle(
                    fontSize: isNarrow ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Text(
                    cartState.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Scan EAN → enter price & GST → save to database',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        );

        final modeSelector = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
            children: [
              isNarrow
                  ? Expanded(
                      child: _buildTabButton(
                        title: isVeryNarrow ? 'Scan & List' : 'Scan & List Products',
                        icon: Icons.barcode_reader,
                        isSelected: _viewMode == ProductListingViewMode.scanAndList,
                        onTap: () {
                          setState(() => _viewMode = ProductListingViewMode.scanAndList);
                          _requestScannerFocus();
                        },
                        isDark: isDark,
                      ),
                    )
                  : _buildTabButton(
                      title: 'Scan & List Products',
                      icon: Icons.barcode_reader,
                      isSelected: _viewMode == ProductListingViewMode.scanAndList,
                      onTap: () {
                        setState(() => _viewMode = ProductListingViewMode.scanAndList);
                        _requestScannerFocus();
                      },
                      isDark: isDark,
                    ),
              if (isNarrow) const SizedBox(width: 4),
              isNarrow
                  ? Expanded(
                      child: _buildTabButton(
                        title: isVeryNarrow ? 'Catalogue' : 'Catalogue Directory',
                        icon: Icons.grid_view_outlined,
                        isSelected: _viewMode == ProductListingViewMode.catalogueDirectory,
                        onTap: () {
                          setState(() => _viewMode = ProductListingViewMode.catalogueDirectory);
                        },
                        isDark: isDark,
                      ),
                    )
                  : _buildTabButton(
                      title: 'Catalogue Directory',
                      icon: Icons.grid_view_outlined,
                      isSelected: _viewMode == ProductListingViewMode.catalogueDirectory,
                      onTap: () {
                        setState(() => _viewMode = ProductListingViewMode.catalogueDirectory);
                      },
                      isDark: isDark,
                    ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 10),
              modeSelector,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            modeSelector,
          ],
        );
      },
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF15803D)
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Subtle non-disruptive feedback banner
  Widget _buildStatusBanner(BillingCartState state, bool isDark) {
    final isError = state.isLastMessageError;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isError
            ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? (isDark ? const Color(0xFFB45309) : const Color(0xFFFCA5A5))
              : (isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 18,
            color: isError ? Colors.redAccent : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.lastMessage ?? '',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isError
                    ? (isDark ? const Color(0xFFFCA5A5) : Colors.red.shade800)
                    : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () {
              ref.read(billingCartProvider.notifier).clearMessage();
              _requestScannerFocus();
            },
          ),
        ],
      ),
    );
  }

  /// Scan & List layout — list products with manual unit price & GST (not a sale).
  Widget _buildScanAndListLayout(
    BuildContext context,
    BillingCartState cartState,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 960;

        final scannerBar = BarcodeScannerBar(
          focusNode: _barcodeFocusNode,
          controller: _barcodeController,
          onBarcodeSubmitted: _onBarcodeScanned,
        );

        final productsContent = Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products to List (${cartState.itemCount})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (cartState.items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(billingCartProvider.notifier).startNewInvoice();
                          _requestScannerFocus();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
                        label: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (cartState.items.isEmpty)
                EmptyScannerState(onFocusRequested: _requestScannerFocus)
              else if (isMobile)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: cartState.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return ScannedProductCard(
                      item: item,
                      onActionCompleted: _requestScannerFocus,
                    );
                  },
                )
              else
                ScannedProductsTable(
                  onActionCompleted: _requestScannerFocus,
                ),
            ],
          ),
        );

        final summaryCard = OrderSummaryCard(
          onFocusRequested: _requestScannerFocus,
        );

        // Mobile Layout (Single Column)
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              scannerBar,
              const SizedBox(height: 16),
              productsContent,
              const SizedBox(height: 16),
              summaryCard,
              const SizedBox(height: 24),
            ],
          );
        }

        // Tablet Layout (2 Columns)
        if (isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              scannerBar,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: productsContent),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: summaryCard),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        }

        // Desktop Layout (3-Area / Wide Split)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            scannerBar,
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: productsContent,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: summaryCard,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Catalogue Directory View Layout (Catalog Table, Camera Scanner, Stock view)
  Widget _buildCatalogueDirectoryLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 960;

        final leftPanel = Column(
          children: const [
            ProductScannerCard(),
            SizedBox(height: 16),
            RecentScansCard(),
          ],
        );

        const rightPanel = ProductTableSection();

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftPanel,
              const SizedBox(height: 16),
              rightPanel,
              const SizedBox(height: 24),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 340,
              child: leftPanel,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: rightPanel,
            ),
          ],
        );
      },
    );
  }
}
