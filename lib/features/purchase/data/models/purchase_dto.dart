import '../../../../core/models/billing_models.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

PurchaseStatus _parsePurchaseStatus(dynamic value) {
  final raw = (value?.toString() ?? 'draft').trim();
  final normalized = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  switch (normalized) {
    case 'confirmed':
      return PurchaseStatus.confirmed;
    case 'partiallypaid':
      return PurchaseStatus.partiallyPaid;
    case 'paid':
      return PurchaseStatus.paid;
    case 'cancelled':
    case 'canceled':
      return PurchaseStatus.cancelled;
    case 'draft':
    default:
      return PurchaseStatus.draft;
  }
}

String _statusToApi(PurchaseStatus status) {
  switch (status) {
    case PurchaseStatus.confirmed:
    case PurchaseStatus.partiallyPaid:
    case PurchaseStatus.paid:
      return 'CONFIRMED';
    case PurchaseStatus.cancelled:
      return 'CANCELLED';
    case PurchaseStatus.draft:
      return 'DRAFT';
  }
}

/// Line item DTO for purchase bill create/list/detail
class PurchaseItemDto {
  final String id;
  final String productId;
  final String name;
  final String category;
  final String subCategory;
  final String hsnCode;
  final double quantity;
  final String unit;
  final double rate;
  final double discountPercentage;
  final double discountAmount;
  final double taxableValue;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double lineTotal;

  const PurchaseItemDto({
    required this.id,
    required this.productId,
    required this.name,
    this.category = '',
    this.subCategory = '',
    this.hsnCode = '',
    required this.quantity,
    this.unit = 'PCS',
    required this.rate,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    required this.taxableValue,
    this.gstRate = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.cess = 0,
    this.lineTotal = 0,
  });

  factory PurchaseItemDto.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ??
        json['productName']?.toString() ??
        '';
    final discount = _parseDouble(
      json['discountPercentage'] ?? json['discountPercent'] ?? 0,
    );
    final gst = _parseDouble(json['gstRate'] ?? json['gstRatePercent'] ?? 0);
    final cgst = _parseDouble(json['cgst'] ?? json['cgstAmount'] ?? 0);
    final sgst = _parseDouble(json['sgst'] ?? json['sgstAmount'] ?? 0);
    final igst = _parseDouble(json['igst'] ?? json['igstAmount'] ?? 0);
    final cess = _parseDouble(json['cess'] ?? json['cessAmount'] ?? 0);
    final taxable = _parseDouble(json['taxableValue']);
    final lineTotal = _parseDouble(
      json['lineTotal'] ?? (taxable + cgst + sgst + igst + cess),
    );

    return PurchaseItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: name,
      category: json['category']?.toString() ?? '',
      subCategory: json['subCategory']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      quantity: _parseDouble(json['quantity']),
      unit: json['unit']?.toString() ?? 'PCS',
      rate: _parseDouble(json['rate']),
      discountPercentage: discount,
      discountAmount: _parseDouble(json['discountAmount']),
      taxableValue: taxable,
      gstRate: gst,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      cess: cess,
      lineTotal: lineTotal,
    );
  }

  factory PurchaseItemDto.fromDomain(PurchaseItem item) {
    return PurchaseItemDto(
      id: item.id,
      productId: item.productId,
      name: item.name,
      hsnCode: item.hsnCode,
      quantity: item.quantity,
      unit: item.unit,
      rate: item.rate,
      discountPercentage: item.discountPercentage,
      discountAmount: item.discountAmount,
      taxableValue: item.taxableValue,
      gstRate: item.gstRate,
      cgst: item.cgst,
      sgst: item.sgst,
      igst: item.igst,
      cess: item.cess,
      lineTotal: item.taxableValue + item.cgst + item.sgst + item.igst + item.cess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'productName': name,
      if (category.isNotEmpty) 'category': category,
      if (subCategory.isNotEmpty) 'subCategory': subCategory,
      if (hsnCode.isNotEmpty) 'hsnCode': hsnCode,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'discountPercent': discountPercentage,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'taxableValue': taxableValue,
      'gstRate': gstRate,
      'gstRatePercent': gstRate,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'cess': cess,
      'cgstAmount': cgst,
      'sgstAmount': sgst,
      'igstAmount': igst,
      'cessAmount': cess,
      'lineTotal': lineTotal > 0
          ? lineTotal
          : taxableValue + cgst + sgst + igst + cess,
    };
  }

  PurchaseItem toDomain() {
    return PurchaseItem(
      id: id.isNotEmpty ? id : 'pur_item_${productId}_${quantity}_$rate',
      productId: productId,
      name: name,
      hsnCode: hsnCode,
      quantity: quantity,
      unit: unit,
      rate: rate,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      taxableValue: taxableValue,
      gstRate: gstRate,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      cess: cess,
    );
  }
}

/// Purchase bill DTO matching backend purchase-bill response
class PurchaseDto {
  final String id;
  final String purchaseNumber;
  final String supplierInvoiceNumber;
  final DateTime purchaseDate;
  final String supplierId;
  final String supplierName;
  final List<PurchaseItemDto> items;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double freightCharges;
  final double otherCharges;
  final double roundOff;
  final double grandTotal;
  final double balanceAmount;
  final String paymentMode;
  final PurchaseStatus status;
  final String notes;
  final String originalPurchaseId;
  final String warehouseId;
  final bool isConfirmed;

  const PurchaseDto({
    required this.id,
    required this.purchaseNumber,
    required this.supplierInvoiceNumber,
    required this.purchaseDate,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.freightCharges,
    required this.otherCharges,
    required this.roundOff,
    required this.grandTotal,
    required this.balanceAmount,
    required this.paymentMode,
    required this.status,
    this.notes = '',
    this.originalPurchaseId = '',
    this.warehouseId = 'main',
    this.isConfirmed = false,
  });

  factory PurchaseDto.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'];
    String supplierName = json['supplierName']?.toString() ?? '';
    if (supplierName.isEmpty && supplier is Map) {
      supplierName = supplier['name']?.toString() ?? '';
    }

    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => PurchaseItemDto.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PurchaseItemDto>[];

    final paymentModeRaw = json['paymentMode']?.toString() ?? 'BANK';
    final paymentMode = paymentModeRaw.isEmpty
        ? 'Bank'
        : '${paymentModeRaw[0].toUpperCase()}${paymentModeRaw.substring(1).toLowerCase()}';

    return PurchaseDto(
      id: json['id']?.toString() ?? '',
      purchaseNumber: json['purchaseNumber']?.toString() ?? '',
      supplierInvoiceNumber: json['supplierInvoiceNumber']?.toString() ?? '',
      purchaseDate: _parseDate(json['purchaseDate']),
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: supplierName,
      items: items,
      taxableAmount: _parseDouble(json['taxableAmount'] ?? json['taxableValue']),
      cgst: _parseDouble(json['cgst'] ?? json['cgstAmount']),
      sgst: _parseDouble(json['sgst'] ?? json['sgstAmount']),
      igst: _parseDouble(json['igst'] ?? json['igstAmount']),
      cess: _parseDouble(json['cess'] ?? json['cessAmount']),
      freightCharges: _parseDouble(json['freightCharges'] ?? json['freight']),
      otherCharges: _parseDouble(json['otherCharges']),
      roundOff: _parseDouble(json['roundOff']),
      grandTotal: _parseDouble(json['grandTotal'] ?? json['totalAmount']),
      balanceAmount: _parseDouble(json['balanceAmount'] ?? json['totalAmount']),
      paymentMode: paymentMode,
      status: _parsePurchaseStatus(json['status']),
      notes: json['notes']?.toString() ?? '',
      originalPurchaseId: json['originalPurchaseId']?.toString() ?? '',
      warehouseId: json['warehouseId']?.toString() ?? 'main',
      isConfirmed: json['isConfirmed'] == true,
    );
  }

  factory PurchaseDto.fromDomain(Purchase purchase) {
    return PurchaseDto(
      id: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      supplierInvoiceNumber: purchase.supplierInvoiceNumber,
      purchaseDate: purchase.purchaseDate,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      items: purchase.items.map(PurchaseItemDto.fromDomain).toList(),
      taxableAmount: purchase.taxableAmount,
      cgst: purchase.cgst,
      sgst: purchase.sgst,
      igst: purchase.igst,
      cess: purchase.cess,
      freightCharges: purchase.freightCharges,
      otherCharges: purchase.otherCharges,
      roundOff: purchase.roundOff,
      grandTotal: purchase.grandTotal,
      balanceAmount: purchase.balanceAmount,
      paymentMode: purchase.paymentMode,
      status: purchase.status,
      notes: purchase.notes,
      originalPurchaseId: purchase.originalPurchaseId,
      warehouseId: purchase.warehouseId,
      isConfirmed: purchase.status == PurchaseStatus.confirmed ||
          purchase.status == PurchaseStatus.partiallyPaid ||
          purchase.status == PurchaseStatus.paid,
    );
  }

  /// Payload for POST /purchases
  Map<String, dynamic> toCreateJson({required PurchaseStatus saveAs}) {
    return {
      'supplierId': supplierId,
      if (purchaseNumber.isNotEmpty) 'purchaseNumber': purchaseNumber,
      'supplierInvoiceNumber': supplierInvoiceNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'freight': freightCharges,
      'freightCharges': freightCharges,
      'otherCharges': otherCharges,
      if (notes.isNotEmpty) 'notes': notes,
      'paymentMode': paymentMode,
      'status': _statusToApi(saveAs),
      if (originalPurchaseId.isNotEmpty) 'originalPurchaseId': originalPurchaseId,
      if (warehouseId.isNotEmpty) 'warehouseId': warehouseId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  Purchase toDomain() {
    return Purchase(
      id: id,
      purchaseNumber: purchaseNumber,
      supplierInvoiceNumber: supplierInvoiceNumber,
      purchaseDate: purchaseDate,
      supplierId: supplierId,
      supplierName: supplierName,
      items: items.map((e) => e.toDomain()).toList(),
      taxableAmount: taxableAmount,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      cess: cess,
      freightCharges: freightCharges,
      otherCharges: otherCharges,
      roundOff: roundOff,
      grandTotal: grandTotal,
      balanceAmount: balanceAmount,
      paymentMode: paymentMode,
      status: status,
      notes: notes,
      originalPurchaseId: originalPurchaseId,
      warehouseId: warehouseId,
    );
  }
}

class PurchaseListResponse {
  final List<Purchase> purchases;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PurchaseListResponse({
    required this.purchases,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PurchaseListResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['purchases'];
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};

    final purchases = listRaw is List
        ? listRaw
            .whereType<Map>()
            .map((e) => PurchaseDto.fromJson(Map<String, dynamic>.from(e)).toDomain())
            .toList()
        : <Purchase>[];

    return PurchaseListResponse(
      purchases: purchases,
      total: (pagination['total'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          purchases.length,
      page: (pagination['page'] as num?)?.toInt() ??
          (json['page'] as num?)?.toInt() ??
          1,
      limit: (pagination['limit'] as num?)?.toInt() ??
          (json['limit'] as num?)?.toInt() ??
          20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ??
          (json['totalPages'] as num?)?.toInt() ??
          1,
    );
  }
}

class PurchaseMetricsDto {
  final int totalBills;
  final int draftCount;
  final int confirmedCount;
  final int cancelledCount;
  final int unpaidCount;
  final int paidCount;
  final double totalPayable;
  final double totalTaxable;
  final double totalGst;

  const PurchaseMetricsDto({
    this.totalBills = 0,
    this.draftCount = 0,
    this.confirmedCount = 0,
    this.cancelledCount = 0,
    this.unpaidCount = 0,
    this.paidCount = 0,
    this.totalPayable = 0,
    this.totalTaxable = 0,
    this.totalGst = 0,
  });

  factory PurchaseMetricsDto.fromJson(Map<String, dynamic> json) {
    return PurchaseMetricsDto(
      totalBills: (json['totalBills'] as num?)?.toInt() ?? 0,
      draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
      confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
      unpaidCount: (json['unpaidCount'] as num?)?.toInt() ?? 0,
      paidCount: (json['paidCount'] as num?)?.toInt() ?? 0,
      totalPayable: _parseDouble(json['totalPayable']),
      totalTaxable: _parseDouble(json['totalTaxable']),
      totalGst: _parseDouble(json['totalGst']),
    );
  }
}

/// Product row used inside purchase bill product picker
class PurchaseProductDto {
  final String id;
  final String name;
  final String code;
  final String sku;
  final String barcode;
  final String hsnCode;
  final String primaryUnit;
  final double gstRate;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double currentStock;
  final String category;
  final String subCategory;
  final String brand;
  final bool isActive;

  const PurchaseProductDto({
    required this.id,
    required this.name,
    this.code = '',
    this.sku = '',
    this.barcode = '',
    this.hsnCode = '',
    this.primaryUnit = 'PCS',
    this.gstRate = 0,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.mrp = 0,
    this.currentStock = 0,
    this.category = 'General',
    this.subCategory = '',
    this.brand = '',
    this.isActive = true,
  });

  factory PurchaseProductDto.fromJson(Map<String, dynamic> json) {
    final gst = _parseDouble(json['gstRate'] ?? json['gstRatePercent']);
    return PurchaseProductDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['productName']?.toString() ?? '',
      code: json['code']?.toString() ?? json['itemCode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      primaryUnit: json['primaryUnit']?.toString() ??
          json['unit']?.toString() ??
          'PCS',
      gstRate: gst,
      purchasePrice: _parseDouble(json['purchasePrice'] ?? json['rate']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      mrp: _parseDouble(json['mrp']),
      currentStock: _parseDouble(json['currentStock'] ?? json['stock']),
      category: json['category']?.toString() ?? 'General',
      subCategory: json['subCategory']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      isActive: json['isActive'] != false,
    );
  }

  Product toDomain() {
    return Product(
      id: id,
      name: name,
      code: code,
      sku: sku,
      barcode: barcode,
      hsnCode: hsnCode,
      primaryUnit: primaryUnit,
      secondaryUnit: '',
      gstRate: gstRate,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: mrp > 0 ? mrp : sellingPrice,
      wholesalePrice: sellingPrice,
      minStockLevel: 0,
      openingStock: 0,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: category,
      subCategory: subCategory,
      brand: brand,
      isActive: isActive,
    );
  }
}

class PurchaseProductListResponse {
  final List<Product> products;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PurchaseProductListResponse({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PurchaseProductListResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['products'];
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};

    final products = listRaw is List
        ? listRaw
            .whereType<Map>()
            .map(
              (e) => PurchaseProductDto.fromJson(Map<String, dynamic>.from(e))
                  .toDomain(),
            )
            .toList()
        : <Product>[];

    return PurchaseProductListResponse(
      products: products,
      total: (pagination['total'] as num?)?.toInt() ?? products.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 50,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class PurchaseCategoryNode {
  final String category;
  final List<String> subCategories;

  const PurchaseCategoryNode({
    required this.category,
    this.subCategories = const [],
  });

  factory PurchaseCategoryNode.fromJson(Map<String, dynamic> json) {
    final subs = json['subCategories'];
    return PurchaseCategoryNode(
      category: json['category']?.toString() ?? 'General',
      subCategories: subs is List
          ? subs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}
