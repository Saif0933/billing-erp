import 'package:flutter/material.dart';

/// Domain entity representing a product in the billing & inventory system.
class Product {
  final String id;
  final String name;
  final String barcode;
  final String sku;
  final String category;
  final double sellingPrice;
  final double purchasePrice;
  final double mrp;
  final double gstRate; // e.g. 18.0 for 18% GST
  final int stock;
  final String? imageUrl;
  final String unit; // 'pcs', 'kg', 'ltr', 'pack'
  final Color? categoryBadgeColor;
  final IconData placeholderIcon;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.sku,
    required this.category,
    required this.sellingPrice,
    this.purchasePrice = 0.0,
    required this.mrp,
    this.gstRate = 18.0,
    this.stock = 100,
    this.imageUrl,
    this.unit = 'pcs',
    this.categoryBadgeColor,
    this.placeholderIcon = Icons.inventory_2_outlined,
  });

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    String? sku,
    String? category,
    double? sellingPrice,
    double? purchasePrice,
    double? mrp,
    double? gstRate,
    int? stock,
    String? imageUrl,
    String? unit,
    Color? categoryBadgeColor,
    IconData? placeholderIcon,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      categoryBadgeColor: categoryBadgeColor ?? this.categoryBadgeColor,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
