import '../../../../core/models/billing_models.dart';

const kProductNotListedSaleMessage =
    'This barcode is not in Product Listing. The product cannot be sold until it is listed.';

const kProductNotListedPurchaseMessage =
    'This product is not in Product Listing. List it first, then add it to the purchase bill.';

bool isSeededMockProductId(String id) {
  return RegExp(r'^prod_\d+$').hasMatch(id.trim()) ||
      id.trim().startsWith('sp_');
}

bool isListedSellableProduct(Product product) {
  return product.isActive && !isSeededMockProductId(product.id);
}

String productNotListedScanMessage(String barcode) {
  final code = barcode.trim();
  if (code.isEmpty) {
    return kProductNotListedSaleMessage;
  }
  return 'Barcode "$code" is not in Product Listing. This product cannot be sold until it is listed.';
}

bool billingProductMatchesCode(Product product, String code) {
  final clean = code.trim().toUpperCase();
  if (clean.isEmpty) return false;
  return product.barcode.trim().toUpperCase() == clean ||
      product.sku.trim().toUpperCase() == clean ||
      product.code.trim().toUpperCase() == clean ||
      product.id.trim().toUpperCase() == clean;
}

bool looksLikeBarcode(String value) {
  final clean = value.trim();
  if (clean.length < 6) return false;
  return RegExp(r'^[A-Za-z0-9\-_./]+$').hasMatch(clean) &&
      RegExp(r'\d').hasMatch(clean);
}
