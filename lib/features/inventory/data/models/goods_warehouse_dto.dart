import '../../../../core/models/billing_models.dart';
import '../../../../core/models/warehouse_models.dart';
import 'stock_valuation_dto.dart';

class WarehouseLocationDto {
  final String id;
  final String name;
  final String code;
  final String address;
  final String contact;
  final bool isDefault;
  final bool isActive;

  const WarehouseLocationDto({
    required this.id,
    required this.name,
    this.code = '',
    this.address = '',
    this.contact = '',
    this.isDefault = false,
    this.isActive = true,
  });

  factory WarehouseLocationDto.fromJson(Map<String, dynamic> json) {
    return WarehouseLocationDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      isActive: json['isActive'] != false,
    );
  }

  Warehouse toDomain() {
    return Warehouse(
      id: id,
      name: name,
      code: code.isEmpty ? name : code,
      address: address,
      contact: contact,
      isActive: isActive,
    );
  }
}

class WarehouseProductStockDto {
  final String productId;
  final String name;
  final String itemCode;
  final String sku;
  final String primaryUnit;
  final String? warehouseId;
  final String? warehouseName;
  final double openingStock;
  final double currentStock;
  final Map<String, double> warehouseStocks;
  final double purchasePrice;
  final bool isActive;

  const WarehouseProductStockDto({
    required this.productId,
    required this.name,
    this.itemCode = '',
    this.sku = '',
    this.primaryUnit = 'PCS',
    this.warehouseId,
    this.warehouseName,
    this.openingStock = 0.0,
    this.currentStock = 0.0,
    this.warehouseStocks = const {},
    this.purchasePrice = 0.0,
    this.isActive = true,
  });

  factory WarehouseProductStockDto.fromJson(Map<String, dynamic> json) {
    final rawStocks = json['warehouseStocks'];
    final stocks = <String, double>{};
    if (rawStocks is Map) {
      rawStocks.forEach((key, value) {
        stocks[key.toString()] = parseStockNum(value);
      });
    }

    return WarehouseProductStockDto(
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      itemCode: json['itemCode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      primaryUnit: json['primaryUnit']?.toString() ?? 'PCS',
      warehouseId: json['warehouseId']?.toString(),
      warehouseName: json['warehouseName']?.toString(),
      openingStock: parseStockNum(json['openingStock']),
      currentStock: parseStockNum(json['currentStock']),
      warehouseStocks: stocks,
      purchasePrice: parseStockNum(json['purchasePrice']),
      isActive: json['isActive'] != false,
    );
  }

  Product toProduct() {
    return Product(
      id: productId,
      name: name,
      code: itemCode,
      sku: sku,
      barcode: '',
      hsnCode: '',
      primaryUnit: primaryUnit,
      secondaryUnit: '',
      gstRate: 0,
      purchasePrice: purchasePrice,
      sellingPrice: 0,
      mrp: 0,
      wholesalePrice: 0,
      minStockLevel: 0,
      openingStock: openingStock,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: '',
      brand: '',
      isActive: isActive,
      warehouseStocks: warehouseStocks,
    );
  }
}

class StockTransferItemDto {
  final String id;
  final String productId;
  final String productName;
  final double quantity;

  const StockTransferItemDto({
    this.id = '',
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  factory StockTransferItemDto.fromJson(Map<String, dynamic> json) {
    return StockTransferItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: parseStockNum(json['quantity']),
    );
  }

  TransferItem toDomain() {
    return TransferItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
    );
  }
}

class StockTransferLogDto {
  final String id;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toWarehouseId;
  final String toWarehouseName;
  final DateTime transferDate;
  final String notes;
  final String referenceNumber;
  final String status;
  final List<StockTransferItemDto> items;

  const StockTransferLogDto({
    required this.id,
    required this.fromWarehouseId,
    this.fromWarehouseName = '',
    required this.toWarehouseId,
    this.toWarehouseName = '',
    required this.transferDate,
    this.notes = '',
    this.referenceNumber = '',
    this.status = 'CONFIRMED',
    this.items = const [],
  });

  factory StockTransferLogDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return StockTransferLogDto(
      id: json['id']?.toString() ?? '',
      fromWarehouseId: json['fromWarehouseId']?.toString() ?? '',
      fromWarehouseName: json['fromWarehouseName']?.toString() ?? '',
      toWarehouseId: json['toWarehouseId']?.toString() ?? '',
      toWarehouseName: json['toWarehouseName']?.toString() ?? '',
      transferDate: parseStockDate(json['transferDate']),
      notes: json['notes']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CONFIRMED',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => StockTransferItemDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }

  StockTransfer toDomain() {
    return StockTransfer(
      id: id,
      sourceWarehouseId: fromWarehouseId,
      destinationWarehouseId: toWarehouseId,
      items: items.map((e) => e.toDomain()).toList(),
      transferDate: transferDate,
      referenceNumber: referenceNumber,
      status: StockTransferStatus.confirmed,
      notes: notes,
    );
  }
}

class WarehouseListResponseDto {
  final List<WarehouseLocationDto> items;

  const WarehouseListResponseDto({this.items = const []});

  factory WarehouseListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['warehouses'];
    return WarehouseListResponseDto(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => WarehouseLocationDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class WarehouseProductsResponseDto {
  final List<WarehouseProductStockDto> items;

  const WarehouseProductsResponseDto({this.items = const []});

  factory WarehouseProductsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return WarehouseProductsResponseDto(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => WarehouseProductStockDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class StockTransferHistoryResponseDto {
  final List<StockTransferLogDto> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const StockTransferHistoryResponseDto({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
  });

  factory StockTransferHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return StockTransferHistoryResponseDto(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => StockTransferLogDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      total: parseStockInt(pagination['total'] ?? json['total']),
      page: parseStockInt(pagination['page'] ?? json['page'] ?? 1),
      limit: parseStockInt(pagination['limit'] ?? json['limit'] ?? 50),
      totalPages: parseStockInt(
        pagination['totalPages'] ?? json['totalPages'] ?? 1,
      ),
    );
  }
}
