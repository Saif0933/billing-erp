import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum CameraScanStatus {
  added,
  alreadyScanned,
  notFound,
}

class POSCameraScannerDialog extends StatefulWidget {
  final Future<CameraScanStatus> Function(String barcode) onBarcodeScanned;
  final int Function() getCartItemCount;
  final double Function() getCartTotal;
  final VoidCallback? onViewCart;

  const POSCameraScannerDialog({
    super.key,
    required this.onBarcodeScanned,
    required this.getCartItemCount,
    required this.getCartTotal,
    this.onViewCart,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<CameraScanStatus> Function(String barcode) onBarcodeScanned,
    required int Function() getCartItemCount,
    required double Function() getCartTotal,
    VoidCallback? onViewCart,
  }) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => POSCameraScannerDialog(
        onBarcodeScanned: onBarcodeScanned,
        getCartItemCount: getCartItemCount,
        getCartTotal: getCartTotal,
        onViewCart: onViewCart,
      ),
    );
  }

  @override
  State<POSCameraScannerDialog> createState() => _POSCameraScannerDialogState();
}

class _POSCameraScannerDialogState extends State<POSCameraScannerDialog>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final TextEditingController _manualInputController = TextEditingController();
  bool _isTorchActive = false;
  bool _isManualInputVisible = false;
  bool _isProcessingScan = false;

  String? _lastScanFeedback;
  int _lastScanTimestamp = 0;

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
        BarcodeFormat.qrCode,
      ],
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle reads to once every 1.2 seconds to prevent multi-read of same item
    if (now - _lastScanTimestamp < 1200 || _isProcessingScan) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _lastScanTimestamp = now;
        _processBarcode(code);
        break;
      }
    }
  }

  Future<void> _processBarcode(String rawBarcode) async {
    final code = rawBarcode.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
    if (code.isEmpty) return;

    setState(() => _isProcessingScan = true);

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final status = await widget.onBarcodeScanned(code);

    if (!mounted) return;

    setState(() {
      _isProcessingScan = false;
      if (status == CameraScanStatus.added) {
        _lastScanFeedback = 'Added to bill!';
      } else if (status == CameraScanStatus.alreadyScanned) {
        _lastScanFeedback = 'Already scanned in current bill!';
      } else {
        _lastScanFeedback = 'Product not listed: $code';
      }
    });

    // Auto-clear feedback banner after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          if (_lastScanFeedback != null &&
              (_lastScanFeedback!.contains(code) ||
                  _lastScanFeedback!.contains('Added') ||
                  _lastScanFeedback!.contains('Already'))) {
            _lastScanFeedback = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cartItemCount = widget.getCartItemCount();
    final cartTotal = widget.getCartTotal();

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Pill Handle
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Camera Barcode Scanner',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flashlight Toggle
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        _isTorchActive
                            ? Icons.flash_on
                            : Icons.flash_off_outlined,
                        color: _isTorchActive
                            ? const Color(0xFFF59E0B)
                            : Colors.white70,
                        size: 20,
                      ),
                      tooltip: 'Toggle Flashlight',
                      onPressed: () {
                        _scannerController.toggleTorch();
                        setState(() => _isTorchActive = !_isTorchActive);
                      },
                    ),
                    const SizedBox(width: 2),
                    // Switch Camera
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(
                        Icons.flip_camera_ios_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: 'Switch Camera',
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                    const SizedBox(width: 2),
                    // Close Dialog
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Main Viewfinder Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Live Camera Stream
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (context, error) {
                    return Container(
                      color: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off_outlined,
                              size: 48,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Camera Preview Unavailable',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use manual barcode input below or test with barcode buffer.\n(${error.errorCode.name})',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.keyboard, size: 16),
                              label: const Text('Type Barcode Manually'),
                              onPressed: () {
                                setState(() => _isManualInputVisible = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Dark Translucent Surrounding Mask
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.52),
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
                          width: 280,
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

                // Green Reticle Frame & Laser Scan Line
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 180,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(280, 180),
                          painter: _ReticlePainter(),
                        ),
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 180 * _laserAnimation.value,
                              left: 14,
                              right: 14,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF10B981),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Instruction Prompt
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.fit_screen_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Align product barcode inside green frame',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Instant Feedback Banner
                if (_lastScanFeedback != null)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _lastScanFeedback == 'Added to bill!'
                              ? const Color(0xFF065F46)
                              : (_lastScanFeedback != null && _lastScanFeedback!.contains('Already')
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF991B1B)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _lastScanFeedback == 'Added to bill!'
                                  ? Icons.check_circle_rounded
                                  : (_lastScanFeedback != null && _lastScanFeedback!.contains('Already')
                                      ? Icons.info_outline_rounded
                                      : Icons.warning_amber_rounded),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _lastScanFeedback!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Manual Entry Expandable Bar
          if (_isManualInputVisible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualInputController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter barcode, SKU, or item code',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (val) {
                        _processBarcode(val);
                        _manualInputController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _processBarcode(_manualInputController.text);
                      _manualInputController.clear();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),

          // Bottom Bar with Live Cart Total & Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cart Status
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$cartItemCount items in current bill',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹ ${cartTotal.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Manual Keyboard Toggle
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'Type Barcode Manually',
                      icon: Icon(
                        _isManualInputVisible
                            ? Icons.keyboard_hide_outlined
                            : Icons.keyboard_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isManualInputVisible = !_isManualInputVisible;
                        });
                      },
                    ),
                    const SizedBox(width: 6),

                    // Done & View Cart Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text(
                        'Done & View Bill',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(context, true);
                        if (widget.onViewCart != null) {
                          widget.onViewCart!();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.5;
    const cornerLength = 26.0;
    const radius = 10.0;

    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-left corner
    final tl = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0),
          radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tl, paint);

    // Top-right corner
    final tr = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius),
          radius: const Radius.circular(radius))
      ..lineTo(w, cornerLength);
    canvas.drawPath(tr, paint);

    // Bottom-left corner
    final bl = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h - radius)
      ..arcToPoint(Offset(radius, h),
          radius: const Radius.circular(radius))
      ..lineTo(cornerLength, h);
    canvas.drawPath(bl, paint);

    // Bottom-right corner
    final br = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w - radius, h)
      ..arcToPoint(Offset(w, h - radius),
          radius: const Radius.circular(radius))
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(br, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
