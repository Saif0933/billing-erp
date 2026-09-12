import '../../../../core/models/billing_models.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}

DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  return DateTime.tryParse(val.toString()) ?? DateTime.now();
}

/// -------------------------------------------------------------
/// 1. Sales Register Models
/// -------------------------------------------------------------
class SalesRegisterSummary {
  final int totalInvoices;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalGst;
  final double totalSales;
  final double totalPaid;
  final double totalBalance;

  const SalesRegisterSummary({
    this.totalInvoices = 0,
    this.taxableAmount = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.totalGst = 0.0,
    this.totalSales = 0.0,
    this.totalPaid = 0.0,
    this.totalBalance = 0.0,
  });

  factory SalesRegisterSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SalesRegisterSummary();
    return SalesRegisterSummary(
      totalInvoices: _toInt(json['totalInvoices']),
      taxableAmount: _toDouble(json['taxableAmount']),
      cgst: _toDouble(json['cgst']),
      sgst: _toDouble(json['sgst']),
      igst: _toDouble(json['igst']),
      totalGst: _toDouble(json['totalGst']),
      totalSales: _toDouble(json['totalSales']),
      totalPaid: _toDouble(json['totalPaid']),
      totalBalance: _toDouble(json['totalBalance']),
    );
  }
}

class SalesRegisterItem {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String paymentMode;
  final String status;
  final String warehouseId;

  const SalesRegisterItem({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentMode,
    required this.status,
    required this.warehouseId,
  });

  factory SalesRegisterItem.fromJson(Map<String, dynamic> json) {
    final customerObj = json['customer'] as Map<String, dynamic>?;
    final custName = (json['customerName'] ?? customerObj?['name'] ?? 'Walk-in Customer').toString();
    final custPhone = (json['customerPhone'] ?? customerObj?['mobileNumber'] ?? '').toString();

    return SalesRegisterItem(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      invoiceDate: _parseDate(json['invoiceDate']),
      customerId: (json['customerId'] ?? customerObj?['id'] ?? '').toString(),
      customerName: custName,
      customerPhone: custPhone,
      taxableValue: _toDouble(json['taxableValue']),
      cgstAmount: _toDouble(json['cgstAmount']),
      sgstAmount: _toDouble(json['sgstAmount']),
      igstAmount: _toDouble(json['igstAmount']),
      grandTotal: _toDouble(json['grandTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      balanceAmount: _toDouble(json['balanceAmount']),
      paymentMode: (json['paymentMode'] ?? 'CASH').toString(),
      status: (json['status'] ?? 'CONFIRMED').toString(),
      warehouseId: (json['warehouseId'] ?? '').toString(),
    );
  }

  Invoice toInvoice() {
    InvoiceStatus invStatus = InvoiceStatus.confirmed;
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'DRAFT') invStatus = InvoiceStatus.draft;
    if (upperStatus == 'CANCELLED') invStatus = InvoiceStatus.cancelled;
    if (upperStatus == 'PAID') invStatus = InvoiceStatus.paid;
    if (upperStatus == 'PARTIALLY_PAID') invStatus = InvoiceStatus.partiallyPaid;

    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      customerId: customerId,
      customerName: customerName,
      billingAddress: '',
      shippingAddress: '',
      placeOfSupply: '',
      items: const [],
      taxableAmount: taxableValue,
      cgst: cgstAmount,
      sgst: sgstAmount,
      igst: igstAmount,
      cess: 0,
      roundOff: 0,
      grandTotal: grandTotal,
      balanceAmount: balanceAmount,
      paymentMode: paymentMode,
      status: invStatus,
      notes: '',
      termsConditions: '',
      warehouseId: warehouseId,
    );
  }
}

class SalesRegisterData {
  final List<SalesRegisterItem> items;
  final SalesRegisterSummary summary;
  final int total;
  final int page;
  final int totalPages;

  const SalesRegisterData({
    this.items = const [],
    this.summary = const SalesRegisterSummary(),
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  factory SalesRegisterData.fromJson(Map<String, dynamic> json) {
    final list = json['invoices'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return SalesRegisterData(
      items: list.map((e) => SalesRegisterItem.fromJson(e as Map<String, dynamic>)).toList(),
      summary: SalesRegisterSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      total: _toInt(pagination?['total'] ?? list.length),
      page: _toInt(pagination?['page'] ?? 1),
      totalPages: _toInt(pagination?['totalPages'] ?? 1),
    );
  }

  List<Invoice> get invoices => items.map((e) => e.toInvoice()).toList();
}

/// -------------------------------------------------------------
/// 2. Purchase Register Models
/// -------------------------------------------------------------
class PurchaseRegisterSummary {
  final int totalBills;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalGst;
  final double totalPurchase;

  const PurchaseRegisterSummary({
    this.totalBills = 0,
    this.taxableValue = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.totalGst = 0.0,
    this.totalPurchase = 0.0,
  });

  factory PurchaseRegisterSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PurchaseRegisterSummary();
    return PurchaseRegisterSummary(
      totalBills: _toInt(json['totalBills']),
      taxableValue: _toDouble(json['taxableValue']),
      cgst: _toDouble(json['cgst']),
      sgst: _toDouble(json['sgst']),
      igst: _toDouble(json['igst']),
      totalGst: _toDouble(json['totalGst']),
      totalPurchase: _toDouble(json['totalPurchase']),
    );
  }
}

class PurchaseRegisterItem {
  final String id;
  final String purchaseNumber;
  final String supplierInvoiceNumber;
  final DateTime purchaseDate;
  final String supplierId;
  final String supplierName;
  final String supplierMobile;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double totalAmount;
  final String paymentMode;
  final String status;
  final String warehouseId;

  const PurchaseRegisterItem({
    required this.id,
    required this.purchaseNumber,
    required this.supplierInvoiceNumber,
    required this.purchaseDate,
    required this.supplierId,
    required this.supplierName,
    required this.supplierMobile,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.status,
    required this.warehouseId,
  });

  factory PurchaseRegisterItem.fromJson(Map<String, dynamic> json) {
    final supplierObj = json['supplier'] as Map<String, dynamic>?;
    final supName = (supplierObj?['name'] ?? 'Vendor').toString();
    final supPhone = (supplierObj?['mobileNumber'] ?? '').toString();

    return PurchaseRegisterItem(
      id: (json['id'] ?? '').toString(),
      purchaseNumber: (json['purchaseNumber'] ?? json['invoiceNumber'] ?? '-').toString(),
      supplierInvoiceNumber: (json['supplierInvoiceNumber'] ?? '').toString(),
      purchaseDate: _parseDate(json['purchaseDate']),
      supplierId: (json['supplierId'] ?? supplierObj?['id'] ?? '').toString(),
      supplierName: supName,
      supplierMobile: supPhone,
      taxableValue: _toDouble(json['taxableValue']),
      cgstAmount: _toDouble(json['cgstAmount']),
      sgstAmount: _toDouble(json['sgstAmount']),
      igstAmount: _toDouble(json['igstAmount']),
      gstAmount: _toDouble(json['gstAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      paymentMode: (json['paymentMode'] ?? 'BANK').toString(),
      status: (json['status'] ?? 'CONFIRMED').toString(),
      warehouseId: (json['warehouseId'] ?? '').toString(),
    );
  }

  Purchase toPurchase() {
    PurchaseStatus pStatus = PurchaseStatus.confirmed;
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'DRAFT') pStatus = PurchaseStatus.draft;
    if (upperStatus == 'CANCELLED') pStatus = PurchaseStatus.cancelled;
    if (upperStatus == 'PAID') pStatus = PurchaseStatus.paid;
    if (upperStatus == 'PARTIALLY_PAID') pStatus = PurchaseStatus.partiallyPaid;

    return Purchase(
      id: id,
      purchaseNumber: purchaseNumber,
      supplierInvoiceNumber: supplierInvoiceNumber,
      purchaseDate: purchaseDate,
      supplierId: supplierId,
      supplierName: supplierName,
      items: const [],
      taxableAmount: taxableValue,
      cgst: cgstAmount,
      sgst: sgstAmount,
      igst: igstAmount,
      cess: 0,
      freightCharges: 0,
      otherCharges: 0,
      roundOff: 0,
      grandTotal: totalAmount,
      balanceAmount: 0,
      paymentMode: paymentMode,
      status: pStatus,
      notes: '',
      warehouseId: warehouseId,
    );
  }
}

class PurchaseRegisterData {
  final List<PurchaseRegisterItem> items;
  final PurchaseRegisterSummary summary;
  final int total;
  final int page;
  final int totalPages;

  const PurchaseRegisterData({
    this.items = const [],
    this.summary = const PurchaseRegisterSummary(),
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  factory PurchaseRegisterData.fromJson(Map<String, dynamic> json) {
    final list = json['purchases'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return PurchaseRegisterData(
      items: list.map((e) => PurchaseRegisterItem.fromJson(e as Map<String, dynamic>)).toList(),
      summary: PurchaseRegisterSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      total: _toInt(pagination?['total'] ?? list.length),
      page: _toInt(pagination?['page'] ?? 1),
      totalPages: _toInt(pagination?['totalPages'] ?? 1),
    );
  }

  List<Purchase> get purchases => items.map((e) => e.toPurchase()).toList();
}

/// -------------------------------------------------------------
/// 3. GST Liability Summary Models
/// -------------------------------------------------------------
class GstTaxSlab {
  final double rate;
  final double taxable;
  final double tax;

  const GstTaxSlab({
    this.rate = 0.0,
    this.taxable = 0.0,
    this.tax = 0.0,
  });

  factory GstTaxSlab.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GstTaxSlab();
    return GstTaxSlab(
      rate: _toDouble(json['rate']),
      taxable: _toDouble(json['taxable']),
      tax: _toDouble(json['tax']),
    );
  }
}

class GstLiabilitySummary {
  final int totalInvoices;
  final double taxableBase;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalLiability;
  final GstTaxSlab gst0;
  final GstTaxSlab gst5;
  final GstTaxSlab gst12;
  final GstTaxSlab gst18;
  final GstTaxSlab gst28;

  const GstLiabilitySummary({
    this.totalInvoices = 0,
    this.taxableBase = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.totalLiability = 0.0,
    this.gst0 = const GstTaxSlab(rate: 0),
    this.gst5 = const GstTaxSlab(rate: 5),
    this.gst12 = const GstTaxSlab(rate: 12),
    this.gst18 = const GstTaxSlab(rate: 18),
    this.gst28 = const GstTaxSlab(rate: 28),
  });

  factory GstLiabilitySummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>?;
    final slabs = json['slabs'] as Map<String, dynamic>?;

    return GstLiabilitySummary(
      totalInvoices: _toInt(summary?['totalInvoices']),
      taxableBase: _toDouble(summary?['taxableBase']),
      cgst: _toDouble(summary?['cgst']),
      sgst: _toDouble(summary?['sgst']),
      igst: _toDouble(summary?['igst']),
      totalLiability: _toDouble(summary?['totalLiability']),
      gst0: GstTaxSlab.fromJson(slabs?['gst0'] as Map<String, dynamic>?),
      gst5: GstTaxSlab.fromJson(slabs?['gst5'] as Map<String, dynamic>?),
      gst12: GstTaxSlab.fromJson(slabs?['gst12'] as Map<String, dynamic>?),
      gst18: GstTaxSlab.fromJson(slabs?['gst18'] as Map<String, dynamic>?),
      gst28: GstTaxSlab.fromJson(slabs?['gst28'] as Map<String, dynamic>?),
    );
  }
}

/// -------------------------------------------------------------
/// 4. Stock Valuation & Inventory Asset Models
/// -------------------------------------------------------------
class StockValuationSummary {
  final int totalSkus;
  final int inStockSkus;
  final double totalUnits;
  final double totalAssetValue;
  final double totalRetailValue;

  const StockValuationSummary({
    this.totalSkus = 0,
    this.inStockSkus = 0,
    this.totalUnits = 0.0,
    this.totalAssetValue = 0.0,
    this.totalRetailValue = 0.0,
  });

  factory StockValuationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StockValuationSummary();
    return StockValuationSummary(
      totalSkus: _toInt(json['totalSkus']),
      inStockSkus: _toInt(json['inStockSkus']),
      totalUnits: _toDouble(json['totalUnits']),
      totalAssetValue: _toDouble(json['totalAssetValue']),
      totalRetailValue: _toDouble(json['totalRetailValue']),
    );
  }
}

class StockValuationItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String warehouseId;
  final String warehouseName;
  final double currentStock;
  final String primaryUnit;
  final double purchasePrice;
  final double sellingPrice;
  final double assetValue;

  const StockValuationItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.warehouseId,
    required this.warehouseName,
    required this.currentStock,
    required this.primaryUnit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.assetValue,
  });

  factory StockValuationItem.fromJson(Map<String, dynamic> json) {
    return StockValuationItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '-').toString(),
      category: (json['category'] ?? 'General').toString(),
      warehouseId: (json['warehouseId'] ?? '').toString(),
      warehouseName: (json['warehouseName'] ?? 'Main Warehouse').toString(),
      currentStock: _toDouble(json['currentStock']),
      primaryUnit: (json['primaryUnit'] ?? 'PCS').toString(),
      purchasePrice: _toDouble(json['purchasePrice']),
      sellingPrice: _toDouble(json['sellingPrice']),
      assetValue: _toDouble(json['assetValue']),
    );
  }

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      code: sku,
      sku: sku,
      barcode: '',
      hsnCode: '',
      primaryUnit: primaryUnit,
      secondaryUnit: '',
      gstRate: 18.0,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: sellingPrice,
      wholesalePrice: purchasePrice,
      minStockLevel: 5,
      openingStock: currentStock,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: category,
      subCategory: '',
      brand: '',
      isActive: true,
      warehouseStocks: {if (warehouseId.isNotEmpty) warehouseId: currentStock},
    );
  }
}

class StockValuationData {
  final List<StockValuationItem> items;
  final StockValuationSummary summary;
  final int total;
  final int page;
  final int totalPages;

  const StockValuationData({
    this.items = const [],
    this.summary = const StockValuationSummary(),
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  factory StockValuationData.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return StockValuationData(
      items: list.map((e) => StockValuationItem.fromJson(e as Map<String, dynamic>)).toList(),
      summary: StockValuationSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      total: _toInt(pagination?['total'] ?? list.length),
      page: _toInt(pagination?['page'] ?? 1),
      totalPages: _toInt(pagination?['totalPages'] ?? 1),
    );
  }

  List<Product> get products => items.map((e) => e.toProduct()).toList();
}

/// -------------------------------------------------------------
/// 5. Report Export Result
/// -------------------------------------------------------------
class ReportExportResult {
  final String fileName;
  final String format;
  final int recordCount;
  final int fileSizeBytes;
  final String? csvContent;
  final String? downloadUrl;

  const ReportExportResult({
    required this.fileName,
    required this.format,
    required this.recordCount,
    required this.fileSizeBytes,
    this.csvContent,
    this.downloadUrl,
  });

  factory ReportExportResult.fromJson(Map<String, dynamic> json) {
    return ReportExportResult(
      fileName: (json['fileName'] ?? 'report_export.csv').toString(),
      format: (json['format'] ?? 'EXCEL').toString(),
      recordCount: _toInt(json['recordCount']),
      fileSizeBytes: _toInt(json['fileSizeBytes']),
      csvContent: json['csvContent']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
    );
  }
}
