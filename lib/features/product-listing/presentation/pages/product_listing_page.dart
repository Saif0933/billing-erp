import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/billing_cart_provider.dart';
import '../widgets/barcode_scanner_bar.dart';
import '../widgets/empty_scanner_state.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/scanned_product_card.dart';
import '../widgets/scanned_products_table.dart';
import '../widgets/product_scanner_card.dart';
import '../widgets/recent_scans_card.dart';
import '../widgets/product_table_section.dart';

enum ProductListingViewMode {
  posBilling,
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
  ProductListingViewMode _viewMode = ProductListingViewMode.posBilling;
  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Maintain live clock
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _currentDateTime = DateTime.now());
    });

    // Automatically focus the barcode input on load for immediate USB/Bluetooth scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestScannerFocus();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _requestScannerFocus() {
    if (mounted && _viewMode == ProductListingViewMode.posBilling) {
      _barcodeFocusNode.requestFocus();
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
        child: KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: (event) {
            // If the user starts scanning or typing anywhere on the page, redirect focus to the barcode input
            if (event is KeyDownEvent &&
                !_barcodeFocusNode.hasFocus &&
                _viewMode == ProductListingViewMode.posBilling) {
              _requestScannerFocus();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: New Sale / Create Invoice + Metadata + View Switcher
                _buildHeader(context, cartState, isDark),
                const SizedBox(height: 14),

                // Inline Toast / Success Feedback Banner
                if (cartState.lastMessage != null)
                  _buildStatusBanner(cartState, isDark),

                // Mode-based View Rendering
                if (_viewMode == ProductListingViewMode.posBilling)
                  _buildPosBillingLayout(context, cartState, isDark)
                else
                  _buildCatalogueDirectoryLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Header Row: Invoice Title, Number, Live Clock, and View Mode Tabs
  Widget _buildHeader(BuildContext context, BillingCartState cartState, bool isDark) {
    final dateStr = DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_currentDateTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'New Sale / Create Invoice',
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
                        title: 'Barcode POS Billing',
                        icon: Icons.barcode_reader,
                        isSelected: _viewMode == ProductListingViewMode.posBilling,
                        onTap: () {
                          setState(() => _viewMode = ProductListingViewMode.posBilling);
                          _requestScannerFocus();
                        },
                        isDark: isDark,
                      ),
                    )
                  : _buildTabButton(
                      title: 'Barcode POS Billing',
                      icon: Icons.barcode_reader,
                      isSelected: _viewMode == ProductListingViewMode.posBilling,
                      onTap: () {
                        setState(() => _viewMode = ProductListingViewMode.posBilling);
                        _requestScannerFocus();
                      },
                      isDark: isDark,
                    ),
              if (isNarrow) const SizedBox(width: 4),
              isNarrow
                  ? Expanded(
                      child: _buildTabButton(
                        title: 'Catalogue Directory',
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
            titleSection,
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

  /// Main Barcode POS Billing View Layout (Responsive Desktop / Tablet / Mobile)
  Widget _buildPosBillingLayout(
    BuildContext context,
    BillingCartState cartState,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 960;

        // Scanner Bar Widget
        final scannerBar = BarcodeScannerBar(
          focusNode: _barcodeFocusNode,
          controller: _barcodeController,
        );

        // Scanned Products Section
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scanned Products (${cartState.itemCount})',
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

              // Products Body or Empty State
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

        // Order Summary Card Widget
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
