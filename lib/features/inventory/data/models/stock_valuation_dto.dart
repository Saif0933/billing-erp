import 'dart:math' as math;

import '../../../../core/models/billing_models.dart';

double parseStockNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  if (val is Map && val.containsKey('d') && val['d'] is List) {
    final list = val['d'] as List;
    final digits = list.join('');
    final exp = (val['e'] as num?)?.toInt() ?? 0;
    final sign = (val['s'] as num?)?.toInt() ?? 1;
    final rawNum = double.tryParse(digits) ?? 0.0;
    final power = exp - digits.length + 1;
    return sign * rawNum * math.pow(10, power).toDouble();
  }
  return double.tryParse(val.toString()) ?? 0.0;
}

int parseStockInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return parseStockNum(val).toInt();
}

DateTime parseStockDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  return DateTime.tryParse(val.toString()) ?? DateTime.now();
}

class StockValuationSummaryDto {
  final double totalStockValuation;
  final double totalUnits;
  final int uniqueProductCount;
  final int inStockCount;
  final int lowStockCount;
  final int zeroStockCount;
  final String valuationMethod;

  const StockValuationSummaryDto({
    this.totalStockValuation = 0.0,
    this.totalUnits = 0.0,
    this.uniqueProductCount = 0,
    this.inStockCount = 0,
    this.lowStockCount = 0,
    this.zeroStockCount = 0,
    this.valuationMethod = 'PURCHASE_PRICE',
  });

  factory StockValuationSummaryDto.fromJson(Map<String, dynamic> json) {
    return StockValuationSummaryDto(
      totalStockValuation: parseStockNum(json['totalStockValuation']),
      totalUnits: parseStockNum(json['totalUnits']),
      uniqueProductCount: parseStockInt(json['uniqueProductCount'] ?? json['uniqueProductCount']),
      inStockCount: parseStockInt(json['inStockCount']),
      lowStockCount: parseStockInt(json['lowStockCount']),
      zeroStockCount: parseStockInt(json['zeroStockCount']),
      valuationMethod: json['valuationMethod']?.toString() ?? 'PURCHASE_PRICE',
    );
  }
}

class StockValuationItemDto {
  final String productId;
  final String name;
  final String itemCode;
  final String sku;
  final String barcode;
  final String primaryUnit;
  final String category;
  final String? warehouseId;
  final String? warehouseName;
  final double purchasePrice;
  final double sellingPrice;
  final double openingStock;
  final double currentStock;
  final double minStockLevel;
  final double stockValue;
  final bool isLowStock;
  final bool isActive;

  const StockValuationItemDto({
    required this.productId,
    required this.name,
    this.itemCode = '',
    this.sku = '',
    this.barcode = '',
    this.primaryUnit = 'PCS',
    this.category = 'General',
    this.warehouseId,
    this.warehouseName,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.openingStock = 0.0,
    this.currentStock = 0.0,
    this.minStockLevel = 0.0,
    this.stockValue = 0.0,
    this.isLowStock = false,
    this.isActive = true,
  });

  factory StockValuationItemDto.fromJson(Map<String, dynamic> json) {
    return StockValuationItemDto(
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      itemCode: json['itemCode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      primaryUnit: json['primaryUnit']?.toString() ?? 'PCS',
      category: json['category']?.toString() ?? 'General',
      warehouseId: json['warehouseId']?.toString(),
      warehouseName: json['warehouseName']?.toString(),
      purchasePrice: parseStockNum(json['purchasePrice']),
      sellingPrice: parseStockNum(json['sellingPrice']),
      openingStock: parseStockNum(json['openingStock']),
      currentStock: parseStockNum(json['currentStock']),
      minStockLevel: parseStockNum(json['minStockLevel']),
      stockValue: parseStockNum(json['stockValue']),
      isLowStock: json['isLowStock'] == true,
      isActive: json['isActive'] != false,
    );
  }

  Product toProduct() {
    return Product(
      id: productId,
      name: name,
      code: itemCode,
      sku: sku,
      barcode: barcode,
      hsnCode: '',
      primaryUnit: primaryUnit,
      secondaryUnit: '',
      gstRate: 0,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: sellingPrice,
      wholesalePrice: sellingPrice,
      minStockLevel: minStockLevel,
      openingStock: openingStock,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: category,
      brand: '',
      isActive: isActive,
      warehouseStocks: warehouseId != null && warehouseId!.isNotEmpty
          ? {warehouseId!: currentStock}
          : const {},
    );
  }
}

class StockValuationItemsResponseDto {
  final List<StockValuationItemDto> items;
  final double pageStockValue;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const StockValuationItemsResponseDto({
    this.items = const [],
    this.pageStockValue = 0.0,
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
  });

  factory StockValuationItemsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return StockValuationItemsResponseDto(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => StockValuationItemDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pageStockValue: parseStockNum(json['pageStockValue']),
      total: parseStockInt(pagination['total'] ?? json['total']),
      page: parseStockInt(pagination['page'] ?? json['page'] ?? 1),
      limit: parseStockInt(pagination['limit'] ?? json['limit'] ?? 50),
      totalPages: parseStockInt(pagination['totalPages'] ?? json['totalPages'] ?? 1),
    );
  }
}

class StockLedgerEntryDto {
  final String id;
  final String productId;
  final String productName;
  final String itemCode;
  final String warehouseId;
  final String warehouseName;
  final String movementType;
  final double quantity;
  final double? unitCost;
  final double stockValueImpact;
  final String referenceNumber;
  final String? referenceType;
  final String? referenceId;
  final DateTime movementDate;
  final DateTime createdAt;

  const StockLedgerEntryDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.itemCode = '',
    this.warehouseId = '',
    this.warehouseName = '',
    this.movementType = 'STOCK_ADJUSTMENT',
    this.quantity = 0.0,
    this.unitCost,
    this.stockValueImpact = 0.0,
    this.referenceNumber = '',
    this.referenceType,
    this.referenceId,
    required this.movementDate,
    required this.createdAt,
  });

  factory StockLedgerEntryDto.fromJson(Map<String, dynamic> json) {
    return StockLedgerEntryDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      itemCode: json['itemCode']?.toString() ?? '',
      warehouseId: json['warehouseId']?.toString() ?? '',
      warehouseName: json['warehouseName']?.toString() ?? '',
      movementType: json['movementType']?.toString() ?? 'STOCK_ADJUSTMENT',
      quantity: parseStockNum(json['quantity']),
      unitCost: json['unitCost'] == null ? null : parseStockNum(json['unitCost']),
      stockValueImpact: parseStockNum(json['stockValueImpact']),
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      movementDate: parseStockDate(json['movementDate']),
      createdAt: parseStockDate(json['createdAt']),
    );
  }

  StockMovementType toDomainType() {
    switch (movementType.toUpperCase().replaceAll('-', '_')) {
      case 'OPENING_STOCK':
        return StockMovementType.openingStock;
      case 'PURCHASE':
        return StockMovementType.purchase;
      case 'SALES':
      case 'SALE':
        return StockMovementType.sale;
      case 'SALES_RETURN':
        return StockMovementType.salesReturn;
      case 'PURCHASE_RETURN':
        return StockMovementType.purchaseReturn;
      default:
        return StockMovementType.adjustment;
    }
  }

  StockMovement toDomain() {
    return StockMovement(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      type: toDomainType(),
      date: movementDate,
      referenceNumber: referenceNumber,
      warehouseId: warehouseId.isEmpty ? 'main' : warehouseId,
    );
  }
}

class StockMovementsResponseDto {
  final List<StockLedgerEntryDto> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const StockMovementsResponseDto({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
  });

  factory StockMovementsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return StockMovementsResponseDto(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => StockLedgerEntryDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      total: parseStockInt(pagination['total'] ?? json['total']),
      page: parseStockInt(pagination['page'] ?? json['page'] ?? 1),
      limit: parseStockInt(pagination['limit'] ?? json['limit'] ?? 50),
      totalPages: parseStockInt(pagination['totalPages'] ?? json['totalPages'] ?? 1),
    );
  }
}

