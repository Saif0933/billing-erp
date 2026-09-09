import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeValidationResult {
  final bool isValid;
  final String? cleanBarcode;
  final String? errorMessage;

  const BarcodeValidationResult({
    required this.isValid,
    this.cleanBarcode,
    this.errorMessage,
  });
}

class BarcodeValidator {
  const BarcodeValidator._();

  static BarcodeValidationResult validate(String rawCode, {BarcodeFormat? format}) {
    final clean = rawCode.replaceAll(RegExp(r'[\r\n\t]'), '').trim();

    if (clean.isEmpty) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Empty scan detected. Please align a product barcode.',
      );
    }

    // 1. Explicitly reject QR codes unless they contain a standard 8-14 digit product GTIN
    if (format == BarcodeFormat.qrCode && !RegExp(r'^\d{8,14}$').hasMatch(clean)) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode: QR codes / links are not product barcodes! Please scan the product 1D barcode.',
      );
    }

    // 2. Check for Website URLs & Domains
    if (clean.startsWith('http://') ||
        clean.startsWith('https://') ||
        clean.startsWith('www.') ||
        clean.contains('.com') ||
        clean.contains('.in') ||
        clean.contains('.org') ||
        clean.contains('.net') ||
        clean.contains('://')) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode: Scanned item is a Web URL! Please scan the 1D barcode on product packaging.',
      );
    }

    // 3. Check for UPI Payment QRs & Financial Payloads
    if (clean.startsWith('upi://') || (clean.contains('pa=') && clean.contains('pn=')) || clean.contains('mc=')) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode: Scanned item is a UPI Payment QR, not a product barcode!',
      );
    }

    // 4. Check for Wi-Fi / vCard / Contact / Email payloads
    if (clean.startsWith('WIFI:') ||
        clean.startsWith('BEGIN:VCARD') ||
        clean.startsWith('mailto:') ||
        clean.startsWith('tel:') ||
        clean.startsWith('smsto:') ||
        clean.startsWith('MATMSG:')) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode: Scanned item is a Wi-Fi/Contact card, not a product barcode!',
      );
    }

    // 5. Check for JSON / XML / structured multiline payloads
    if (clean.contains('{') ||
        clean.contains('}') ||
        clean.contains('<') ||
        clean.contains('>') ||
        clean.contains('=')) {
      return const BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode: Text payload detected! Please scan a standard 1D product barcode.',
      );
    }

    // 6. Flexible Product Barcode Formats (EAN-13, EAN-8, UPC, Code-128, Code-39, Alphanumeric SKU):
    // Accepts standard retail barcodes from 3 to 32 characters (digits, letters, hyphens, underscores, dots, slashes)
    final bool isStandardBarcode = RegExp(r'^[A-Za-z0-9\-_./]{3,32}$').hasMatch(clean);

    if (!isStandardBarcode) {
      return BarcodeValidationResult(
        isValid: false,
        errorMessage: 'Invalid Barcode ($clean). Please scan a valid product barcode (EAN-13 / EAN-8 / UPC / Code-128).',
      );
    }

    return BarcodeValidationResult(isValid: true, cleanBarcode: clean);
  }
}
