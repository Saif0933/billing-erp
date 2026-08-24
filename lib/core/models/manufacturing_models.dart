import 'package:flutter/foundation.dart';

class BOM {
  final String id;
  final String businessId;
  final String finishedProductId;
  final String finishedProductName;
  final String version;
  final List<BOMItem> items;
  final String notes;
  final bool isActive;

  const BOM({
    required this.id,
    required this.businessId,
    required this.finishedProductId,
    required this.finishedProductName,
    required this.version,
    required this.items,
    required this.notes,
    required this.isActive,
  });

  BOM copyWith({
    String? version,
    List<BOMItem>? items,
    String? notes,
    bool? isActive,
  }) {
    return BOM(
      id: id,
      businessId: businessId,
      finishedProductId: finishedProductId,
      finishedProductName: finishedProductName,
      version: version ?? this.version,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}

class BOMItem {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double wastagePercentage;

  const BOMItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.wastagePercentage,
  });
}

enum ProductionStatus {
  draft('Draft'),
  planned('Planned'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String displayName;
  const ProductionStatus(this.displayName);
}

class ProductionOrder {
  final String id;
  final String businessId;
  final String productionNumber;
  final DateTime date;
  final String finishedProductId;
  final String finishedProductName;
  final String bomId;
  final String bomVersion;
  final double quantity;
  final String warehouseId; // Finished Goods Warehouse
  final String rawMaterialWarehouseId; // Raw Material Warehouse
  final double rawMaterialCost;
  final double laborCost;
  final double overheadCost;
  final double scrapValue;
  final double totalCost;
  final ProductionStatus status;
  final String notes;
  final List<ProductionConsumptionItem> consumedItems;
  final List<ProductionWastageItem> wastageItems;

  const ProductionOrder({
    required this.id,
    required this.businessId,
    required this.productionNumber,
    required this.date,
    required this.finishedProductId,
    required this.finishedProductName,
    required this.bomId,
    required this.bomVersion,
    required this.quantity,
    required this.warehouseId,
    required this.rawMaterialWarehouseId,
    required this.rawMaterialCost,
    required this.laborCost,
    required this.overheadCost,
    required this.scrapValue,
    required this.totalCost,
    required this.status,
    required this.notes,
    required this.consumedItems,
    required this.wastageItems,
  });

  ProductionOrder copyWith({
    ProductionStatus? status,
    double? rawMaterialCost,
    double? laborCost,
    double? overheadCost,
    double? scrapValue,
    double? totalCost,
    String? notes,
    List<ProductionConsumptionItem>? consumedItems,
    List<ProductionWastageItem>? wastageItems,
  }) {
    return ProductionOrder(
      id: id,
      businessId: businessId,
      productionNumber: productionNumber,
      date: date,
      finishedProductId: finishedProductId,
      finishedProductName: finishedProductName,
      bomId: bomId,
      bomVersion: bomVersion,
      quantity: quantity,
      warehouseId: warehouseId,
      rawMaterialWarehouseId: rawMaterialWarehouseId,
      rawMaterialCost: rawMaterialCost ?? this.rawMaterialCost,
      laborCost: laborCost ?? this.laborCost,
      overheadCost: overheadCost ?? this.overheadCost,
      scrapValue: scrapValue ?? this.scrapValue,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      consumedItems: consumedItems ?? this.consumedItems,
      wastageItems: wastageItems ?? this.wastageItems,
    );
  }
}

class ProductionConsumptionItem {
  final String productId;
  final String productName;
  final double quantityRequired;
  final double quantityConsumed;
  final String unit;

  const ProductionConsumptionItem({
    required this.productId,
    required this.productName,
    required this.quantityRequired,
    required this.quantityConsumed,
    required this.unit,
  });

  ProductionConsumptionItem copyWith({
    String? productId,
    String? productName,
    double? quantityRequired,
    double? quantityConsumed,
    String? unit,
  }) {
    return ProductionConsumptionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      quantityConsumed: quantityConsumed ?? this.quantityConsumed,
      unit: unit ?? this.unit,
    );
  }
}

class ProductionWastageItem {
  final String productId;
  final String productName;
  final double quantity;
  final String type; // 'WASTAGE' or 'SCRAP'
  final String reason;

  const ProductionWastageItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.type,
    required this.reason,
  });
}

enum JobWorkStatus {
  draft('Draft'),
  sent('Sent'),
  inProgress('In Progress'),
  partiallyReceived('Partially Received'),
  completed('Completed'),
  cancelled('Cancelled');

  final String displayName;
  const JobWorkStatus(this.displayName);
}

class JobWorkOrder {
  final String id;
  final String businessId;
  final String jobWorkerId; // Supplier/Vendor ID
  final String jobWorkerName;
  final String rawMaterialId;
  final String rawMaterialName;
  final double quantitySent;
  final DateTime dateSent;
  final String reference;
  final DateTime expectedReturnDate;
  final String finishedProductId;
  final String finishedProductName;
  final double expectedFinishedQuantity;
  final double receivedFinishedQuantity;
  final double scrapQuantity;
  final double jobWorkCharges;
  final JobWorkStatus status;

  const JobWorkOrder({
    required this.id,
    required this.businessId,
    required this.jobWorkerId,
    required this.jobWorkerName,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantitySent,
    required this.dateSent,
    required this.reference,
    required this.expectedReturnDate,
    required this.finishedProductId,
    required this.finishedProductName,
    required this.expectedFinishedQuantity,
    required this.receivedFinishedQuantity,
    required this.scrapQuantity,
    required this.jobWorkCharges,
    required this.status,
  });

  JobWorkOrder copyWith({
    double? receivedFinishedQuantity,
    double? scrapQuantity,
    JobWorkStatus? status,
  }) {
    return JobWorkOrder(
      id: id,
      businessId: businessId,
      jobWorkerId: jobWorkerId,
      jobWorkerName: jobWorkerName,
      rawMaterialId: rawMaterialId,
      rawMaterialName: rawMaterialName,
      quantitySent: quantitySent,
      dateSent: dateSent,
      reference: reference,
      expectedReturnDate: expectedReturnDate,
      finishedProductId: finishedProductId,
      finishedProductName: finishedProductName,
      expectedFinishedQuantity: expectedFinishedQuantity,
      receivedFinishedQuantity: receivedFinishedQuantity ?? this.receivedFinishedQuantity,
      scrapQuantity: scrapQuantity ?? this.scrapQuantity,
      jobWorkCharges: jobWorkCharges,
      status: status ?? this.status,
    );
  }
}
