import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/product_listing_models.dart';
import '../../domain/utils/barcode_validator.dart';
import '../providers/product_listing_provider.dart';
import 'product_quick_add_modal.dart';

class LiveCameraScannerDialog extends ConsumerStatefulWidget {
  const LiveCameraScannerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LiveCameraScannerDialog(),
    );
  }

  @override
  ConsumerState<LiveCameraScannerDialog> createState() =>
      _LiveCameraScannerDialogState();
}

class _LiveCameraScannerDialogState
    extends ConsumerState<LiveCameraScannerDialog>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  bool _isTorchActive = false;

  ProductListingItem? _currentScannedProduct;
  String? _scanErrorMessage;
  final List<ProductListingItem> _scannedSessionList = [];
  int _lastScanTime = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf14,
      ],
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle duplicate reads to once every 1.5 seconds
    if (now - _lastScanTime < 1500) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _lastScanTime = now;
        _handleFoundBarcode(code, format: barcode.format);
        break;
      }
    }
  }

  void _handleFoundBarcode(String rawCode, {BarcodeFormat? format}) {
    // 1. Strict validation: Only valid product barcodes are processed
    final validation = BarcodeValidator.validate(rawCode, format: format);

    if (!validation.isValid) {
      setState(() {
        _scanErrorMessage = validation.errorMessage;
        _currentScannedProduct = null;
      });

      AppFeedback.showSnackbar(
        context,
        message: validation.errorMessage ?? 'Invalid Barcode! Please scan a product packaging barcode.',
        isError: true,
      );
      return;
    }

    // 2. Valid barcode found
    final cleanCode = validation.cleanBarcode!;
    final notifier = ref.read(productListingProvider.notifier);
    final scannedItem = notifier.handleScannedBarcode(cleanCode);

    if (scannedItem != null) {
      setState(() {
        _scanErrorMessage = null;
        _currentScannedProduct = scannedItem;
        if (!_scannedSessionList.any((p) => p.barcode == scannedItem.barcode)) {
          _scannedSessionList.add(scannedItem);
        }
      });

      AppFeedback.showSnackbar(
        context,
        message: 'Product Listed: ${scannedItem.name}',
      );
    }
  }

  Future<void> _triggerManualSimulatedScan() async {
    final notifier = ref.read(productListingProvider.notifier);
    final scannedItem = await notifier.simulateScan();

    setState(() {
      _scanErrorMessage = null;
      _currentScannedProduct = scannedItem;
      if (!_scannedSessionList.any((p) => p.barcode == scannedItem.barcode)) {
        _scannedSessionList.add(scannedItem);
      }
    });

    if (mounted) {
      AppFeedback.showSnackbar(
        context,
        message: 'Product Listed: ${scannedItem.name}',
      );
    }
  }

  void _finishAndDone() {
    Navigator.pop(context);
    if (_scannedSessionList.isNotEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'Scan Done! ${_scannedSessionList.length} items listed & added.',
      );
      if (_currentScannedProduct != null) {
        ProductQuickAddModal.show(context, _currentScannedProduct!);
      }
    } else {
      AppFeedback.showSnackbar(
        context,
        message: 'Scan session completed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Handle Bar
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.camera_alt_outlined, color: Color(0xFF22C55E), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Live Barcode Scanner',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Torch Toggle
                    IconButton(
                      icon: Icon(
                        _isTorchActive ? Icons.flash_on : Icons.flash_off_outlined,
                        color: _isTorchActive ? const Color(0xFFF59E0B) : Colors.white70,
                      ),
                      tooltip: 'Toggle Flashlight',
                      onPressed: () {
                        _scannerController.toggleTorch();
                        setState(() => _isTorchActive = !_isTorchActive);
                      },
                    ),
                    // Switch Camera (Front/Back)
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white70),
                      tooltip: 'Switch Camera',
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                    // Close
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Live Camera Stream Container with Target Viewfinder Overlay
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Real Live Camera View
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (context, error) {
                    return Container(
                      color: const Color(0xFF18181B),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            Text(
                              'Camera Access: ${error.errorCode.name}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                              ),
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text('Simulate Barcode Scan', style: TextStyle(color: Colors.white)),
                              onPressed: _triggerManualSimulatedScan,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Darkened Overlay Border Around Target Area
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.55),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 270,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Green Target Reticle Frame
                Center(
                  child: SizedBox(
                    width: 270,
                    height: 180,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(270, 180),
                          painter: _ReticleCornerPainter(),
                        ),
                        // Animated Scanning Laser Line
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 180 * _laserAnimation.value,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 1. Top Floating Error Banner (When non-barcode / invalid item is scanned)
                if (_scanErrorMessage != null)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF450A0A).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'INVALID SCAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFCA5A5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _scanErrorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Top Floating Scanned Product Name Banner (When valid barcode is scanned)
                if (_currentScannedProduct != null && _scanErrorMessage == null)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LISTED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _currentScannedProduct!.category,
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _currentScannedProduct!.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Barcode: ${_currentScannedProduct!.barcode}  •  Price: ₹${_currentScannedProduct!.sellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF86EFAC)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Bottom Reticle Instruction Hint
                if (_currentScannedProduct == null && _scanErrorMessage == null)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFF22C55E)),
                          SizedBox(width: 8),
                          Text(
                            'Align product barcode inside the green frame',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Control Panel: [ Simulate Scan ] + [ Scan Done Button ]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                // Simulate Scan Fallback Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.flash_auto, size: 16, color: Color(0xFF22C55E)),
                  label: const Text('Test Scan', style: TextStyle(fontSize: 12)),
                  onPressed: _triggerManualSimulatedScan,
                ),
                const SizedBox(width: 12),

                // Primary "Scan Done" Action Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D), // Green
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    label: Text(
                      _scannedSessionList.isEmpty
                          ? 'Scan Done'
                          : 'Scan Done (${_scannedSessionList.length} Items)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _finishAndDone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticleCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const len = 24.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
