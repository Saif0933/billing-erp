class Warehouse {
  final String id;
  final String name;
  final String code;
  final String address;
  final String contact;
  final bool isActive;

  const Warehouse({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.contact,
    this.isActive = true,
  });

  Warehouse copyWith({
    String? name,
    String? code,
    String? address,
    String? contact,
    bool? isActive,
  }) {
    return Warehouse(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum StockTransferStatus {
  draft,
  confirmed,
  cancelled;

  String get displayName {
    switch (this) {
      case StockTransferStatus.draft:
        return 'Draft';
      case StockTransferStatus.confirmed:
        return 'Confirmed';
      case StockTransferStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class TransferItem {
  final String productId;
  final String productName;
  final double quantity;

  const TransferItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}

class StockTransfer {
  final String id;
  final String sourceWarehouseId;
  final String destinationWarehouseId;
  final List<TransferItem> items;
  final DateTime transferDate;
  final String referenceNumber;
  final StockTransferStatus status;
  final String notes;

  const StockTransfer({
    required this.id,
    required this.sourceWarehouseId,
    required this.destinationWarehouseId,
    required this.items,
    required this.transferDate,
    required this.referenceNumber,
    required this.status,
    required this.notes,
  });

  StockTransfer copyWith({
    String? sourceWarehouseId,
    String? destinationWarehouseId,
    List<TransferItem>? items,
    DateTime? transferDate,
    String? referenceNumber,
    StockTransferStatus? status,
    String? notes,
  }) {
    return StockTransfer(
      id: id,
      sourceWarehouseId: sourceWarehouseId ?? this.sourceWarehouseId,
      destinationWarehouseId: destinationWarehouseId ?? this.destinationWarehouseId,
      items: items ?? this.items,
      transferDate: transferDate ?? this.transferDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
