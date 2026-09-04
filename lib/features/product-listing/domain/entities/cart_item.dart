import 'product.dart';

/// Domain entity representing a scanned/added product item in the active billing cart.
class CartItem {
  final Product product;
  final int quantity;
  final double discountPercent; // e.g. 5.0 for 5% item discount
  final DateTime addedAt;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercent = 0.0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Total gross price before tax and discount
  double get grossTotal => product.sellingPrice * quantity;

  /// Discount amount for this line item
  double get discountAmount => grossTotal * (discountPercent / 100.0);

  /// Net price after discount (if prices are GST inclusive or base)
  double get netAmount => grossTotal - discountAmount;

  /// Calculated GST component amount based on gstRate
  double get gstAmount => (netAmount * (product.gstRate / (100.0 + product.gstRate)));

  /// Taxable base amount excluding GST
  double get taxableAmount => netAmount - gstAmount;

  /// Final payable amount for this item row
  double get totalAmount => netAmount;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discountPercent,
    DateTime? addedAt,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && product.id == other.product.id;

  @override
  int get hashCode => product.id.hashCode;
}
