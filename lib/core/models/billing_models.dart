enum PartyType { customer, supplier }

enum InvoiceStatus { draft, confirmed, partiallyPaid, paid, cancelled }

enum PurchaseStatus { draft, confirmed, partiallyPaid, paid, cancelled }

class Customer {
  final String id;
  final String name;
  final String type; // e.g. Retail, Wholesale, etc.
  final String gstin;
  final String pan;
  final String mobile;
  final String email;
  final String billingAddress;
  final String shippingAddress;
  final String state;
  final String stateCode;
  final double creditLimit;
  final int creditPeriod; // in days
  final double openingBalance;
  final double currentBalance;
  final String customerGroup;
  final String notes;
  final bool isRegistered;

  const Customer({
    required this.id,
    required this.name,
    required this.type,
    required this.gstin,
    required this.pan,
    required this.mobile,
    required this.email,
    required this.billingAddress,
    required this.shippingAddress,
    required this.state,
    required this.stateCode,
    required this.creditLimit,
    required this.creditPeriod,
    required this.openingBalance,
    required this.currentBalance,
    required this.customerGroup,
    required this.notes,
    required this.isRegistered,
  });

  Customer copyWith({
    String? name,
    String? type,
    String? gstin,
    String? pan,
    String? mobile,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    String? state,
    String? stateCode,
    double? creditLimit,
    int? creditPeriod,
    double? openingBalance,
    double? currentBalance,
    String? customerGroup,
    String? notes,
    bool? isRegistered,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      creditLimit: creditLimit ?? this.creditLimit,
      creditPeriod: creditPeriod ?? this.creditPeriod,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      customerGroup: customerGroup ?? this.customerGroup,
      notes: notes ?? this.notes,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Supplier {
  final String id;
  final String name;
  final String gstin;
  final String pan;
  final String mobile;
  final String email;
  final String address;
  final String state;
  final String stateCode;
  final int creditTerms; // in days
  final double openingBalance;
  final double currentBalance;
  final String supplierGroup;
  final String notes;

  const Supplier({
    required this.id,
    required this.name,
    required this.gstin,
    required this.pan,
    required this.mobile,
    required this.email,
    required this.address,
    required this.state,
    required this.stateCode,
    required this.creditTerms,
    required this.openingBalance,
    required this.currentBalance,
    required this.supplierGroup,
    required this.notes,
  });

  Supplier copyWith({
    String? name,
    String? gstin,
    String? pan,
    String? mobile,
    String? email,
    String? address,
    String? state,
    String? stateCode,
    int? creditTerms,
    double? openingBalance,
    double? currentBalance,
    String? supplierGroup,
    String? notes,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      creditTerms: creditTerms ?? this.creditTerms,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      supplierGroup: supplierGroup ?? this.supplierGroup,
      notes: notes ?? this.notes,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String code;
  final String sku;
  final String barcode;
  final String hsnCode;
  final String primaryUnit;
  final String secondaryUnit;
  final double gstRate; // percentage, e.g. 18.0
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double wholesalePrice;
  final double minStockLevel;
  final double openingStock;
  final double currentStock;
  final String batchNumber;
  final String expiryDate;
  final String serialNumber;
  final String category;
  final String brand;
  final bool isActive;
  final Map<String, double> warehouseStocks; // Map of warehouseId -> stock

  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.sku,
    required this.barcode,
    required this.hsnCode,
    required this.primaryUnit,
    required this.secondaryUnit,
    required this.gstRate,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    required this.wholesalePrice,
    required this.minStockLevel,
    required this.openingStock,
    required this.currentStock,
    required this.batchNumber,
    required this.expiryDate,
    required this.serialNumber,
    required this.category,
    required this.brand,
    this.isActive = true,
    this.warehouseStocks = const {},
  });

  Product copyWith({
    String? name,
    String? code,
    String? sku,
    String? barcode,
    String? hsnCode,
    String? primaryUnit,
    String? secondaryUnit,
    double? gstRate,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? wholesalePrice,
    double? minStockLevel,
    double? openingStock,
    double? currentStock,
    String? batchNumber,
    String? expiryDate,
    String? serialNumber,
    String? category,
    String? brand,
    bool? isActive,
    Map<String, double>? warehouseStocks,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      hsnCode: hsnCode ?? this.hsnCode,
      primaryUnit: primaryUnit ?? this.primaryUnit,
      secondaryUnit: secondaryUnit ?? this.secondaryUnit,
      gstRate: gstRate ?? this.gstRate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      isActive: isActive ?? this.isActive,
      warehouseStocks: warehouseStocks ?? this.warehouseStocks,
    );
  }
}

class Service {
  final String id;
  final String name;
  final String code;
  final String sacCode;
  final String description;
  final double rate;
  final double gstRate; // percentage, e.g. 18.0
  final String unit;
  final double discount;
  final String incomeLedger;
  final bool isActive;

  const Service({
    required this.id,
    required this.name,
    required this.code,
    required this.sacCode,
    required this.description,
    required this.rate,
    required this.gstRate,
    required this.unit,
    required this.discount,
    required this.incomeLedger,
    this.isActive = true,
  });

  Service copyWith({
    String? name,
    String? code,
    String? sacCode,
    String? description,
    double? rate,
    double? gstRate,
    String? unit,
    double? discount,
    String? incomeLedger,
    bool? isActive,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      sacCode: sacCode ?? this.sacCode,
      description: description ?? this.description,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
      unit: unit ?? this.unit,
      discount: discount ?? this.discount,
      incomeLedger: incomeLedger ?? this.incomeLedger,
      isActive: isActive ?? this.isActive,
    );
  }
}

class InvoiceItem {
  final String id;
  final String productId; // Empty if it is a service
  final String serviceId; // Empty if it is a product
  final String name;
  final String hsnSac;
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

  const InvoiceItem({
    required this.id,
    required this.productId,
    required this.serviceId,
    required this.name,
    required this.hsnSac,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.discountPercentage,
    required this.discountAmount,
    required this.taxableValue,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
  });

  bool get isProduct => productId.isNotEmpty;
  bool get isService => serviceId.isNotEmpty;
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerId;
  final String customerName;
  final String billingAddress;
  final String shippingAddress;
  final String placeOfSupply;
  final List<InvoiceItem> items;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double roundOff;
  final double grandTotal;
  final double balanceAmount;
  final String paymentMode; // Cash, Bank, UPI, etc.
  final InvoiceStatus status;
  final String notes;
  final String termsConditions;
  final String
  originalInvoiceId; // Non-empty if this is a Credit Note (Sales Return)
  final String warehouseId;
  final bool _isCreditNote;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerId,
    required this.customerName,
    required this.billingAddress,
    required this.shippingAddress,
    required this.placeOfSupply,
    required this.items,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.roundOff,
    required this.grandTotal,
    required this.balanceAmount,
    required this.paymentMode,
    required this.status,
    required this.notes,
    required this.termsConditions,
    this.originalInvoiceId = '',
    this.warehouseId = 'main',
    bool isCreditNote = false,
  }) : _isCreditNote = isCreditNote;

  bool get isCreditNote => _isCreditNote || originalInvoiceId.isNotEmpty;

  Invoice copyWith({
    InvoiceStatus? status,
    double? balanceAmount,
    List<InvoiceItem>? items,
    double? taxableAmount,
    double? cgst,
    double? sgst,
    double? igst,
    double? cess,
    double? roundOff,
    double? grandTotal,
    String? warehouseId,
    bool? isCreditNote,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      customerId: customerId,
      customerName: customerName,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      placeOfSupply: placeOfSupply,
      items: items ?? this.items,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      cess: cess ?? this.cess,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentMode: paymentMode,
      status: status ?? this.status,
      notes: notes,
      termsConditions: termsConditions,
      originalInvoiceId: originalInvoiceId,
      warehouseId: warehouseId ?? this.warehouseId,
      isCreditNote: isCreditNote ?? this.isCreditNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PurchaseItem {
  final String id;
  final String productId;
  final String name;
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

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.hsnCode,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.discountPercentage,
    required this.discountAmount,
    required this.taxableValue,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
  });
}

class Purchase {
  final String id;
  final String purchaseNumber;
  final String supplierInvoiceNumber;
  final DateTime purchaseDate;
  final String supplierId;
  final String supplierName;
  final List<PurchaseItem> items;
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
  final String
  originalPurchaseId; // Non-empty if this is a Debit Note (Purchase Return)
  final String warehouseId;

  const Purchase({
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
    required this.notes,
    this.originalPurchaseId = '',
    this.warehouseId = 'main',
  });

  bool get isDebitNote => originalPurchaseId.isNotEmpty;

  Purchase copyWith({
    PurchaseStatus? status,
    double? balanceAmount,
    String? warehouseId,
  }) {
    return Purchase(
      id: id,
      purchaseNumber: purchaseNumber,
      supplierInvoiceNumber: supplierInvoiceNumber,
      purchaseDate: purchaseDate,
      supplierId: supplierId,
      supplierName: supplierName,
      items: items,
      taxableAmount: taxableAmount,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      cess: cess,
      freightCharges: freightCharges,
      otherCharges: otherCharges,
      roundOff: roundOff,
      grandTotal: grandTotal,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentMode: paymentMode,
      status: status ?? this.status,
      notes: notes,
      originalPurchaseId: originalPurchaseId,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }
}

class ReceiptAllocation {
  final String invoiceId;
  final double amountAllocated;

  const ReceiptAllocation({
    required this.invoiceId,
    required this.amountAllocated,
  });
}

class Receipt {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime date;
  final String paymentMode;
  final String referenceNumber;
  final String notes;
  final List<ReceiptAllocation> allocations;

  const Receipt({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.paymentMode,
    required this.referenceNumber,
    required this.notes,
    required this.allocations,
  });
}

class PaymentAllocation {
  final String purchaseId;
  final double amountAllocated;

  const PaymentAllocation({
    required this.purchaseId,
    required this.amountAllocated,
  });
}

class Payment {
  final String id;
  final String supplierId;
  final String supplierName;
  final double amount;
  final DateTime date;
  final String paymentMode;
  final String referenceNumber;
  final String notes;
  final List<PaymentAllocation> allocations;

  const Payment({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.date,
    required this.paymentMode,
    required this.referenceNumber,
    required this.notes,
    required this.allocations,
  });
}

enum LedgerTransactionType {
  sale,
  purchase,
  receipt,
  payment,
  creditNote,
  debitNote,
  openingBalance,
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String particulars;
  final double debit;
  final double credit;
  final double runningBalance;
  final String referenceNumber;
  final LedgerTransactionType type;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.particulars,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    required this.referenceNumber,
    required this.type,
  });
}

enum StockMovementType {
  openingStock,
  purchase,
  sale,
  salesReturn,
  purchaseReturn,
  adjustment,
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final double quantity; // positive for addition, negative for reduction
  final StockMovementType type;
  final DateTime date;
  final String referenceNumber;
  final String warehouseId;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.type,
    required this.date,
    required this.referenceNumber,
    this.warehouseId = 'main',
  });
}

class Expense {
  final String id;
  final String category;
  final DateTime date;
  final String vendor;
  final double amount;
  final double gst;
  final String paymentMode;
  final String attachmentPath;
  final String notes;

  const Expense({
    required this.id,
    required this.category,
    required this.date,
    required this.vendor,
    required this.amount,
    required this.gst,
    required this.paymentMode,
    required this.attachmentPath,
    required this.notes,
  });
}

enum POSSessionStatus { open, closed }

class POSSession {
  final String id;
  final double openingCash;
  final double closingCash;
  final DateTime openingTime;
  final DateTime? closingTime;
  final POSSessionStatus status;

  const POSSession({
    required this.id,
    required this.openingCash,
    required this.closingCash,
    required this.openingTime,
    this.closingTime,
    required this.status,
  });

  POSSession copyWith({
    double? closingCash,
    DateTime? closingTime,
    POSSessionStatus? status,
  }) {
    return POSSession(
      id: id,
      openingCash: openingCash,
      closingCash: closingCash ?? this.closingCash,
      openingTime: openingTime,
      closingTime: closingTime ?? this.closingTime,
      status: status ?? this.status,
    );
  }
}

class InvoiceBrandingConfig {
  final String logoUrl;
  final String primaryColor; // e.g. '#2563EB'
  final String fontName;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfsc;
  final String upiId;
  final String authorizedSignatoryName;
  final String termsConditions;
  final String footerText;

  const InvoiceBrandingConfig({
    required this.logoUrl,
    required this.primaryColor,
    required this.fontName,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankIfsc,
    required this.upiId,
    required this.authorizedSignatoryName,
    required this.termsConditions,
    required this.footerText,
  });

  InvoiceBrandingConfig copyWith({
    String? logoUrl,
    String? primaryColor,
    String? fontName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
    String? authorizedSignatoryName,
    String? termsConditions,
    String? footerText,
  }) {
    return InvoiceBrandingConfig(
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      fontName: fontName ?? this.fontName,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      upiId: upiId ?? this.upiId,
      authorizedSignatoryName:
          authorizedSignatoryName ?? this.authorizedSignatoryName,
      termsConditions: termsConditions ?? this.termsConditions,
      footerText: footerText ?? this.footerText,
    );
  }
}

class AuditLogEntry {
  final String id;
  final String user;
  final String action;
  final String entity;
  final String entityId;
  final String previousValue;
  final String newValue;
  final DateTime timestamp;

  const AuditLogEntry({
    required this.id,
    required this.user,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
  });
}
