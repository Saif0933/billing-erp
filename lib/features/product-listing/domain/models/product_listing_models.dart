import 'package:flutter/material.dart';

class ProductListingItem {
  final String id;
  final String name;
  final String barcode;
  final String sku;
  final String category;
  final double mrp;
  final double sellingPrice;
  final int stock;
  final String imagePath;
  final Color categoryBadgeBg;
  final Color categoryBadgeText;
  final IconData placeholderIcon;
  final Color iconColor;
  final String unit;
  final DateTime? lastScannedAt;

  const ProductListingItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.sku,
    required this.category,
    required this.mrp,
    required this.sellingPrice,
    required this.stock,
    this.imagePath = '',
    required this.categoryBadgeBg,
    required this.categoryBadgeText,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.iconColor = const Color(0xFF15803D),
    this.unit = 'pcs',
    this.lastScannedAt,
  });

  ProductListingItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? sku,
    String? category,
    double? mrp,
    double? sellingPrice,
    int? stock,
    String? imagePath,
    Color? categoryBadgeBg,
    Color? categoryBadgeText,
    IconData? placeholderIcon,
    Color? iconColor,
    String? unit,
    DateTime? lastScannedAt,
  }) {
    return ProductListingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
      categoryBadgeBg: categoryBadgeBg ?? this.categoryBadgeBg,
      categoryBadgeText: categoryBadgeText ?? this.categoryBadgeText,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
      iconColor: iconColor ?? this.iconColor,
      unit: unit ?? this.unit,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
    );
  }
}
