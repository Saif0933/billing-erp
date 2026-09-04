import 'package:flutter/material.dart';
import '../../../../core/models/billing_models.dart' as billing;
import '../../domain/entities/product.dart' as domain;
import '../../domain/models/product_listing_models.dart';

/// DTO for serializing and deserializing Product data between Frontend and Backend
class ProductDto {
  final String id;
  final String? businessId;
  final String name;
  final String code;
  final String itemCode;
  final String sku;
  final String barcode;
  final String hsnCode;
  final String primaryUnit;
  final String secondaryUnit;
  final String unit;
  final double gstRate;
  final double gstRatePercent;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double wholesalePrice;
  final double minStockLevel;
  final double openingStock;
  final double currentStock;
  final int stock;
  final String category;
  final String brand;
  final String warehouseId;
  final String warehouseName;
  final String rackOrBin;
  final bool hasBatchTracking;
  final bool hasSerialTracking;
  final bool hasExpiryTracking;
  final bool isActive;
  final String? categoryBadgeBgHex;
  final String? categoryBadgeTextHex;
  final bool isLowStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductDto({
    required this.id,
    this.businessId,
    required this.name,
    this.code = '',
    this.itemCode = '',
    this.sku = '',
    this.barcode = '',
    this.hsnCode = '',
    this.primaryUnit = 'PCS',
    this.secondaryUnit = '',
    this.unit = 'PCS',
    this.gstRate = 0.0,
    this.gstRatePercent = 0.0,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.mrp = 0.0,
    this.wholesalePrice = 0.0,
    this.minStockLevel = 0.0,
    this.openingStock = 0.0,
    this.currentStock = 0.0,
    this.stock = 0,
    this.category = 'General',
    this.brand = '',
    this.warehouseId = '',
    this.warehouseName = '',
    this.rackOrBin = '',
    this.hasBatchTracking = false,
    this.hasSerialTracking = false,
    this.hasExpiryTracking = false,
    this.isActive = true,
    this.categoryBadgeBgHex,
    this.categoryBadgeTextHex,
    this.isLowStock = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor from backend JSON response
  factory ProductDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final code = json['code']?.toString() ??
        json['itemCode']?.toString() ??
        '';

    final gst = parseDouble(json['gstRate'] ?? json['gstRatePercent'] ?? 0.0);
    final curStock = parseDouble(json['currentStock'] ?? json['openingStock'] ?? json['stock'] ?? 0.0);

    return ProductDto(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString(),
      name: json['name']?.toString() ?? '',
      code: code,
      itemCode: code,
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      primaryUnit: json['primaryUnit']?.toString() ?? 'PCS',
      secondaryUnit: json['secondaryUnit']?.toString() ?? '',
      unit: json['unit']?.toString() ?? json['primaryUnit']?.toString() ?? 'PCS',
      gstRate: gst,
      gstRatePercent: gst,
      purchasePrice: parseDouble(json['purchasePrice']),
      sellingPrice: parseDouble(json['sellingPrice']),
      mrp: parseDouble(json['mrp'] ?? json['sellingPrice']),
      wholesalePrice: parseDouble(json['wholesalePrice'] ?? json['sellingPrice']),
      minStockLevel: parseDouble(json['minStockLevel']),
      openingStock: parseDouble(json['openingStock']),
      currentStock: curStock,
      stock: parseInt(json['stock'] ?? curStock),
      category: json['category']?.toString() ?? 'General',
      brand: json['brand']?.toString() ?? '',
      warehouseId: json['warehouseId']?.toString() ?? '',
      warehouseName: json['warehouseName']?.toString() ?? '',
      rackOrBin: json['rackOrBin']?.toString() ?? '',
      hasBatchTracking: json['hasBatchTracking'] == true,
      hasSerialTracking: json['hasSerialTracking'] == true,
      hasExpiryTracking: json['hasExpiryTracking'] == true,
      isActive: json['isActive'] != false,
      categoryBadgeBgHex: json['categoryBadgeBg']?.toString(),
      categoryBadgeTextHex: json['categoryBadgeText']?.toString(),
      isLowStock: json['isLowStock'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Converts DTO to Flutter ProductListingItem (used in POS and Catalogue directory)
  ProductListingItem toListingItem() {
    Color parseHexColor(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      try {
        final clean = hex.replaceAll('#', '');
        return Color(int.parse('FF$clean', radix: 16));
      } catch (_) {
        return fallback;
      }
    }

    final badgeBg = parseHexColor(categoryBadgeBgHex, const Color(0xFFDCFCE7));
    final badgeText = parseHexColor(categoryBadgeTextHex, const Color(0xFF16A34A));

    return ProductListingItem(
      id: id,
      name: name,
      barcode: barcode,
      sku: sku.isNotEmpty ? sku : code,
      category: category,
      mrp: mrp > 0 ? mrp : sellingPrice,
      sellingPrice: sellingPrice,
      stock: stock > 0 ? stock : currentStock.round(),
      unit: unit,
      categoryBadgeBg: badgeBg,
      categoryBadgeText: badgeText,
      placeholderIcon: Icons.inventory_2_outlined,
      iconColor: badgeText,
    );
  }

  /// Converts DTO to billing_models.Product
  billing.Product toBillingProduct() {
    return billing.Product(
      id: id,
      name: name,
      code: code,
      sku: sku,
      barcode: barcode,
      hsnCode: hsnCode,
      primaryUnit: primaryUnit,
      secondaryUnit: secondaryUnit,
      gstRate: gstRate,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: mrp,
      wholesalePrice: wholesalePrice,
      minStockLevel: minStockLevel,
      openingStock: openingStock,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: category,
      brand: brand,
      isActive: isActive,
    );
  }

  /// Converts DTO to domain.Product
  domain.Product toDomainProduct() {
    return domain.Product(
      id: id,
      name: name,
      barcode: barcode,
      sku: sku.isNotEmpty ? sku : code,
      category: category,
      sellingPrice: sellingPrice,
      purchasePrice: purchasePrice,
      mrp: mrp > 0 ? mrp : sellingPrice,
      gstRate: gstRate,
      stock: stock > 0 ? stock : currentStock.round(),
      unit: unit,
    );
  }

  /// Factory from ProductListingItem
  factory ProductDto.fromListingItem(ProductListingItem item) {
    return ProductDto(
      id: item.id,
      name: item.name,
      code: item.sku,
      itemCode: item.sku,
      sku: item.sku,
      barcode: item.barcode,
      category: item.category,
      mrp: item.mrp,
      sellingPrice: item.sellingPrice,
      currentStock: item.stock.toDouble(),
      stock: item.stock,
      unit: item.unit,
      primaryUnit: item.unit,
    );
  }

  /// Factory from billing.Product
  factory ProductDto.fromBillingProduct(billing.Product product) {
    return ProductDto(
      id: product.id,
      name: product.name,
      code: product.code,
      itemCode: product.code,
      sku: product.sku,
      barcode: product.barcode,
      hsnCode: product.hsnCode,
      primaryUnit: product.primaryUnit,
      secondaryUnit: product.secondaryUnit,
      unit: product.primaryUnit,
      gstRate: product.gstRate,
      gstRatePercent: product.gstRate,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      mrp: product.mrp,
      wholesalePrice: product.wholesalePrice,
      minStockLevel: product.minStockLevel,
      openingStock: product.openingStock,
      currentStock: product.currentStock,
      stock: product.currentStock.round(),
      category: product.category,
      brand: product.brand,
      isActive: product.isActive,
    );
  }

  /// Convert to JSON payload for backend POST / PUT requests
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'name': name,
      'itemCode': code.isNotEmpty ? code : (itemCode.isNotEmpty ? itemCode : null),
      'sku': sku.isNotEmpty ? sku : null,
      'barcode': barcode.isNotEmpty ? barcode : null,
      'hsnCode': hsnCode.isNotEmpty ? hsnCode : null,
      'primaryUnit': primaryUnit.isNotEmpty ? primaryUnit : 'PCS',
      'secondaryUnit': secondaryUnit.isNotEmpty ? secondaryUnit : null,
      'gstRatePercent': gstRate,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
      'wholesalePrice': wholesalePrice,
      'minStockLevel': minStockLevel,
      'openingStock': openingStock,
      'category': category.isNotEmpty ? category : 'General',
      'brand': brand.isNotEmpty ? brand : null,
      'isActive': isActive,
    };

    if (warehouseId.isNotEmpty) {
      map['warehouseId'] = warehouseId;
    }

    if (!isUpdate && businessId != null && businessId!.isNotEmpty) {
      map['businessId'] = businessId;
    }

    return map;
  }
}

/// Paginated response from GET /api/v1/products
class ProductListResponse {
  final List<ProductDto> products;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const ProductListResponse({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['products'] as List<dynamic>? ?? [];
    // Filter out inactive products by default
    final products = rawList
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .where((dto) => dto.isActive)
        .toList();

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return ProductListResponse(
      products: products,
      total: (pagination['total'] as num?)?.toInt() ?? products.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPrevPage: pagination['hasPrevPage'] == true,
    );
  }
}

/// Metrics summary from GET /api/v1/products/metrics/summary
class ProductMetricsDto {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int lowStockCount;
  final double totalStockValue;
  final int totalCategories;
  final List<String> categories;

  const ProductMetricsDto({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.inactiveProducts = 0,
    this.lowStockCount = 0,
    this.totalStockValue = 0.0,
    this.totalCategories = 0,
    this.categories = const [],
  });

  factory ProductMetricsDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawCats = json['categories'] as List<dynamic>? ?? [];

    return ProductMetricsDto(
      totalProducts: parseInt(json['totalProducts']),
      activeProducts: parseInt(json['activeProducts']),
      inactiveProducts: parseInt(json['inactiveProducts']),
      lowStockCount: parseInt(json['lowStockCount']),
      totalStockValue: parseDouble(json['totalStockValue']),
      totalCategories: parseInt(json['totalCategories']),
      categories: rawCats.map((c) => c.toString()).toList(),
    );
  }
}
