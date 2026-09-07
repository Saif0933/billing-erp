import '../../../../core/models/billing_models.dart';

/// POS Product DTO with live stock & barcode
class PosProductDto {
  final String id;
  final String name;
  final String code;
  final String? sku;
  final String? barcode;
  final String? hsnCode;
  final String primaryUnit;
  final double sellingPrice;
  final double mrp;
  final double currentStock;
  final double gstRate;
  final String category;
  final String? brand;
  final bool isLowStock;

  const PosProductDto({
    required this.id,
    required this.name,
    required this.code,
    this.sku,
    this.barcode,
    this.hsnCode,
    required this.primaryUnit,
    required this.sellingPrice,
    required this.mrp,
    required this.currentStock,
    required this.gstRate,
    required this.category,
    this.brand,
    this.isLowStock = false,
  });

  factory PosProductDto.fromJson(Map<String, dynamic> json) {
    return PosProductDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      code: json['code']?.toString() ?? json['id']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      hsnCode: json['hsnCode']?.toString(),
      primaryUnit: json['primaryUnit']?.toString() ?? 'PCS',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ??
          (json['sellingPrice'] as num?)?.toDouble() ??
          0.0,
      currentStock: (json['currentStock'] as num?)?.toDouble() ??
          (json['stock'] as num?)?.toDouble() ??
          0.0,
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'General',
      brand: json['brand']?.toString(),
      isLowStock: json['isLowStock'] == true,
    );
  }

  Product toDomain() {
    return Product(
      id: id,
      name: name,
      code: code,
      sku: sku ?? code,
      barcode: barcode ?? '',
      hsnCode: hsnCode ?? '',
      primaryUnit: primaryUnit,
      secondaryUnit: '',
      gstRate: gstRate,
      purchasePrice: 0.0,
      sellingPrice: sellingPrice,
      mrp: mrp,
      wholesalePrice: sellingPrice,
      minStockLevel: 5.0,
      openingStock: currentStock,
      currentStock: currentStock,
      batchNumber: '',
      expiryDate: '',
      serialNumber: '',
      category: category,
      brand: brand ?? '',
      warehouseStocks: {'main': currentStock},
    );
  }
}

/// POS Session DTO for register management
class PosSessionDto {
  final String id;
  final double openingCash;
  final double closingCash;
  final DateTime openingTime;
  final DateTime? closingTime;
  final String status;
  final String? registerNumber;
  final String? counterName;
  final String? notes;

  const PosSessionDto({
    required this.id,
    required this.openingCash,
    required this.closingCash,
    required this.openingTime,
    this.closingTime,
    required this.status,
    this.registerNumber,
    this.counterName,
    this.notes,
  });

  factory PosSessionDto.fromJson(Map<String, dynamic> json) {
    return PosSessionDto(
      id: json['id']?.toString() ?? '',
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0.0,
      closingCash: (json['closingCash'] as num?)?.toDouble() ?? 0.0,
      openingTime: json['openingTime'] != null
          ? DateTime.tryParse(json['openingTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closingTime: json['closingTime'] != null
          ? DateTime.tryParse(json['closingTime'].toString())
          : null,
      status: json['status']?.toString().toLowerCase() ?? 'open',
      registerNumber: json['registerNumber']?.toString(),
      counterName: json['counterName']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  POSSession toDomain() {
    return POSSession(
      id: id,
      openingCash: openingCash,
      closingCash: closingCash,
      openingTime: openingTime,
      closingTime: closingTime,
      status: status == 'closed'
          ? POSSessionStatus.closed
          : POSSessionStatus.open,
    );
  }
}

/// POS Thermal Receipt structure matching 80mm ESC/POS printer payload
class PosThermalReceiptDto {
  final String rawText;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final double grandTotal;
  final String paymentMode;
  final Map<String, dynamic>? business;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? taxSummary;
  final String footer;

  const PosThermalReceiptDto({
    required this.rawText,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.grandTotal,
    required this.paymentMode,
    this.business,
    this.items = const [],
    this.taxSummary,
    this.footer = 'Thank you for shopping with us!',
  });

  factory PosThermalReceiptDto.fromJson(Map<String, dynamic> json) {
    return PosThermalReceiptDto(
      rawText: json['rawText']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'Cash',
      business: json['business'] as Map<String, dynamic>?,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => i as Map<String, dynamic>)
              .toList() ??
          const [],
      taxSummary: json['taxSummary'] as Map<String, dynamic>?,
      footer: json['footer']?.toString() ?? 'Thank you for shopping with us!',
    );
  }
}

/// POS Fast Billing Checkout Response
class PosCheckoutResponse {
  final Invoice invoice;
  final PosThermalReceiptDto? thermalReceipt;
  final String message;

  const PosCheckoutResponse({
    required this.invoice,
    this.thermalReceipt,
    this.message = 'Checkout completed successfully',
  });

  factory PosCheckoutResponse.fromJson(Map<String, dynamic> json) {
    final invoiceData = json['invoice'] as Map<String, dynamic>? ?? json;

    final itemsRaw = invoiceData['items'] as List<dynamic>? ?? [];
    final items = itemsRaw.map((item) {
      final m = item as Map<String, dynamic>;
      final rate = (m['rate'] as num?)?.toDouble() ?? 0.0;
      final qty = (m['quantity'] as num?)?.toDouble() ?? 1.0;
      final gstRate = (m['gstRatePercent'] as num?)?.toDouble() ??
          (m['gstRate'] as num?)?.toDouble() ??
          0.0;
      final taxable = (m['taxableValue'] as num?)?.toDouble() ?? (rate * qty);

      return InvoiceItem(
        id: m['id']?.toString() ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
        productId: m['productId']?.toString() ?? '',
        serviceId: m['serviceId']?.toString() ?? '',
        name: m['product']?['name']?.toString() ??
            m['name']?.toString() ??
            'Item',
        hsnSac: m['hsnOrSacCode']?.toString() ?? m['hsnSac']?.toString() ?? '',
        quantity: qty,
        unit: m['unit']?.toString() ?? 'PCS',
        rate: rate,
        discountPercentage:
            (m['discountPercent'] as num?)?.toDouble() ??
            (m['discountPercentage'] as num?)?.toDouble() ??
            0.0,
        discountAmount: (m['discountAmount'] as num?)?.toDouble() ?? 0.0,
        taxableValue: taxable,
        gstRate: gstRate,
        cgst: (m['cgstAmount'] as num?)?.toDouble() ??
            (m['cgst'] as num?)?.toDouble() ??
            0.0,
        sgst: (m['sgstAmount'] as num?)?.toDouble() ??
            (m['sgst'] as num?)?.toDouble() ??
            0.0,
        igst: (m['igstAmount'] as num?)?.toDouble() ??
            (m['igst'] as num?)?.toDouble() ??
            0.0,
        cess: (m['cessAmount'] as num?)?.toDouble() ??
            (m['cess'] as num?)?.toDouble() ??
            0.0,
      );
    }).toList();

    final invoice = Invoice(
      id: invoiceData['id']?.toString() ?? 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: invoiceData['invoiceNumber']?.toString() ?? 'INV-POS',
      invoiceDate: invoiceData['createdAt'] != null
          ? DateTime.tryParse(invoiceData['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customerId: invoiceData['customerId']?.toString() ?? '',
      customerName: invoiceData['customer']?['name']?.toString() ??
          invoiceData['customerName']?.toString() ??
          'Walk-in Customer',
      billingAddress: invoiceData['billingAddress']?.toString() ?? '',
      shippingAddress: invoiceData['shippingAddress']?.toString() ?? '',
      placeOfSupply: invoiceData['placeOfSupply']?.toString() ?? '',
      items: items,
      taxableAmount: (invoiceData['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgst: (invoiceData['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgst: (invoiceData['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igst: (invoiceData['igstAmount'] as num?)?.toDouble() ?? 0.0,
      cess: (invoiceData['cessAmount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (invoiceData['roundOff'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (invoiceData['grandTotal'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: invoiceData['paymentMode'] == 'CREDIT'
          ? (invoiceData['grandTotal'] as num?)?.toDouble() ?? 0.0
          : 0.0,
      paymentMode: invoiceData['paymentMode']?.toString() ?? 'Cash',
      status: InvoiceStatus.confirmed,
      notes: invoiceData['notes']?.toString() ?? 'POS Fast Billing Sale',
      termsConditions: invoiceData['termsAndConditions']?.toString() ??
          'Goods once sold are not returnable.',
      warehouseId: invoiceData['warehouseId']?.toString() ?? 'main',
    );

    PosThermalReceiptDto? receipt;
    if (json['thermalReceipt'] != null) {
      receipt = PosThermalReceiptDto.fromJson(
        json['thermalReceipt'] as Map<String, dynamic>,
      );
    }

    return PosCheckoutResponse(
      invoice: invoice,
      thermalReceipt: receipt,
      message: json['message']?.toString() ?? 'Sale completed successfully',
    );
  }
}

/// POS Terminal Dashboard Summary
class PosDashboardSummaryDto {
  final double todaySales;
  final int todayBills;
  final double cashSales;
  final double upiSales;
  final double cardSales;
  final double creditSales;
  final int heldCartCount;

  const PosDashboardSummaryDto({
    this.todaySales = 0.0,
    this.todayBills = 0,
    this.cashSales = 0.0,
    this.upiSales = 0.0,
    this.cardSales = 0.0,
    this.creditSales = 0.0,
    this.heldCartCount = 0,
  });

  factory PosDashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return PosDashboardSummaryDto(
      todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0.0,
      todayBills: (json['todayBills'] as num?)?.toInt() ?? 0,
      cashSales: (json['cashSales'] as num?)?.toDouble() ?? 0.0,
      upiSales: (json['upiSales'] as num?)?.toDouble() ?? 0.0,
      cardSales: (json['cardSales'] as num?)?.toDouble() ?? 0.0,
      creditSales: (json['creditSales'] as num?)?.toDouble() ?? 0.0,
      heldCartCount: (json['heldCartCount'] as num?)?.toInt() ?? 0,
    );
  }
}
