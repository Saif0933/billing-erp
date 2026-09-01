import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/models/warehouse_models.dart';
import '../../../../core/models/recurring_billing_models.dart';
import '../../../../core/services/gst_calculation_service.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/models/accounting_models.dart';
import '../../../../core/models/manufacturing_models.dart';
import '../../../notifications/data/models/notification_model.dart';

class BillingState {
  final List<Customer> customers;
  final List<Supplier> suppliers;
  final List<Product> products;
  final List<Service> services;
  final List<Invoice> invoices;
  final List<Purchase> purchases;
  final List<Receipt> receipts;
  final List<Payment> payments;
  final List<Expense> expenses;
  final List<StockMovement> stockMovements;
  final List<LedgerEntry> ledgerEntries;
  final List<Warehouse> warehouses;
  final List<StockTransfer> stockTransfers;
  final List<RecurringSchedule> recurringSchedules;
  final List<AuditLogEntry> auditLogs;
  final POSSession? activePOSSession;
  final List<Invoice> heldPOSCarts;
  final InvoiceBrandingConfig invoiceBrandingConfig;
  final List<Map<String, dynamic>> customUsers;

  // Phase 3 Accounting & Manufacturing lists
  final List<Account> accounts;
  final List<JournalEntry> journalEntries;
  final List<BankAccount> bankAccounts;
  final List<AccountingPeriod> accountingPeriods;
  final List<BOM> boms;
  final List<ProductionOrder> productionOrders;
  final List<JobWorkOrder> jobWorkOrders;
  final List<NotificationModel> notifications;

  const BillingState({
    required this.customers,
    required this.suppliers,
    required this.products,
    required this.services,
    required this.invoices,
    required this.purchases,
    required this.receipts,
    required this.payments,
    required this.expenses,
    required this.stockMovements,
    required this.ledgerEntries,
    required this.warehouses,
    required this.stockTransfers,
    required this.recurringSchedules,
    required this.auditLogs,
    this.activePOSSession,
    required this.heldPOSCarts,
    required this.invoiceBrandingConfig,
    required this.customUsers,
    required this.accounts,
    required this.journalEntries,
    required this.bankAccounts,
    required this.accountingPeriods,
    required this.boms,
    required this.productionOrders,
    required this.jobWorkOrders,
    required this.notifications,
  });

  BillingState copyWith({
    List<Customer>? customers,
    List<Supplier>? suppliers,
    List<Product>? products,
    List<Service>? services,
    List<Invoice>? invoices,
    List<Purchase>? purchases,
    List<Receipt>? receipts,
    List<Payment>? payments,
    List<Expense>? expenses,
    List<StockMovement>? stockMovements,
    List<LedgerEntry>? ledgerEntries,
    List<Warehouse>? warehouses,
    List<StockTransfer>? stockTransfers,
    List<RecurringSchedule>? recurringSchedules,
    List<AuditLogEntry>? auditLogs,
    POSSession? Function()? activePOSSession,
    List<Invoice>? heldPOSCarts,
    InvoiceBrandingConfig? invoiceBrandingConfig,
    List<Map<String, dynamic>>? customUsers,
    List<Account>? accounts,
    List<JournalEntry>? journalEntries,
    List<BankAccount>? bankAccounts,
    List<AccountingPeriod>? accountingPeriods,
    List<BOM>? boms,
    List<ProductionOrder>? productionOrders,
    List<JobWorkOrder>? jobWorkOrders,
    List<NotificationModel>? notifications,
  }) {
    return BillingState(
      customers: customers ?? this.customers,
      suppliers: suppliers ?? this.suppliers,
      products: products ?? this.products,
      services: services ?? this.services,
      invoices: invoices ?? this.invoices,
      purchases: purchases ?? this.purchases,
      receipts: receipts ?? this.receipts,
      payments: payments ?? this.payments,
      expenses: expenses ?? this.expenses,
      stockMovements: stockMovements ?? this.stockMovements,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      warehouses: warehouses ?? this.warehouses,
      stockTransfers: stockTransfers ?? this.stockTransfers,
      recurringSchedules: recurringSchedules ?? this.recurringSchedules,
      auditLogs: auditLogs ?? this.auditLogs,
      activePOSSession: activePOSSession != null ? activePOSSession() : this.activePOSSession,
      heldPOSCarts: heldPOSCarts ?? this.heldPOSCarts,
      invoiceBrandingConfig: invoiceBrandingConfig ?? this.invoiceBrandingConfig,
      customUsers: customUsers ?? this.customUsers,
      accounts: accounts ?? this.accounts,
      journalEntries: journalEntries ?? this.journalEntries,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      accountingPeriods: accountingPeriods ?? this.accountingPeriods,
      boms: boms ?? this.boms,
      productionOrders: productionOrders ?? this.productionOrders,
      jobWorkOrders: jobWorkOrders ?? this.jobWorkOrders,
      notifications: notifications ?? this.notifications,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final Ref _ref;

  BillingNotifier(this._ref)
      : super(
          const BillingState(
            customers: [],
            suppliers: [],
            products: [],
            services: [],
            invoices: [],
            purchases: [],
            receipts: [],
            payments: [],
            expenses: [],
            stockMovements: [],
            ledgerEntries: [],
            warehouses: [],
            stockTransfers: [],
            recurringSchedules: [],
            auditLogs: [],
            heldPOSCarts: [],
            invoiceBrandingConfig: InvoiceBrandingConfig(
              logoUrl: '',
              primaryColor: '#2563EB',
              fontName: 'Inter',
              bankName: 'Bunny Central Bank',
              bankAccountNumber: '1234567890',
              bankIfsc: 'BCB0001234',
              upiId: 'taxbunny@upi',
              authorizedSignatoryName: 'Rahul Sharma',
              termsConditions: '1. Goods once sold will not be taken back.\n2. Interest @ 18% will be charged if payment is not made within credit period.',
              footerText: 'Thank you for choosing Bunny Farms!',
            ),
            customUsers: [],
            accounts: [],
            journalEntries: [],
            bankAccounts: [],
            accountingPeriods: [],
            boms: [],
            productionOrders: [],
            jobWorkOrders: [],
            notifications: [],
          ),
        ) {
    _loadInitialMockData();
  }

  String get _businessId {
    try {
      return _ref.read(businessProvider).activeBusiness?.id ?? 'biz_01';
    } catch (_) {
      return 'biz_01';
    }
  }

  String get _businessStateCode {
    try {
      return _ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
    } catch (_) {
      return '27';
    }
  }

  // --- Initial Mock Data ---
  void _loadInitialMockData() {
    // Pre-populate with realistic starting data
    final customers = [
      const Customer(
        id: 'cust_01',
        name: 'Acme Corporates',
        type: 'Wholesale',
        gstin: '27AADCA1234F1Z5',
        pan: 'AADCA1234F',
        mobile: '9876543210',
        email: 'billing@acme.com',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        state: 'Maharashtra',
        stateCode: '27',
        creditLimit: 100000.0,
        creditPeriod: 30,
        openingBalance: 20000.0,
        currentBalance: 20000.0,
        customerGroup: 'Corporate',
        notes: 'VIP customer',
        isRegistered: true,
      ),
      const Customer(
        id: 'cust_02',
        name: 'Rahul Sharma (Retail)',
        type: 'Retail',
        gstin: '',
        pan: '',
        mobile: '9123456789',
        email: 'rahul@gmail.com',
        billingAddress: '42, Park Street, Pune',
        shippingAddress: '42, Park Street, Pune',
        state: 'Maharashtra',
        stateCode: '27',
        creditLimit: 0.0,
        creditPeriod: 0,
        openingBalance: 0.0,
        currentBalance: 0.0,
        customerGroup: 'Retailer',
        notes: '',
        isRegistered: false,
      ),
      const Customer(
        id: 'cust_03',
        name: 'Karnataka Enterprises',
        type: 'Wholesale',
        gstin: '29BBBBB1234A1Z0',
        pan: 'BBBBB1234A',
        mobile: '8899889988',
        email: 'info@karnatakaent.com',
        billingAddress: 'Brigade Road, Bangalore',
        shippingAddress: 'Brigade Road, Bangalore',
        state: 'Karnataka',
        stateCode: '29',
        creditLimit: 150000.0,
        creditPeriod: 45,
        openingBalance: 12500.0,
        currentBalance: 12500.0,
        customerGroup: 'Out of State',
        notes: 'Interstate customer',
        isRegistered: true,
      ),
    ];

    final suppliers = [
      const Supplier(
        id: 'supp_01',
        name: 'Apex Raw Materials Ltd',
        gstin: '27APEXM1234F1Z8',
        pan: 'APEXM1234F',
        mobile: '9988776655',
        email: 'supply@apex.com',
        address: '505, MIDC Thane, Mumbai',
        state: 'Maharashtra',
        stateCode: '27',
        creditTerms: 60,
        openingBalance: 50000.0,
        currentBalance: 50000.0,
        supplierGroup: 'Raw Materials',
        notes: 'Primary raw materials vendor',
      ),
      const Supplier(
        id: 'supp_02',
        name: 'Gujarat Tech Packers',
        gstin: '24GTECH5678R1Z1',
        pan: 'GTECH5678R',
        mobile: '9001002003',
        email: 'sales@gtechpack.com',
        address: 'GIDC, Vadodara',
        state: 'Gujarat',
        stateCode: '24',
        creditTerms: 30,
        openingBalance: 15800.0,
        currentBalance: 15800.0,
        supplierGroup: 'Packaging',
        notes: 'Interstate packaging supplier',
      ),
    ];

    final products = [
      const Product(
        id: 'prod_01',
        name: 'Organic Wheat Flour (5kg)',
        code: 'WHT5K',
        sku: 'WHT-005',
        barcode: '8901234567890',
        hsnCode: '1101',
        primaryUnit: 'Bag',
        secondaryUnit: 'Kg',
        gstRate: 5.0,
        purchasePrice: 180.0,
        sellingPrice: 220.0,
        mrp: 250.0,
        wholesalePrice: 200.0,
        minStockLevel: 20.0,
        openingStock: 100.0,
        currentStock: 100.0,
        batchNumber: 'B-WHT-01',
        expiryDate: '2027-02-28',
        serialNumber: '',
        category: 'Grocery',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 100.0, 'store': 0.0},
      ),
      const Product(
        id: 'prod_02',
        name: 'Premium Basmati Rice (10kg)',
        code: 'RCE10K',
        sku: 'RCE-010',
        barcode: '8901234567891',
        hsnCode: '1006',
        primaryUnit: 'Bag',
        secondaryUnit: 'Kg',
        gstRate: 5.0,
        purchasePrice: 650.0,
        sellingPrice: 850.0,
        mrp: 999.0,
        wholesalePrice: 780.0,
        minStockLevel: 10.0,
        openingStock: 50.0,
        currentStock: 50.0,
        batchNumber: 'B-RCE-05',
        expiryDate: '2028-06-30',
        serialNumber: '',
        category: 'Grocery',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 50.0, 'store': 0.0},
      ),
      const Product(
        id: 'prod_03',
        name: 'Refined Sunflower Oil (1L)',
        code: 'OIL1L',
        sku: 'OIL-001',
        barcode: '8901234567892',
        hsnCode: '1512',
        primaryUnit: 'Bottle',
        secondaryUnit: 'Litre',
        gstRate: 12.0,
        purchasePrice: 110.0,
        sellingPrice: 150.0,
        mrp: 180.0,
        wholesalePrice: 135.0,
        minStockLevel: 50.0,
        openingStock: 150.0,
        currentStock: 15.0, // Pre-trigger low stock (15 <= 50)
        batchNumber: 'B-OIL-12',
        expiryDate: '2027-01-15',
        serialNumber: '',
        category: 'Edible Oils',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 15.0, 'store': 0.0},
      ),
      const Product(
        id: 'prod_raw_01',
        name: 'Wheat Grain (Raw)',
        code: 'WHTRAW',
        sku: 'WHT-RAW-01',
        barcode: '8901234567893',
        hsnCode: '1001',
        primaryUnit: 'Kg',
        secondaryUnit: 'Gram',
        gstRate: 0.0,
        purchasePrice: 30.0,
        sellingPrice: 0.0,
        mrp: 35.0,
        wholesalePrice: 0.0,
        minStockLevel: 100.0,
        openingStock: 500.0,
        currentStock: 500.0,
        batchNumber: 'B-RAW-WHT',
        expiryDate: '2028-12-31',
        serialNumber: '',
        category: 'Raw Materials',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 500.0, 'store': 0.0},
      ),
      const Product(
        id: 'prod_raw_02',
        name: 'Baking Yeast Additives',
        code: 'YSTADD',
        sku: 'YST-ADD-01',
        barcode: '8901234567894',
        hsnCode: '2102',
        primaryUnit: 'Kg',
        secondaryUnit: 'Gram',
        gstRate: 18.0,
        purchasePrice: 80.0,
        sellingPrice: 0.0,
        mrp: 100.0,
        wholesalePrice: 0.0,
        minStockLevel: 10.0,
        openingStock: 100.0,
        currentStock: 100.0,
        batchNumber: 'B-RAW-YST',
        expiryDate: '2027-09-30',
        serialNumber: '',
        category: 'Raw Materials',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 100.0, 'store': 0.0},
      ),
      const Product(
        id: 'prod_finished_01',
        name: 'Premium Farm Bread (400g)',
        code: 'BRDFRM',
        sku: 'BRD-FRM-01',
        barcode: '8901234567895',
        hsnCode: '1905',
        primaryUnit: 'Loaf',
        secondaryUnit: 'Piece',
        gstRate: 5.0,
        purchasePrice: 0.0,
        sellingPrice: 45.0,
        mrp: 50.0,
        wholesalePrice: 40.0,
        minStockLevel: 25.0,
        openingStock: 50.0,
        currentStock: 50.0,
        batchNumber: 'B-BRD-FRM',
        expiryDate: '2026-10-15',
        serialNumber: '',
        category: 'Bakery',
        brand: 'Bunny Farms',
        warehouseStocks: {'main': 50.0, 'store': 0.0},
      ),
    ];

    final services = [
      const Service(
        id: 'serv_01',
        name: 'Home Delivery Logistics',
        code: 'SERV-DLV',
        sacCode: '9965',
        description: 'Doorstep shipping and delivery services',
        rate: 150.0,
        gstRate: 18.0,
        unit: 'Trip',
        discount: 0.0,
        incomeLedger: 'Delivery Income',
      ),
      const Service(
        id: 'serv_02',
        name: 'Consultancy Service',
        code: 'SERV-CNS',
        sacCode: '9983',
        description: 'Business process advisory services',
        rate: 5000.0,
        gstRate: 18.0,
        unit: 'Hour',
        discount: 10.0,
        incomeLedger: 'Consulting Income',
      ),
    ];

    final expenses = [
      Expense(
        id: 'exp_01',
        category: 'Rent',
        date: DateTime.now().subtract(const Duration(days: 5)),
        vendor: 'Apex Properties',
        amount: 25000.0,
        gst: 4500.0,
        paymentMode: 'Bank',
        attachmentPath: '',
        notes: 'Office monthly rent',
      ),
      Expense(
        id: 'exp_02',
        category: 'Office Expenses',
        date: DateTime.now().subtract(const Duration(days: 2)),
        vendor: 'Stationery Zone',
        amount: 1500.0,
        gst: 270.0,
        paymentMode: 'Cash',
        attachmentPath: '',
        notes: 'Notebooks and printer paper',
      ),
    ];

    // Seed stock movement logs for opening stock
    final List<StockMovement> stockMovements = [];
    for (var p in products) {
      if (p.openingStock > 0) {
        stockMovements.add(
          StockMovement(
            id: 'sm_init_${p.id}',
            productId: p.id,
            productName: p.name,
            quantity: p.openingStock,
            type: StockMovementType.openingStock,
            date: DateTime(2026, 4, 1),
            referenceNumber: 'INITIAL-STOCK',
          ),
        );
      }
    }

    // Seed opening balance ledger entries
    final List<LedgerEntry> ledgerEntries = [];
    for (var c in customers) {
      if (c.openingBalance > 0) {
        ledgerEntries.add(
          LedgerEntry(
            id: 'led_init_${c.id}',
            date: DateTime(2026, 4, 1),
            particulars: 'Opening Balance for Customer: ${c.name}',
            debit: c.openingBalance,
            credit: 0.0,
            runningBalance: c.openingBalance,
            referenceNumber: 'OP-BAL',
            type: LedgerTransactionType.openingBalance,
          ),
        );
      }
    }
    for (var s in suppliers) {
      if (s.openingBalance > 0) {
        ledgerEntries.add(
          LedgerEntry(
            id: 'led_init_${s.id}',
            date: DateTime(2026, 4, 1),
            particulars: 'Opening Balance for Supplier: ${s.name}',
            debit: 0.0,
            credit: s.openingBalance,
            runningBalance: -s.openingBalance,
            referenceNumber: 'OP-BAL',
            type: LedgerTransactionType.openingBalance,
          ),
        );
      }
    }

    final initialInvoices = [
      Invoice(
        id: 'inv_01',
        invoiceNumber: 'TB/26-27/0001',
        invoiceDate: DateTime(2026, 4, 10),
        customerId: 'cust_01',
        customerName: 'Acme Corporates',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        placeOfSupply: 'Maharashtra',
        items: const [
          InvoiceItem(
            id: 'item_01_1',
            productId: 'prod_01',
            serviceId: '',
            name: 'Organic Wheat Flour (5kg)',
            hsnSac: '1101',
            quantity: 20.0,
            unit: 'Bag',
            rate: 220.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 4400.0,
            gstRate: 5.0,
            cgst: 110.0,
            sgst: 110.0,
            igst: 0.0,
            cess: 0.0,
          ),
          InvoiceItem(
            id: 'item_01_2',
            productId: 'prod_02',
            serviceId: '',
            name: 'Basmati Rice Premium (1kg)',
            hsnSac: '1006',
            quantity: 15.0,
            unit: 'Packet',
            rate: 110.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 1650.0,
            gstRate: 5.0,
            cgst: 41.25,
            sgst: 41.25,
            igst: 0.0,
            cess: 0.0,
          ),
        ],
        taxableAmount: 6050.0,
        cgst: 151.25,
        sgst: 151.25,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.5,
        grandTotal: 6353.0,
        balanceAmount: 0.0,
        paymentMode: 'Bank',
        status: InvoiceStatus.paid,
        notes: 'Monthly corporate office pantry supplies',
        termsConditions: 'Net 30 terms.',
        originalInvoiceId: '',
        warehouseId: 'main',
      ),
      Invoice(
        id: 'inv_02',
        invoiceNumber: 'TB/26-27/0002',
        invoiceDate: DateTime(2026, 4, 15),
        customerId: 'cust_02',
        customerName: 'Rahul Sharma (Retail)',
        billingAddress: '42, Park Street, Pune',
        shippingAddress: '42, Park Street, Pune',
        placeOfSupply: 'Maharashtra',
        items: const [
          InvoiceItem(
            id: 'item_02_1',
            productId: 'prod_03',
            serviceId: '',
            name: 'Cold Pressed Sunflower Oil (1L)',
            hsnSac: '1512',
            quantity: 5.0,
            unit: 'Bottle',
            rate: 180.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 900.0,
            gstRate: 5.0,
            cgst: 22.5,
            sgst: 22.5,
            igst: 0.0,
            cess: 0.0,
          ),
        ],
        taxableAmount: 900.0,
        cgst: 22.5,
        sgst: 22.5,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 945.0,
        balanceAmount: 945.0,
        paymentMode: 'Cash',
        status: InvoiceStatus.confirmed,
        notes: 'Counter retail sale',
        termsConditions: 'Goods once sold will not be taken back without receipt.',
        originalInvoiceId: '',
        warehouseId: 'main',
      ),
      Invoice(
        id: 'ret_01',
        invoiceNumber: 'CN/26-27/0001',
        invoiceDate: DateTime(2026, 4, 18),
        customerId: 'cust_01',
        customerName: 'Acme Corporates',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        placeOfSupply: 'Maharashtra',
        items: const [
          InvoiceItem(
            id: 'ret_item_01_1',
            productId: 'prod_01',
            serviceId: '',
            name: 'Organic Wheat Flour (5kg)',
            hsnSac: '1101',
            quantity: 2.0,
            unit: 'Bag',
            rate: 220.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 440.0,
            gstRate: 5.0,
            cgst: 11.0,
            sgst: 11.0,
            igst: 0.0,
            cess: 0.0,
          ),
        ],
        taxableAmount: 440.0,
        cgst: 11.0,
        sgst: 11.0,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 462.0,
        balanceAmount: 0.0,
        paymentMode: 'Credit Note (Store Credit)',
        status: InvoiceStatus.confirmed,
        notes: '2 bags returned due to outer packaging tear during shipping (Reason: Defective / Damaged Goods)',
        termsConditions: 'Credit note issued for returned goods.',
        originalInvoiceId: 'TB/26-27/0001',
        warehouseId: 'main',
      ),
    ];

    state = BillingState(
      customers: customers,
      suppliers: suppliers,
      products: products,
      services: services,
      invoices: initialInvoices,
      purchases: [],
      receipts: [],
      payments: [],
      expenses: expenses,
      stockMovements: stockMovements,
      ledgerEntries: ledgerEntries,
      warehouses: [
        const Warehouse(
          id: 'main',
          name: 'Main Warehouse',
          code: 'M-WH',
          address: '101, Industrial Area, Mumbai',
          contact: '9876543210',
          isActive: true,
        ),
        const Warehouse(
          id: 'store',
          name: 'Retail Store Godown',
          code: 'R-ST',
          address: '42, Park Street, Pune',
          contact: '9123456789',
          isActive: true,
        ),
      ],
      stockTransfers: [],
      recurringSchedules: [
        RecurringSchedule(
          id: 'rec_01',
          customerId: 'cust_01',
          customerName: 'Acme Corporates',
          items: [
            const InvoiceItem(
              id: 'item_rec_01',
              productId: 'prod_01',
              serviceId: '',
              name: 'Organic Wheat Flour (5kg)',
              hsnSac: '1101',
              quantity: 10.0,
              unit: 'Bag',
              rate: 220.0,
              discountPercentage: 0.0,
              discountAmount: 0.0,
              taxableValue: 2200.0,
              gstRate: 5.0,
              cgst: 55.0,
              sgst: 55.0,
              igst: 0.0,
              cess: 0.0,
            ),
          ],
          frequency: RecurringFrequency.monthly,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 365)),
          nextBillingDate: DateTime.now().add(const Duration(days: 1)),
          status: RecurringScheduleStatus.active,
          paymentTerms: 'Net 30',
          notes: 'Standard monthly supply of organic wheat flour.',
        ),
      ],
      auditLogs: [
        AuditLogEntry(
          id: 'aud_init',
          user: 'owner@taxbunny.com',
          action: 'System Init',
          entity: 'Database',
          entityId: 'db',
          previousValue: '',
          newValue: 'Phase 2 Database Initialized',
          timestamp: DateTime.now(),
        ),
      ],
      heldPOSCarts: [],
      invoiceBrandingConfig: const InvoiceBrandingConfig(
        logoUrl: '',
        primaryColor: '#2563EB',
        fontName: 'Inter',
        bankName: 'Bunny Central Bank',
        bankAccountNumber: '1234567890',
        bankIfsc: 'BCB0001234',
        upiId: 'taxbunny@upi',
        authorizedSignatoryName: 'Rahul Sharma',
        termsConditions: '1. Goods once sold will not be taken back.\n2. Interest @ 18% will be charged if payment is not made within credit period.',
        footerText: 'Thank you for choosing Bunny Farms!',
      ),
      customUsers: [
        const {
          'name': 'Rahul (Owner)',
          'email': 'owner@taxbunny.com',
          'role': 'owner',
          'permissions': {
            'view': true,
            'create': true,
            'edit': true,
            'delete': true,
            'print': true,
            'export': true,
            'cancel': true,
            'approve': true,
          }
        },
        const {
          'name': 'Gopal (Accountant)',
          'email': 'accountant@taxbunny.com',
          'role': 'accountant',
          'permissions': {
            'view': true,
            'create': true,
            'edit': true,
            'delete': false,
            'print': true,
            'export': true,
            'cancel': false,
            'approve': true,
          }
        },
        const {
          'name': 'Rita (Sales)',
          'email': 'sales@taxbunny.com',
          'role': 'salesUser',
          'permissions': {
            'view': true,
            'create': true,
            'edit': true,
            'delete': false,
            'print': true,
            'export': false,
            'cancel': false,
            'approve': false,
          }
        },
      ],
      accounts: _getDefaultAccounts('biz_01'),
      journalEntries: [],
      bankAccounts: _getDefaultBankAccounts('biz_01'),
      accountingPeriods: _getDefaultPeriods('biz_01'),
      boms: _getDefaultBOMs('biz_01'),
      productionOrders: [],
      jobWorkOrders: [],
      notifications: _getDefaultNotifications(),
    );
  }

  // --- Customer CRUD ---
  Future<void> addCustomer(Customer c) async {
    state = state.copyWith(customers: [...state.customers, c]);
  }

  Future<void> updateCustomer(Customer c) async {
    state = state.copyWith(
      customers: state.customers.map((cust) => cust.id == c.id ? c : cust).toList(),
    );
  }

  Future<void> deleteCustomer(String id) async {
    state = state.copyWith(
      customers: state.customers.where((cust) => cust.id != id).toList(),
    );
  }

  // --- Supplier CRUD ---
  Future<void> addSupplier(Supplier s) async {
    state = state.copyWith(suppliers: [...state.suppliers, s]);
  }

  Future<void> updateSupplier(Supplier s) async {
    state = state.copyWith(
      suppliers: state.suppliers.map((supp) => supp.id == s.id ? s : supp).toList(),
    );
  }

  Future<void> deleteSupplier(String id) async {
    state = state.copyWith(
      suppliers: state.suppliers.where((supp) => supp.id != id).toList(),
    );
  }

  // --- Product CRUD ---
  Future<void> addProduct(Product p) async {
    final updatedList = [...state.products, p];
    final List<StockMovement> listMovements = [...state.stockMovements];
    if (p.openingStock > 0) {
      listMovements.add(
        StockMovement(
          id: 'sm_op_${p.id}_${DateTime.now().millisecondsSinceEpoch}',
          productId: p.id,
          productName: p.name,
          quantity: p.openingStock,
          type: StockMovementType.openingStock,
          date: DateTime.now(),
          referenceNumber: 'OP-STOCK-${p.code}',
        ),
      );
    }
    state = state.copyWith(
      products: updatedList,
      stockMovements: listMovements,
    );
  }

  Future<void> updateProduct(Product p) async {
    state = state.copyWith(
      products: state.products.map((prod) => prod.id == p.id ? p : prod).toList(),
    );
  }

  Future<void> adjustStock(String productId, double adjustmentQuantity, String reason, {String warehouseId = 'main'}) async {
    final product = state.products.firstWhere((p) => p.id == productId);
    final Map<String, double> updatedWarehouseStocks = Map.from(product.warehouseStocks);
    final double existingStock = updatedWarehouseStocks[warehouseId] ?? (warehouseId == 'main' ? product.currentStock : 0.0);
    updatedWarehouseStocks[warehouseId] = existingStock + adjustmentQuantity;

    final updatedProduct = product.copyWith(
      currentStock: product.currentStock + adjustmentQuantity,
      warehouseStocks: updatedWarehouseStocks,
    );
    final movement = StockMovement(
      id: 'sm_adj_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      quantity: adjustmentQuantity,
      type: StockMovementType.adjustment,
      date: DateTime.now(),
      referenceNumber: reason.isEmpty ? 'ADJUSTMENT' : reason,
      warehouseId: warehouseId,
    );

    _writeAuditLog('Manual Stock Adjustment', 'Product', productId, 'Stock: ${product.currentStock}', 'Stock: ${updatedProduct.currentStock}');

    state = state.copyWith(
      products: state.products.map((p) => p.id == productId ? updatedProduct : p).toList(),
      stockMovements: [...state.stockMovements, movement],
    );
  }

  // --- Service CRUD ---
  Future<void> addService(Service s) async {
    state = state.copyWith(services: [...state.services, s]);
  }

  Future<void> updateService(Service s) async {
    state = state.copyWith(
      services: state.services.map((serv) => serv.id == s.id ? s : serv).toList(),
    );
  }

  // --- Invoice Creation & Confirmation Engine ---
  Future<void> addInvoice(Invoice invoice) async {
    // Inserts invoice (could be draft or confirmed)
    final updatedInvoices = [...state.invoices, invoice];
    state = state.copyWith(invoices: updatedInvoices);

    if (invoice.status == InvoiceStatus.confirmed) {
      await _processInvoiceConfirmation(invoice);
    }
  }

  Future<void> confirmInvoice(String invoiceId) async {
    final invoiceIndex = state.invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) return;

    final invoice = state.invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.draft) return;

    final confirmedInvoice = invoice.copyWith(status: InvoiceStatus.confirmed);
    state = state.copyWith(
      invoices: state.invoices.map((inv) => inv.id == invoiceId ? confirmedInvoice : inv).toList(),
    );

    await _processInvoiceConfirmation(confirmedInvoice);
  }

  Future<void> _processInvoiceConfirmation(Invoice invoice) async {
    final now = DateTime.now();

    // 1. Update product stock levels & stock movements
    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);

    for (var item in invoice.items) {
      if (item.isProduct) {
        final prodIndex = updatedProducts.indexWhere((p) => p.id == item.productId);
        if (prodIndex != -1) {
          final prod = updatedProducts[prodIndex];
          // For Credit Notes (Returns), stock increases. Otherwise (Sales), stock decreases.
          final stockChange = invoice.isCreditNote ? item.quantity : -item.quantity;

          final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
          final double existingStock = updatedWarehouseStocks[invoice.warehouseId] ?? (invoice.warehouseId == 'main' ? prod.currentStock : 0.0);
          updatedWarehouseStocks[invoice.warehouseId] = existingStock + stockChange;

          final updatedProd = prod.copyWith(
            currentStock: prod.currentStock + stockChange,
            warehouseStocks: updatedWarehouseStocks,
          );
          updatedProducts[prodIndex] = updatedProd;

          newMovements.add(
            StockMovement(
              id: 'sm_inv_${invoice.id}_${item.id}',
              productId: item.productId,
              productName: item.name,
              quantity: stockChange,
              type: invoice.isCreditNote ? StockMovementType.salesReturn : StockMovementType.sale,
              date: invoice.invoiceDate,
              referenceNumber: invoice.invoiceNumber,
              warehouseId: invoice.warehouseId,
            ),
          );
        }
      }
    }

    // 2. Update Customer Outstanding Balance
    final List<Customer> updatedCustomers = List.from(state.customers);
    final custIndex = updatedCustomers.indexWhere((c) => c.id == invoice.customerId);
    if (custIndex != -1) {
      final cust = updatedCustomers[custIndex];
      // For credit notes, outstanding decreases. For standard invoices, outstanding increases.
      final outstandingChange = invoice.isCreditNote ? -invoice.grandTotal : invoice.grandTotal;
      final updatedCust = cust.copyWith(currentBalance: cust.currentBalance + outstandingChange);
      updatedCustomers[custIndex] = updatedCust;
    }

    // 3. Create Ledger Entry
    final double debit = invoice.isCreditNote ? 0.0 : invoice.grandTotal;
    final double credit = invoice.isCreditNote ? invoice.grandTotal : 0.0;
    
    // Calculate running balance for the ledger of this customer
    final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
    final double runningChange = debit - credit;
    final newLedgerEntry = LedgerEntry(
      id: 'led_inv_${invoice.id}',
      date: invoice.invoiceDate,
      particulars: invoice.isCreditNote
          ? 'Credit Note: ${invoice.invoiceNumber} (Linked: ${invoice.originalInvoiceId})'
          : 'Sales Invoice: ${invoice.invoiceNumber}',
      debit: debit,
      credit: credit,
      runningBalance: lastRunning + runningChange,
      referenceNumber: invoice.invoiceNumber,
      type: invoice.isCreditNote ? LedgerTransactionType.creditNote : LedgerTransactionType.sale,
    );

    _writeAuditLog('Confirm Invoice', 'Invoice', invoice.id, 'Status: DRAFT', 'Status: CONFIRMED');

    state = state.copyWith(
      products: updatedProducts,
      stockMovements: newMovements,
      customers: updatedCustomers,
      ledgerEntries: [...state.ledgerEntries, newLedgerEntry],
    );

    _createJournalForInvoice(invoice);
  }

  // --- Purchase Creation & Confirmation Engine ---
  Future<void> addPurchase(Purchase purchase) async {
    final updatedPurchases = [...state.purchases, purchase];
    state = state.copyWith(purchases: updatedPurchases);

    if (purchase.status == PurchaseStatus.confirmed) {
      await _processPurchaseConfirmation(purchase);
    }
  }

  Future<void> confirmPurchase(String purchaseId) async {
    final purchaseIndex = state.purchases.indexWhere((p) => p.id == purchaseId);
    if (purchaseIndex == -1) return;

    final purchase = state.purchases[purchaseIndex];
    if (purchase.status != PurchaseStatus.draft) return;

    final confirmedPurchase = purchase.copyWith(status: PurchaseStatus.confirmed);
    state = state.copyWith(
      purchases: state.purchases.map((p) => p.id == purchaseId ? confirmedPurchase : p).toList(),
    );

    await _processPurchaseConfirmation(confirmedPurchase);
  }

  Future<void> _processPurchaseConfirmation(Purchase purchase) async {
    // 1. Update product stock levels & stock movements
    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);

    for (var item in purchase.items) {
      final prodIndex = updatedProducts.indexWhere((p) => p.id == item.productId);
      if (prodIndex != -1) {
        final prod = updatedProducts[prodIndex];
        // For Debit Notes (Returns), stock decreases. For standard purchases, stock increases.
        final stockChange = purchase.isDebitNote ? -item.quantity : item.quantity;

        final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
        final double existingStock = updatedWarehouseStocks[purchase.warehouseId] ?? (purchase.warehouseId == 'main' ? prod.currentStock : 0.0);
        updatedWarehouseStocks[purchase.warehouseId] = existingStock + stockChange;

        final updatedProd = prod.copyWith(
          currentStock: prod.currentStock + stockChange,
          warehouseStocks: updatedWarehouseStocks,
        );
        updatedProducts[prodIndex] = updatedProd;

        newMovements.add(
          StockMovement(
            id: 'sm_pur_${purchase.id}_${item.id}',
            productId: item.productId,
            productName: item.name,
            quantity: stockChange,
            type: purchase.isDebitNote ? StockMovementType.purchaseReturn : StockMovementType.purchase,
            date: purchase.purchaseDate,
            referenceNumber: purchase.purchaseNumber,
            warehouseId: purchase.warehouseId,
          ),
        );
      }
    }

    // 2. Update Supplier Outstanding Payable Balance
    final List<Supplier> updatedSuppliers = List.from(state.suppliers);
    final suppIndex = updatedSuppliers.indexWhere((s) => s.id == purchase.supplierId);
    if (suppIndex != -1) {
      final supp = updatedSuppliers[suppIndex];
      // For debit notes, payable decreases. For standard purchases, payable increases.
      final balanceChange = purchase.isDebitNote ? -purchase.grandTotal : purchase.grandTotal;
      final updatedSupp = supp.copyWith(currentBalance: supp.currentBalance + balanceChange);
      updatedSuppliers[suppIndex] = updatedSupp;
    }

    // 3. Create Ledger Entry
    final double debit = purchase.isDebitNote ? purchase.grandTotal : 0.0;
    final double credit = purchase.isDebitNote ? 0.0 : purchase.grandTotal;

    final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
    // Debits increase asset/decrease liability. Credits increase liability/decrease asset.
    // For supplier ledger (running balance represent assets - liability), credits decrease it.
    final double runningChange = debit - credit;

    final newLedgerEntry = LedgerEntry(
      id: 'led_pur_${purchase.id}',
      date: purchase.purchaseDate,
      particulars: purchase.isDebitNote
          ? 'Debit Note: ${purchase.purchaseNumber} (Linked: ${purchase.originalPurchaseId})'
          : 'Purchase Bill: ${purchase.purchaseNumber}',
      debit: debit,
      credit: credit,
      runningBalance: lastRunning + runningChange,
      referenceNumber: purchase.purchaseNumber,
      type: purchase.isDebitNote ? LedgerTransactionType.debitNote : LedgerTransactionType.purchase,
    );

    _writeAuditLog('Confirm Purchase', 'Purchase', purchase.id, 'Status: DRAFT', 'Status: CONFIRMED');

    state = state.copyWith(
      products: updatedProducts,
      stockMovements: newMovements,
      suppliers: updatedSuppliers,
      ledgerEntries: [...state.ledgerEntries, newLedgerEntry],
    );

    _createJournalForPurchase(purchase);
  }

  // --- Receipts Allocation Engine ---
  Future<void> addReceipt(Receipt receipt) async {
    // 1. Save receipt
    state = state.copyWith(receipts: [...state.receipts, receipt]);

    // 2. Update invoice balances & status according to allocations
    final List<Invoice> updatedInvoices = List.from(state.invoices);
    for (var alloc in receipt.allocations) {
      final idx = updatedInvoices.indexWhere((inv) => inv.id == alloc.invoiceId);
      if (idx != -1) {
        final inv = updatedInvoices[idx];
        final double newBal = double.parse((inv.balanceAmount - alloc.amountAllocated).toStringAsFixed(2));
        InvoiceStatus newStatus = inv.status;
        if (newBal <= 0) {
          newStatus = InvoiceStatus.paid;
        } else if (newBal < inv.grandTotal) {
          newStatus = InvoiceStatus.partiallyPaid;
        }
        updatedInvoices[idx] = inv.copyWith(
          balanceAmount: newBal,
          status: newStatus,
        );
      }
    }

    // 3. Update Customer Balance (reduces outstanding)
    final List<Customer> updatedCustomers = List.from(state.customers);
    final custIdx = updatedCustomers.indexWhere((c) => c.id == receipt.customerId);
    if (custIdx != -1) {
      final cust = updatedCustomers[custIdx];
      updatedCustomers[custIdx] = cust.copyWith(
        currentBalance: double.parse((cust.currentBalance - receipt.amount).toStringAsFixed(2)),
      );
    }

    // 4. Create Ledger Entry
    final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
    final ledgerEntry = LedgerEntry(
      id: 'led_rec_${receipt.id}',
      date: receipt.date,
      particulars: 'Payment Receipt (${receipt.paymentMode}) - Ref: ${receipt.referenceNumber}',
      debit: 0.0,
      credit: receipt.amount,
      runningBalance: lastRunning - receipt.amount,
      referenceNumber: receipt.referenceNumber,
      type: LedgerTransactionType.receipt,
    );

    state = state.copyWith(
      invoices: updatedInvoices,
      customers: updatedCustomers,
      ledgerEntries: [...state.ledgerEntries, ledgerEntry],
    );

    _createJournalForReceipt(receipt);
  }

  // --- Payments Allocation Engine ---
  Future<void> addPayment(Payment payment) async {
    // 1. Save payment
    state = state.copyWith(payments: [...state.payments, payment]);

    // 2. Update purchase balances & status according to allocations
    final List<Purchase> updatedPurchases = List.from(state.purchases);
    for (var alloc in payment.allocations) {
      final idx = updatedPurchases.indexWhere((p) => p.id == alloc.purchaseId);
      if (idx != -1) {
        final pur = updatedPurchases[idx];
        final double newBal = double.parse((pur.balanceAmount - alloc.amountAllocated).toStringAsFixed(2));
        PurchaseStatus newStatus = pur.status;
        if (newBal <= 0) {
          newStatus = PurchaseStatus.paid;
        } else if (newBal < pur.grandTotal) {
          newStatus = PurchaseStatus.partiallyPaid;
        }
        updatedPurchases[idx] = pur.copyWith(
          balanceAmount: newBal,
          status: newStatus,
        );
      }
    }

    // 3. Update Supplier Balance (reduces outstanding)
    final List<Supplier> updatedSuppliers = List.from(state.suppliers);
    final suppIdx = updatedSuppliers.indexWhere((s) => s.id == payment.supplierId);
    if (suppIdx != -1) {
      final supp = updatedSuppliers[suppIdx];
      updatedSuppliers[suppIdx] = supp.copyWith(
        currentBalance: double.parse((supp.currentBalance - payment.amount).toStringAsFixed(2)),
      );
    }

    // 4. Create Ledger Entry
    final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
    final ledgerEntry = LedgerEntry(
      id: 'led_pay_${payment.id}',
      date: payment.date,
      particulars: 'Payment Outward (${payment.paymentMode}) - Ref: ${payment.referenceNumber}',
      debit: payment.amount,
      credit: 0.0,
      runningBalance: lastRunning + payment.amount,
      referenceNumber: payment.referenceNumber,
      type: LedgerTransactionType.payment,
    );

    state = state.copyWith(
      purchases: updatedPurchases,
      suppliers: updatedSuppliers,
      ledgerEntries: [...state.ledgerEntries, ledgerEntry],
    );

    _createJournalForPayment(payment);
  }

  // --- Expenses ---
  Future<void> addExpense(Expense exp) async {
    state = state.copyWith(expenses: [...state.expenses, exp]);
    _createJournalForExpense(exp);
  }

  // --- Transaction Cancellation ---
  Future<void> cancelInvoice(String invoiceId) async {
    final idx = state.invoices.indexWhere((inv) => inv.id == invoiceId);
    if (idx == -1) return;

    final invoice = state.invoices[idx];
    if (invoice.status == InvoiceStatus.cancelled) return;

    final cancelledInvoice = invoice.copyWith(
      status: InvoiceStatus.cancelled,
      balanceAmount: 0.0,
    );

    // If it was confirmed previously, reverse its inventory & financial impacts!
    if (invoice.status == InvoiceStatus.confirmed ||
        invoice.status == InvoiceStatus.partiallyPaid ||
        invoice.status == InvoiceStatus.paid) {
      
      // 1. Reverse stock
      final List<Product> updatedProducts = List.from(state.products);
      final List<StockMovement> newMovements = List.from(state.stockMovements);
      for (var item in invoice.items) {
        if (item.isProduct) {
          final pIdx = updatedProducts.indexWhere((p) => p.id == item.productId);
          if (pIdx != -1) {
            final prod = updatedProducts[pIdx];
            final stockChange = invoice.isCreditNote ? -item.quantity : item.quantity; // reverse the change
            updatedProducts[pIdx] = prod.copyWith(currentStock: prod.currentStock + stockChange);

            newMovements.add(
              StockMovement(
                id: 'sm_cancel_${invoice.id}_${item.id}',
                productId: item.productId,
                productName: item.name,
                quantity: stockChange,
                type: StockMovementType.adjustment,
                date: DateTime.now(),
                referenceNumber: 'CANCEL-${invoice.invoiceNumber}',
              ),
            );
          }
        }
      }

      // 2. Reverse Customer Balance
      final List<Customer> updatedCustomers = List.from(state.customers);
      final cIdx = updatedCustomers.indexWhere((c) => c.id == invoice.customerId);
      if (cIdx != -1) {
        final cust = updatedCustomers[cIdx];
        final balanceOffset = invoice.isCreditNote ? invoice.grandTotal : -invoice.grandTotal;
        updatedCustomers[cIdx] = cust.copyWith(currentBalance: cust.currentBalance + balanceOffset);
      }

      // 3. Reverse Ledger Entry
      final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
      final ledgerEntry = LedgerEntry(
        id: 'led_cancel_${invoice.id}',
        date: DateTime.now(),
        particulars: 'Cancelled Invoice: ${invoice.invoiceNumber}',
        debit: invoice.isCreditNote ? invoice.grandTotal : 0.0,
        credit: invoice.isCreditNote ? 0.0 : invoice.grandTotal,
        runningBalance: lastRunning + (invoice.isCreditNote ? invoice.grandTotal : -invoice.grandTotal),
        referenceNumber: invoice.invoiceNumber,
        type: LedgerTransactionType.openingBalance, // Reverse adjustment type
      );

      state = state.copyWith(
        invoices: state.invoices.map((inv) => inv.id == invoiceId ? cancelledInvoice : inv).toList(),
        products: updatedProducts,
        stockMovements: newMovements,
        customers: updatedCustomers,
        ledgerEntries: [...state.ledgerEntries, ledgerEntry],
      );

      reverseJournalEntry(invoice.id, 'Invoice');
    } else {
      // Just mark cancelled if it was draft
      state = state.copyWith(
        invoices: state.invoices.map((inv) => inv.id == invoiceId ? cancelledInvoice : inv).toList(),
      );
    }
  }

  Future<void> cancelPurchase(String purchaseId) async {
    final idx = state.purchases.indexWhere((p) => p.id == purchaseId);
    if (idx == -1) return;

    final purchase = state.purchases[idx];
    if (purchase.status == PurchaseStatus.cancelled) return;

    final cancelledPurchase = purchase.copyWith(
      status: PurchaseStatus.cancelled,
      balanceAmount: 0.0,
    );

    if (purchase.status == PurchaseStatus.confirmed ||
        purchase.status == PurchaseStatus.partiallyPaid ||
        purchase.status == PurchaseStatus.paid) {
      
      // 1. Reverse stock
      final List<Product> updatedProducts = List.from(state.products);
      final List<StockMovement> newMovements = List.from(state.stockMovements);
      for (var item in purchase.items) {
        final pIdx = updatedProducts.indexWhere((p) => p.id == item.productId);
        if (pIdx != -1) {
          final prod = updatedProducts[pIdx];
          final stockChange = purchase.isDebitNote ? item.quantity : -item.quantity; // reverse the change
          updatedProducts[pIdx] = prod.copyWith(currentStock: prod.currentStock + stockChange);

          newMovements.add(
            StockMovement(
              id: 'sm_cancel_${purchase.id}_${item.id}',
              productId: item.productId,
              productName: item.name,
              quantity: stockChange,
              type: StockMovementType.adjustment,
              date: DateTime.now(),
              referenceNumber: 'CANCEL-${purchase.purchaseNumber}',
            ),
          );
        }
      }

      // 2. Reverse Supplier Balance
      final List<Supplier> updatedSuppliers = List.from(state.suppliers);
      final sIdx = updatedSuppliers.indexWhere((s) => s.id == purchase.supplierId);
      if (sIdx != -1) {
        final supp = updatedSuppliers[sIdx];
        final balanceOffset = purchase.isDebitNote ? purchase.grandTotal : -purchase.grandTotal;
        updatedSuppliers[sIdx] = supp.copyWith(currentBalance: supp.currentBalance + balanceOffset);
      }

      // 3. Reverse Ledger Entry
      final lastRunning = state.ledgerEntries.isNotEmpty ? state.ledgerEntries.last.runningBalance : 0.0;
      final ledgerEntry = LedgerEntry(
        id: 'led_cancel_${purchase.id}',
        date: DateTime.now(),
        particulars: 'Cancelled Purchase Bill: ${purchase.purchaseNumber}',
        debit: purchase.isDebitNote ? 0.0 : purchase.grandTotal,
        credit: purchase.isDebitNote ? purchase.grandTotal : 0.0,
        runningBalance: lastRunning + (purchase.isDebitNote ? -purchase.grandTotal : purchase.grandTotal),
        referenceNumber: purchase.purchaseNumber,
        type: LedgerTransactionType.openingBalance,
      );

      state = state.copyWith(
        purchases: state.purchases.map((p) => p.id == purchaseId ? cancelledPurchase : p).toList(),
        products: updatedProducts,
        stockMovements: newMovements,
        suppliers: updatedSuppliers,
        ledgerEntries: [...state.ledgerEntries, ledgerEntry],
      );

      reverseJournalEntry(purchase.id, 'Purchase');
    } else {
      state = state.copyWith(
        purchases: state.purchases.map((p) => p.id == purchaseId ? cancelledPurchase : p).toList(),
      );
    }
  }

  // --- Phase 3: Double-Entry Accounting Engine ---

  void _postJournalEntry(JournalEntry entry) {
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (var line in entry.lines) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }
    totalDebit = double.parse(totalDebit.toStringAsFixed(2));
    totalCredit = double.parse(totalCredit.toStringAsFixed(2));
    if (totalDebit != totalCredit) {
      throw Exception('Accounting Error: Total Debit ($totalDebit) must equal Total Credit ($totalCredit).');
    }

    final now = entry.date;
    final periodIndex = state.accountingPeriods.indexWhere(
      (p) => now.isAfter(p.startDate.subtract(const Duration(days: 1))) &&
             now.isBefore(p.endDate.add(const Duration(days: 1))),
    );

    if (periodIndex != -1) {
      final period = state.accountingPeriods[periodIndex];
      if (period.status == PeriodStatus.locked || period.status == PeriodStatus.closed) {
        throw Exception('Accounting Error: Financial Period ${period.name} is Locked or Closed. Cannot post entries.');
      }
    }

    final updatedAccounts = state.accounts.map((acc) {
      double balChange = 0.0;
      for (var line in entry.lines) {
        if (line.accountId == acc.id) {
          if (acc.type == AccountType.asset || acc.type == AccountType.expense) {
            balChange += (line.debit - line.credit);
          } else {
            balChange += (line.credit - line.debit);
          }
        }
      }
      if (balChange == 0.0) return acc;
      return acc.copyWith(
        currentBalance: double.parse((acc.currentBalance + balChange).toStringAsFixed(2)),
      );
    }).toList();

    state = state.copyWith(
      journalEntries: [...state.journalEntries, entry],
      accounts: updatedAccounts,
    );
  }

  void reverseJournalEntry(String referenceId, String referenceType) {
    final entryIndex = state.journalEntries.indexWhere((e) => e.referenceId == referenceId && e.referenceType == referenceType && e.status == JournalStatus.posted);
    if (entryIndex == -1) return;
    final entry = state.journalEntries[entryIndex];

    final reversedLines = entry.lines.map((line) => JournalEntryLine(
      id: 'line_rev_${line.id}_${DateTime.now().millisecondsSinceEpoch}',
      journalEntryId: 'rev_${entry.id}',
      accountId: line.accountId,
      accountName: line.accountName,
      debit: line.credit,
      credit: line.debit,
      description: 'Reversal of: ${line.description}',
    )).toList();

    final reversal = JournalEntry(
      id: 'je_rev_${entry.id}_${DateTime.now().millisecondsSinceEpoch}',
      businessId: entry.businessId,
      date: DateTime.now(),
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      narration: 'Reversal Entry for cancelled ${entry.referenceType} (Ref: ${entry.id})',
      status: JournalStatus.posted,
      lines: reversedLines,
    );

    final updatedEntries = state.journalEntries.map((e) {
      if (e.id == entry.id) {
        return e.copyWith(status: JournalStatus.cancelled);
      }
      return e;
    }).toList();

    state = state.copyWith(journalEntries: updatedEntries);
    _postJournalEntry(reversal);
    _writeAuditLog('Reverse Journal Entry', 'JournalEntry', entry.id, 'Status: POSTED', 'Status: CANCELLED');
  }

  void _createJournalForInvoice(Invoice invoice) {
    final entryId = 'je_inv_${invoice.id}';
    final lines = <JournalEntryLine>[];

    final double debitVal = invoice.grandTotal;
    final double salesVal = invoice.taxableAmount;
    final double gstVal = invoice.cgst + invoice.sgst + invoice.igst;

    if (invoice.isCreditNote) {
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_sales',
        journalEntryId: entryId,
        accountId: 'acc_sales',
        accountName: 'Sales Revenue',
        debit: salesVal,
        credit: 0.0,
        description: 'Sales Return Debit',
      ));
      if (gstVal > 0) {
        lines.add(JournalEntryLine(
          id: 'line_${entryId}_gst',
          journalEntryId: entryId,
          accountId: 'acc_output_gst',
          accountName: 'GST Output Tax Liability',
          debit: gstVal,
          credit: 0.0,
          description: 'GST Output Return Debit',
        ));
      }
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_ar',
        journalEntryId: entryId,
        accountId: 'acc_ar',
        accountName: 'Accounts Receivable',
        debit: 0.0,
        credit: debitVal,
        description: 'Credit Note Customer Credit',
      ));
    } else {
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_ar',
        journalEntryId: entryId,
        accountId: 'acc_ar',
        accountName: 'Accounts Receivable',
        debit: debitVal,
        credit: 0.0,
        description: 'Sales Invoice Debit',
      ));
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_sales',
        journalEntryId: entryId,
        accountId: 'acc_sales',
        accountName: 'Sales Revenue',
        debit: 0.0,
        credit: salesVal,
        description: 'Sales Revenue Credit',
      ));
      if (gstVal > 0) {
        lines.add(JournalEntryLine(
          id: 'line_${entryId}_gst',
          journalEntryId: entryId,
          accountId: 'acc_output_gst',
          accountName: 'GST Output Tax Liability',
          debit: 0.0,
          credit: gstVal,
          description: 'GST Output Tax Credit',
        ));
      }
    }

    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: invoice.invoiceDate,
      referenceType: 'Invoice',
      referenceId: invoice.id,
      narration: invoice.isCreditNote ? 'Credit Note Return: ${invoice.invoiceNumber}' : 'Sales Invoice: ${invoice.invoiceNumber}',
      status: JournalStatus.posted,
      lines: lines,
    );

    _postJournalEntry(entry);
    _writeAuditLog('Post Journal Entry', 'Invoice', invoice.id, '', 'Journal Entry: $entryId');
  }

  void _createJournalForPurchase(Purchase purchase) {
    final entryId = 'je_pur_${purchase.id}';
    final lines = <JournalEntryLine>[];

    final double creditVal = purchase.grandTotal;
    final double purchaseVal = purchase.taxableAmount;
    final double gstVal = purchase.cgst + purchase.sgst + purchase.igst;

    if (purchase.isDebitNote) {
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_ap',
        journalEntryId: entryId,
        accountId: 'acc_ap',
        accountName: 'Accounts Payable',
        debit: creditVal,
        credit: 0.0,
        description: 'Debit Note Supplier Debit',
      ));
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_pur',
        journalEntryId: entryId,
        accountId: 'acc_purchases',
        accountName: 'Direct Purchases',
        debit: 0.0,
        credit: purchaseVal,
        description: 'Purchase Return Credit',
      ));
      if (gstVal > 0) {
        lines.add(JournalEntryLine(
          id: 'line_${entryId}_gst',
          journalEntryId: entryId,
          accountId: 'acc_input_gst',
          accountName: 'GST Input Tax Credit',
          debit: 0.0,
          credit: gstVal,
          description: 'GST Input Reverse Credit',
        ));
      }
    } else {
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_pur',
        journalEntryId: entryId,
        accountId: 'acc_purchases',
        accountName: 'Direct Purchases',
        debit: purchaseVal,
        credit: 0.0,
        description: 'Direct Purchase Debit',
      ));
      if (gstVal > 0) {
        lines.add(JournalEntryLine(
          id: 'line_${entryId}_gst',
          journalEntryId: entryId,
          accountId: 'acc_input_gst',
          accountName: 'GST Input Tax Credit',
          debit: gstVal,
          credit: 0.0,
          description: 'GST Input Tax Debit',
        ));
      }
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_ap',
        journalEntryId: entryId,
        accountId: 'acc_ap',
        accountName: 'Accounts Payable',
        debit: 0.0,
        credit: creditVal,
        description: 'Supplier Credit',
      ));
    }

    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: purchase.purchaseDate,
      referenceType: 'Purchase',
      referenceId: purchase.id,
      narration: purchase.isDebitNote ? 'Debit Note Return: ${purchase.purchaseNumber}' : 'Purchase Bill: ${purchase.purchaseNumber}',
      status: JournalStatus.posted,
      lines: lines,
    );

    _postJournalEntry(entry);
    _writeAuditLog('Post Journal Entry', 'Purchase', purchase.id, '', 'Journal Entry: $entryId');
  }

  void _createJournalForReceipt(Receipt receipt) {
    final entryId = 'je_rec_${receipt.id}';
    final lines = <JournalEntryLine>[];

    final double amount = receipt.amount;
    final bool isBank = receipt.paymentMode.toLowerCase() != 'cash';

    lines.add(JournalEntryLine(
      id: 'line_${entryId}_cashbank',
      journalEntryId: entryId,
      accountId: isBank ? 'acc_bank' : 'acc_cash',
      accountName: isBank ? 'Bank Account' : 'Cash Account',
      debit: amount,
      credit: 0.0,
      description: 'Payment Received (${receipt.paymentMode})',
    ));
    lines.add(JournalEntryLine(
      id: 'line_${entryId}_ar',
      journalEntryId: entryId,
      accountId: 'acc_ar',
      accountName: 'Accounts Receivable',
      debit: 0.0,
      credit: amount,
      description: 'Customer Account Credit',
    ));

    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: receipt.date,
      referenceType: 'Receipt',
      referenceId: receipt.id,
      narration: 'Receipt Ref: ${receipt.referenceNumber} (Mode: ${receipt.paymentMode})',
      status: JournalStatus.posted,
      lines: lines,
    );

    _postJournalEntry(entry);
    _writeAuditLog('Post Journal Entry', 'Receipt', receipt.id, '', 'Journal Entry: $entryId');
  }

  void _createJournalForPayment(Payment payment) {
    final entryId = 'je_pay_${payment.id}';
    final lines = <JournalEntryLine>[];

    final double amount = payment.amount;
    final bool isBank = payment.paymentMode.toLowerCase() != 'cash';

    lines.add(JournalEntryLine(
      id: 'line_${entryId}_ap',
      journalEntryId: entryId,
      accountId: 'acc_ap',
      accountName: 'Accounts Payable',
      debit: amount,
      credit: 0.0,
      description: 'Supplier Account Debit',
    ));
    lines.add(JournalEntryLine(
      id: 'line_${entryId}_cashbank',
      journalEntryId: entryId,
      accountId: isBank ? 'acc_bank' : 'acc_cash',
      accountName: isBank ? 'Bank Account' : 'Cash Account',
      debit: 0.0,
      credit: amount,
      description: 'Payment Disbursed (${payment.paymentMode})',
    ));

    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: payment.date,
      referenceType: 'Payment',
      referenceId: payment.id,
      narration: 'Payment Outward Ref: ${payment.referenceNumber} (Mode: ${payment.paymentMode})',
      status: JournalStatus.posted,
      lines: lines,
    );

    _postJournalEntry(entry);
    _writeAuditLog('Post Journal Entry', 'Payment', payment.id, '', 'Journal Entry: $entryId');
  }

  void _createJournalForExpense(Expense expense) {
    final entryId = 'je_exp_${expense.id}';
    final lines = <JournalEntryLine>[];

    final double amount = expense.amount;
    final double gst = expense.gst;
    final double netAmount = amount - gst;
    final bool isBank = expense.paymentMode.toLowerCase() != 'cash';

    lines.add(JournalEntryLine(
      id: 'line_${entryId}_exp',
      journalEntryId: entryId,
      accountId: 'acc_expenses',
      accountName: 'General Expenses (${expense.category})',
      debit: netAmount,
      credit: 0.0,
      description: 'Expense Debit - ${expense.category}',
    ));
    if (gst > 0) {
      lines.add(JournalEntryLine(
        id: 'line_${entryId}_gst',
        journalEntryId: entryId,
        accountId: 'acc_input_gst',
        accountName: 'GST Input Tax Credit',
        debit: gst,
        credit: 0.0,
        description: 'Expense GST Input Debit',
      ));
    }
    lines.add(JournalEntryLine(
      id: 'line_${entryId}_cashbank',
      journalEntryId: entryId,
      accountId: isBank ? 'acc_bank' : 'acc_cash',
      accountName: isBank ? 'Bank Account' : 'Cash Account',
      debit: 0.0,
      credit: amount,
      description: 'Paid via ${expense.paymentMode}',
    ));

    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: expense.date,
      referenceType: 'Expense',
      referenceId: expense.id,
      narration: 'Expense Ref: ${expense.id} (Category: ${expense.category})',
      status: JournalStatus.posted,
      lines: lines,
    );

    _postJournalEntry(entry);
    _writeAuditLog('Post Journal Entry', 'Expense', expense.id, '', 'Journal Entry: $entryId');
  }

  // --- Phase 3: Business Operations Methods ---

  Future<void> addAccount(Account acc) async {
    state = state.copyWith(accounts: [...state.accounts, acc]);
    _writeAuditLog('Create Account', 'Account', acc.id, '', 'Code: ${acc.code}, Name: ${acc.name}');
  }

  Future<void> updateAccount(Account acc) async {
    state = state.copyWith(
      accounts: state.accounts.map((a) => a.id == acc.id ? acc : a).toList(),
    );
    _writeAuditLog('Update Account', 'Account', acc.id, 'Old values', 'Code: ${acc.code}, Name: ${acc.name}');
  }

  Future<void> deactivateAccount(String id) async {
    final hasTx = state.journalEntries.any((je) => je.lines.any((l) => l.accountId == id));
    if (hasTx) {
      throw Exception('Cannot delete or deactivate an account that contains active accounting transactions. Please archive instead.');
    }
    state = state.copyWith(
      accounts: state.accounts.map((a) => a.id == id ? a.copyWith(isActive: false) : a).toList(),
    );
    _writeAuditLog('Deactivate Account', 'Account', id, 'Status: ACTIVE', 'Status: INACTIVE');
  }

  Future<void> addManualJournalEntry(JournalEntry entry) async {
    _postJournalEntry(entry);
    _writeAuditLog('Post Manual Journal', 'JournalEntry', entry.id, '', 'Narration: ${entry.narration}');
  }

  Future<void> addBankAccount(BankAccount bank) async {
    state = state.copyWith(bankAccounts: [...state.bankAccounts, bank]);
    _writeAuditLog('Add Bank Account', 'BankAccount', bank.id, '', 'Bank: ${bank.bankName}');
  }

  Future<void> addBankTransfer(String sourceBankId, String destBankId, double amount, String refNo) async {
    final srcBank = state.bankAccounts.firstWhere((b) => b.id == sourceBankId);
    final destBank = state.bankAccounts.firstWhere((b) => b.id == destBankId);

    if (srcBank.currentBalance < amount) {
      throw Exception('Insufficient funds in source bank account (${srcBank.bankName}).');
    }

    final updatedBanks = state.bankAccounts.map((b) {
      if (b.id == sourceBankId) {
        return b.copyWith(currentBalance: double.parse((b.currentBalance - amount).toStringAsFixed(2)));
      }
      if (b.id == destBankId) {
        return b.copyWith(currentBalance: double.parse((b.currentBalance + amount).toStringAsFixed(2)));
      }
      return b;
    }).toList();

    state = state.copyWith(bankAccounts: updatedBanks);

    final entryId = 'je_transfer_${DateTime.now().millisecondsSinceEpoch}';
    final entry = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: DateTime.now(),
      referenceType: 'BankTransfer',
      referenceId: refNo,
      narration: 'Interbank transfer from ${srcBank.bankName} to ${destBank.bankName} - Ref: $refNo',
      status: JournalStatus.posted,
      lines: [
        JournalEntryLine(
          id: 'line_${entryId}_dest',
          journalEntryId: entryId,
          accountId: 'acc_bank',
          accountName: destBank.bankName,
          debit: amount,
          credit: 0.0,
          description: 'Debit to receiving bank account',
        ),
        JournalEntryLine(
          id: 'line_${entryId}_src',
          journalEntryId: entryId,
          accountId: 'acc_bank',
          accountName: srcBank.bankName,
          debit: 0.0,
          credit: amount,
          description: 'Credit to sending bank account',
        ),
      ],
    );

    _postJournalEntry(entry);
    _writeAuditLog('Bank Contra Transfer', 'BankAccount', sourceBankId, 'Transfer of ₹$amount to $destBankId', 'Done');
  }

  Future<void> addBOM(BOM bom) async {
    state = state.copyWith(boms: [...state.boms, bom]);
    _writeAuditLog('Create BOM', 'BOM', bom.id, '', 'Product: ${bom.finishedProductName}, Version: ${bom.version}');
  }

  Future<void> updateBOM(BOM bom) async {
    state = state.copyWith(
      boms: state.boms.map((b) => b.id == bom.id ? bom : b).toList(),
    );
    _writeAuditLog('Update BOM', 'BOM', bom.id, 'Old recipe', 'Version: ${bom.version}');
  }

  Future<void> addProductionOrder(ProductionOrder order) async {
    state = state.copyWith(productionOrders: [...state.productionOrders, order]);
    _writeAuditLog('Create Production Order', 'ProductionOrder', order.id, '', 'No: ${order.productionNumber}, Status: DRAFT');
  }

  Future<void> startProduction(String orderId) async {
    final index = state.productionOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = state.productionOrders[index];

    final List<String> shortages = [];
    for (var consumed in order.consumedItems) {
      final product = state.products.firstWhere((p) => p.id == consumed.productId);
      final double qtyNeeded = consumed.quantityRequired;
      final double qtyAvailable = product.warehouseStocks[order.rawMaterialWarehouseId] ?? 0.0;
      if (qtyAvailable < qtyNeeded) {
        shortages.add('${product.name} (Required: $qtyNeeded, Available: $qtyAvailable)');
      }
    }

    if (shortages.isNotEmpty) {
      final notif = NotificationModel(
        id: 'not_short_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Production Material Shortage',
        description: 'Shortage for Production Run ${order.productionNumber}: ${shortages.join(", ")}',
        timestamp: DateTime.now(),
        isRead: false,
      );
      state = state.copyWith(notifications: [...state.notifications, notif]);
      throw Exception('Insufficient raw materials available: ${shortages.join(", ")}');
    }

    final updated = order.copyWith(status: ProductionStatus.inProgress);
    state = state.copyWith(
      productionOrders: state.productionOrders.map((o) => o.id == orderId ? updated : o).toList(),
    );
    _writeAuditLog('Start Production', 'ProductionOrder', orderId, 'Status: DRAFT', 'Status: IN_PROGRESS');
  }

  Future<void> completeProduction({
    required String orderId,
    required double laborCost,
    required double overheadCost,
    required List<ProductionConsumptionItem> actualConsumption,
    required List<ProductionWastageItem> wastageItems,
  }) async {
    final index = state.productionOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = state.productionOrders[index];

    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);
    double totalRawMaterialCost = 0.0;

    for (var item in actualConsumption) {
      final pIdx = updatedProducts.indexWhere((p) => p.id == item.productId);
      if (pIdx != -1) {
        final prod = updatedProducts[pIdx];
        final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
        final double currentStock = updatedWarehouseStocks[order.rawMaterialWarehouseId] ?? 0.0;
        updatedWarehouseStocks[order.rawMaterialWarehouseId] = currentStock - item.quantityConsumed;

        final updatedProd = prod.copyWith(
          currentStock: prod.currentStock - item.quantityConsumed,
          warehouseStocks: updatedWarehouseStocks,
        );
        updatedProducts[pIdx] = updatedProd;

        totalRawMaterialCost += (item.quantityConsumed * prod.purchasePrice);

        newMovements.add(
          StockMovement(
            id: 'sm_prod_con_${order.id}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            quantity: -item.quantityConsumed,
            type: StockMovementType.adjustment,
            date: DateTime.now(),
            referenceNumber: 'PROD-CONSUME-${order.productionNumber}',
            warehouseId: order.rawMaterialWarehouseId,
          ),
        );
      }
    }

    double scrapValueComputed = 0.0;
    for (var wastage in wastageItems) {
      final pIdx = updatedProducts.indexWhere((p) => p.id == wastage.productId);
      if (pIdx != -1) {
        final prod = updatedProducts[pIdx];
        if (wastage.type == 'SCRAP') {
          scrapValueComputed += (wastage.quantity * prod.purchasePrice * 0.5);
        }

        final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
        final double currentStock = updatedWarehouseStocks[order.rawMaterialWarehouseId] ?? 0.0;
        updatedWarehouseStocks[order.rawMaterialWarehouseId] = currentStock - wastage.quantity;

        final updatedProd = prod.copyWith(
          currentStock: prod.currentStock - wastage.quantity,
          warehouseStocks: updatedWarehouseStocks,
        );
        updatedProducts[pIdx] = updatedProd;

        newMovements.add(
          StockMovement(
            id: 'sm_prod_wast_${order.id}_${wastage.productId}',
            productId: wastage.productId,
            productName: wastage.productName,
            quantity: -wastage.quantity,
            type: StockMovementType.adjustment,
            date: DateTime.now(),
            referenceNumber: 'PROD-WASTAGE-${order.productionNumber}',
            warehouseId: order.rawMaterialWarehouseId,
          ),
        );
      }
    }

    final double totalProductionCost = totalRawMaterialCost + laborCost + overheadCost - scrapValueComputed;
    final double costPerUnit = totalProductionCost / order.quantity;

    final finishedIdx = updatedProducts.indexWhere((p) => p.id == order.finishedProductId);
    if (finishedIdx != -1) {
      final prod = updatedProducts[finishedIdx];
      final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
      final double currentStock = updatedWarehouseStocks[order.warehouseId] ?? 0.0;
      updatedWarehouseStocks[order.warehouseId] = currentStock + order.quantity;

      final updatedProd = prod.copyWith(
        currentStock: prod.currentStock + order.quantity,
        warehouseStocks: updatedWarehouseStocks,
        purchasePrice: costPerUnit,
      );
      updatedProducts[finishedIdx] = updatedProd;

      newMovements.add(
        StockMovement(
          id: 'sm_prod_fg_${order.id}',
          productId: order.finishedProductId,
          productName: order.finishedProductName,
          quantity: order.quantity,
          type: StockMovementType.adjustment,
          date: DateTime.now(),
          referenceNumber: 'PROD-OUTPUT-${order.productionNumber}',
          warehouseId: order.warehouseId,
        ),
      );
    }

    final updatedOrder = order.copyWith(
      status: ProductionStatus.completed,
      rawMaterialCost: totalRawMaterialCost,
      laborCost: laborCost,
      overheadCost: overheadCost,
      scrapValue: scrapValueComputed,
      totalCost: totalProductionCost,
      consumedItems: actualConsumption,
      wastageItems: wastageItems,
    );

    final entryId = 'je_prod_${order.id}';
    final lines = [
      JournalEntryLine(
        id: 'line_${entryId}_fg',
        journalEntryId: entryId,
        accountId: 'acc_finished_stock',
        accountName: 'Finished Goods Stock',
        debit: totalProductionCost,
        credit: 0.0,
        description: 'Finished Goods Output: ${order.quantity} units',
      ),
      if (scrapValueComputed > 0)
        JournalEntryLine(
          id: 'line_${entryId}_scrap',
          journalEntryId: entryId,
          accountId: 'acc_scrap',
          accountName: 'Scrap Sales',
          debit: scrapValueComputed,
          credit: 0.0,
          description: 'Scrap Recovery Value',
        ),
      JournalEntryLine(
        id: 'line_${entryId}_raw',
        journalEntryId: entryId,
        accountId: 'acc_raw_stock',
        accountName: 'Raw Material Stock',
        debit: 0.0,
        credit: totalRawMaterialCost,
        description: 'Raw Materials Consumed',
      ),
      if (laborCost > 0)
        JournalEntryLine(
          id: 'line_${entryId}_labor',
          journalEntryId: entryId,
          accountId: 'acc_labor',
          accountName: 'Production Labor Cost',
          debit: 0.0,
          credit: laborCost,
          description: 'Labor Cost Allocation',
        ),
      if (overheadCost > 0)
        JournalEntryLine(
          id: 'line_${entryId}_overhead',
          journalEntryId: entryId,
          accountId: 'acc_overhead',
          accountName: 'Production Overhead',
          debit: 0.0,
          credit: overheadCost,
          description: 'Overhead Allocation',
        ),
    ];

    final journal = JournalEntry(
      id: entryId,
      businessId: _businessId,
      date: DateTime.now(),
      referenceType: 'Production',
      referenceId: order.id,
      narration: 'Production Completion: ${order.productionNumber}',
      status: JournalStatus.posted,
      lines: lines,
    );

    state = state.copyWith(
      productionOrders: state.productionOrders.map((o) => o.id == orderId ? updatedOrder : o).toList(),
      products: updatedProducts,
      stockMovements: newMovements,
    );

    _postJournalEntry(journal);

    final notif = NotificationModel(
      id: 'not_comp_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Production Completed',
      description: 'Production Order ${order.productionNumber} completed successfully. Finished goods updated.',
      timestamp: DateTime.now(),
      isRead: false,
    );
    state = state.copyWith(notifications: [...state.notifications, notif]);

    _writeAuditLog('Complete Production', 'ProductionOrder', orderId, 'Status: IN_PROGRESS', 'Status: COMPLETED');
  }

  Future<void> cancelProduction(String orderId) async {
    final index = state.productionOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = state.productionOrders[index];

    if (order.status == ProductionStatus.completed) {
      final List<Product> updatedProducts = List.from(state.products);
      final List<StockMovement> newMovements = List.from(state.stockMovements);

      for (var item in order.consumedItems) {
        final pIdx = updatedProducts.indexWhere((p) => p.id == item.productId);
        if (pIdx != -1) {
          final prod = updatedProducts[pIdx];
          final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
          final double currentStock = updatedWarehouseStocks[order.rawMaterialWarehouseId] ?? 0.0;
          updatedWarehouseStocks[order.rawMaterialWarehouseId] = currentStock + item.quantityConsumed;
          updatedProducts[pIdx] = prod.copyWith(
            currentStock: prod.currentStock + item.quantityConsumed,
            warehouseStocks: updatedWarehouseStocks,
          );
          newMovements.add(
            StockMovement(
              id: 'sm_prod_rev_con_${order.id}_${item.productId}',
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantityConsumed,
              type: StockMovementType.adjustment,
              date: DateTime.now(),
              referenceNumber: 'REVERT-CONSUMPTION-${order.productionNumber}',
              warehouseId: order.rawMaterialWarehouseId,
            ),
          );
        }
      }

      final finishedIdx = updatedProducts.indexWhere((p) => p.id == order.finishedProductId);
      if (finishedIdx != -1) {
        final prod = updatedProducts[finishedIdx];
        final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
        final double currentStock = updatedWarehouseStocks[order.warehouseId] ?? 0.0;
        updatedWarehouseStocks[order.warehouseId] = currentStock - order.quantity;
        updatedProducts[finishedIdx] = prod.copyWith(
          currentStock: prod.currentStock - order.quantity,
          warehouseStocks: updatedWarehouseStocks,
        );
        newMovements.add(
          StockMovement(
            id: 'sm_prod_rev_fg_${order.id}',
            productId: order.finishedProductId,
            productName: order.finishedProductName,
            quantity: -order.quantity,
            type: StockMovementType.adjustment,
            date: DateTime.now(),
            referenceNumber: 'REVERT-FG-${order.productionNumber}',
            warehouseId: order.warehouseId,
          ),
        );
      }

      state = state.copyWith(
        products: updatedProducts,
        stockMovements: newMovements,
      );

      reverseJournalEntry(order.id, 'Production');
    }

    final updated = order.copyWith(status: ProductionStatus.cancelled);
    state = state.copyWith(
      productionOrders: state.productionOrders.map((o) => o.id == orderId ? updated : o).toList(),
    );
    _writeAuditLog('Cancel Production', 'ProductionOrder', orderId, 'Status: ${order.status.displayName}', 'Status: CANCELLED');
  }

  Future<void> addJobWorkOrder(JobWorkOrder order) async {
    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);
    final pIdx = updatedProducts.indexWhere((p) => p.id == order.rawMaterialId);
    if (pIdx != -1) {
      final prod = updatedProducts[pIdx];
      final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
      final double currentStock = updatedWarehouseStocks['main'] ?? 0.0;
      updatedWarehouseStocks['main'] = currentStock - order.quantitySent;
      updatedProducts[pIdx] = prod.copyWith(
        currentStock: prod.currentStock - order.quantitySent,
        warehouseStocks: updatedWarehouseStocks,
      );
      newMovements.add(
        StockMovement(
          id: 'sm_jw_send_${order.id}',
          productId: order.rawMaterialId,
          productName: order.rawMaterialName,
          quantity: -order.quantitySent,
          type: StockMovementType.adjustment,
          date: order.dateSent,
          referenceNumber: 'JOBWORK-SEND-${order.reference}',
          warehouseId: 'main',
        ),
      );
    }

    state = state.copyWith(
      jobWorkOrders: [...state.jobWorkOrders, order],
      products: updatedProducts,
      stockMovements: newMovements,
    );

    final notif = NotificationModel(
      id: 'not_jw_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Job Work Sent',
      description: 'Job Work sent to ${order.jobWorkerName}: ${order.quantitySent} units of ${order.rawMaterialName}.',
      timestamp: DateTime.now(),
      isRead: false,
    );
    state = state.copyWith(notifications: [...state.notifications, notif]);

    _writeAuditLog('Create Job Work', 'JobWorkOrder', order.id, '', 'Status: SENT');
  }

  Future<void> receiveJobWork(String orderId, double receivedQty, double scrapQty) async {
    final index = state.jobWorkOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = state.jobWorkOrders[index];

    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);
    final pIdx = updatedProducts.indexWhere((p) => p.id == order.finishedProductId);
    if (pIdx != -1) {
      final prod = updatedProducts[pIdx];
      final Map<String, double> updatedWarehouseStocks = Map.from(prod.warehouseStocks);
      final double currentStock = updatedWarehouseStocks['main'] ?? 0.0;
      updatedWarehouseStocks['main'] = currentStock + receivedQty;
      updatedProducts[pIdx] = prod.copyWith(
        currentStock: prod.currentStock + receivedQty,
        warehouseStocks: updatedWarehouseStocks,
      );
      newMovements.add(
        StockMovement(
          id: 'sm_jw_recv_${order.id}',
          productId: order.finishedProductId,
          productName: order.finishedProductName,
          quantity: receivedQty,
          type: StockMovementType.adjustment,
          date: DateTime.now(),
          referenceNumber: 'JOBWORK-RECEIVE-${order.reference}',
          warehouseId: 'main',
        ),
      );
    }

    final double totalRecv = order.receivedFinishedQuantity + receivedQty;
    final double totalScrap = order.scrapQuantity + scrapQty;
    JobWorkStatus newStatus = order.status;
    if (totalRecv >= order.expectedFinishedQuantity) {
      newStatus = JobWorkStatus.completed;
    } else {
      newStatus = JobWorkStatus.partiallyReceived;
    }

    final updated = order.copyWith(
      receivedFinishedQuantity: totalRecv,
      scrapQuantity: totalScrap,
      status: newStatus,
    );

    state = state.copyWith(
      jobWorkOrders: state.jobWorkOrders.map((o) => o.id == orderId ? updated : o).toList(),
      products: updatedProducts,
      stockMovements: newMovements,
    );

    _writeAuditLog('Receive Job Work', 'JobWorkOrder', orderId, 'Status: SENT', 'Status: ${newStatus.displayName}');
  }

  // --- Phase 2: Operations Support Methods ---
  
  void _writeAuditLog(String action, String entity, String entityId, String prev, String next) {
    String user = 'system@taxbunny.com';
    try {
      final biz = _ref.read(businessProvider);
      if (biz.activeBusiness?.id != null) {
        user = 'owner@taxbunny.com';
      }
    } catch (_) {
      // Fallback for test zones
    }

    final entry = AuditLogEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}_${state.auditLogs.length}',
      user: user,
      action: action,
      entity: entity,
      entityId: entityId,
      previousValue: prev,
      newValue: next,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(auditLogs: [...state.auditLogs, entry]);
  }

  Future<void> addWarehouse(Warehouse w) async {
    state = state.copyWith(warehouses: [...state.warehouses, w]);
    _writeAuditLog('Create Warehouse', 'Warehouse', w.id, '', 'Name: ${w.name}');
  }

  Future<void> updateWarehouse(Warehouse w) async {
    final oldW = state.warehouses.firstWhere((item) => item.id == w.id);
    state = state.copyWith(
      warehouses: state.warehouses.map((item) => item.id == w.id ? w : item).toList(),
    );
    _writeAuditLog('Update Warehouse', 'Warehouse', w.id, 'Name: ${oldW.name}', 'Name: ${w.name}');
  }

  Future<void> transferStock(StockTransfer st) async {
    state = state.copyWith(stockTransfers: [...state.stockTransfers, st]);
    _writeAuditLog('Initiate Stock Transfer', 'StockTransfer', st.id, '', 'Status: ${st.status.displayName}');
    if (st.status == StockTransferStatus.confirmed) {
      await _processStockTransferConfirmation(st);
    }
  }

  Future<void> confirmTransfer(String id) async {
    final index = state.stockTransfers.indexWhere((st) => st.id == id);
    if (index == -1) return;
    final st = state.stockTransfers[index];
    if (st.status != StockTransferStatus.draft) return;
    final confirmedSt = st.copyWith(status: StockTransferStatus.confirmed);
    state = state.copyWith(
      stockTransfers: state.stockTransfers.map((item) => item.id == id ? confirmedSt : item).toList(),
    );
    _writeAuditLog('Confirm Stock Transfer', 'StockTransfer', id, 'Status: DRAFT', 'Status: CONFIRMED');
    await _processStockTransferConfirmation(confirmedSt);
  }

  Future<void> _processStockTransferConfirmation(StockTransfer st) async {
    final List<Product> updatedProducts = List.from(state.products);
    final List<StockMovement> newMovements = List.from(state.stockMovements);

    for (var item in st.items) {
      final prodIndex = updatedProducts.indexWhere((p) => p.id == item.productId);
      if (prodIndex != -1) {
        final prod = updatedProducts[prodIndex];
        
        // Decrement from source
        final Map<String, double> updatedSourceStocks = Map.from(prod.warehouseStocks);
        final double existingSourceStock = updatedSourceStocks[st.sourceWarehouseId] ?? (st.sourceWarehouseId == 'main' ? prod.currentStock : 0.0);
        updatedSourceStocks[st.sourceWarehouseId] = existingSourceStock - item.quantity;
        
        // Increment in destination
        final Map<String, double> updatedDestStocks = Map.from(updatedSourceStocks);
        final double existingDestStock = updatedDestStocks[st.destinationWarehouseId] ?? (st.destinationWarehouseId == 'main' ? prod.currentStock : 0.0);
        updatedDestStocks[st.destinationWarehouseId] = existingDestStock + item.quantity;

        final updatedProd = prod.copyWith(
          warehouseStocks: updatedDestStocks,
        );
        updatedProducts[prodIndex] = updatedProd;

        // Log Stock Movements for both warehouses
        newMovements.add(
          StockMovement(
            id: 'sm_tr_src_${st.id}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            quantity: -item.quantity,
            type: StockMovementType.adjustment,
            date: st.transferDate,
            referenceNumber: 'TRANSFER-OUT-${st.referenceNumber}',
            warehouseId: st.sourceWarehouseId,
          ),
        );
        newMovements.add(
          StockMovement(
            id: 'sm_tr_dest_${st.id}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            type: StockMovementType.adjustment,
            date: st.transferDate,
            referenceNumber: 'TRANSFER-IN-${st.referenceNumber}',
            warehouseId: st.destinationWarehouseId,
          ),
        );
      }
    }
    state = state.copyWith(
      products: updatedProducts,
      stockMovements: newMovements,
    );
  }

  Future<void> addRecurringSchedule(RecurringSchedule rs) async {
    state = state.copyWith(recurringSchedules: [...state.recurringSchedules, rs]);
    _writeAuditLog('Create Recurring Schedule', 'RecurringSchedule', rs.id, '', 'Status: ${rs.status.displayName}');
  }

  Future<void> updateRecurringSchedule(RecurringSchedule rs) async {
    final oldRs = state.recurringSchedules.firstWhere((item) => item.id == rs.id);
    state = state.copyWith(
      recurringSchedules: state.recurringSchedules.map((item) => item.id == rs.id ? rs : item).toList(),
    );
    _writeAuditLog('Update Recurring Schedule', 'RecurringSchedule', rs.id, 'Status: ${oldRs.status.displayName}', 'Status: ${rs.status.displayName}');
  }

  Future<void> triggerRecurringBillingRun() async {
    final now = DateTime.now();
    final List<RecurringSchedule> updatedSchedules = List.from(state.recurringSchedules);
    final List<Invoice> generatedInvoices = List.from(state.invoices);
    int generatedCount = 0;

    for (int i = 0; i < updatedSchedules.length; i++) {
      final schedule = updatedSchedules[i];
      if (schedule.status == RecurringScheduleStatus.active &&
          schedule.nextBillingDate.isBefore(now)) {
        
        // Generate Invoice
        final double taxable = schedule.items.fold(0.0, (sum, item) => sum + item.taxableValue);
        final double cgst = schedule.items.fold(0.0, (sum, item) => sum + item.cgst);
        final double sgst = schedule.items.fold(0.0, (sum, item) => sum + item.sgst);
        final double igst = schedule.items.fold(0.0, (sum, item) => sum + item.igst);
        final double grand = taxable + cgst + sgst + igst;

        final invoice = Invoice(
          id: 'inv_rec_${schedule.id}_${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: 'INV-REC-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-${generatedInvoices.length}',
          invoiceDate: DateTime.now(),
          customerId: schedule.customerId,
          customerName: schedule.customerName,
          billingAddress: 'Billing address of customer',
          shippingAddress: 'Shipping address of customer',
          placeOfSupply: 'State of Supply',
          items: schedule.items,
          taxableAmount: taxable,
          cgst: cgst,
          sgst: sgst,
          igst: igst,
          cess: 0.0,
          roundOff: 0.0,
          grandTotal: grand,
          balanceAmount: grand,
          paymentMode: 'Bank Transfer',
          status: InvoiceStatus.confirmed, // Auto confirmed
          notes: 'Auto generated invoice from recurring schedule: ${schedule.notes}',
          termsConditions: 'Auto generated standard terms.',
          warehouseId: 'main',
        );

        generatedInvoices.add(invoice);
        generatedCount++;

        // Update next billing date based on frequency
        DateTime nextDate;
        switch (schedule.frequency) {
          case RecurringFrequency.monthly:
            nextDate = schedule.nextBillingDate.add(const Duration(days: 30));
            break;
          case RecurringFrequency.quarterly:
            nextDate = schedule.nextBillingDate.add(const Duration(days: 90));
            break;
          case RecurringFrequency.halfYearly:
            nextDate = schedule.nextBillingDate.add(const Duration(days: 180));
            break;
          case RecurringFrequency.yearly:
            nextDate = schedule.nextBillingDate.add(const Duration(days: 365));
            break;
          case RecurringFrequency.custom:
            nextDate = schedule.nextBillingDate.add(Duration(days: schedule.customFrequencyDays));
            break;
        }

        updatedSchedules[i] = schedule.copyWith(
          lastBillingDate: now,
          nextBillingDate: nextDate,
          status: nextDate.isAfter(schedule.endDate)
              ? RecurringScheduleStatus.expired
              : schedule.status,
        );

        // Confirm the auto-generated invoice to update stock & ledger
        await _processInvoiceConfirmation(invoice);
      }
    }

    if (generatedCount > 0) {
      state = state.copyWith(
        invoices: generatedInvoices,
        recurringSchedules: updatedSchedules,
      );
      _writeAuditLog('Recurring Billing Run', 'Scheduler', 'System', 'Schedules Run', '$generatedCount invoices generated');
    }
  }

  Future<void> openPOSSession(double openingCash) async {
    final session = POSSession(
      id: 'pos_session_${DateTime.now().millisecondsSinceEpoch}',
      openingCash: openingCash,
      closingCash: 0.0,
      openingTime: DateTime.now(),
      status: POSSessionStatus.open,
    );
    state = state.copyWith(activePOSSession: () => session);
    _writeAuditLog('Open POS Register', 'POSSession', session.id, '', 'Opening Cash: ₹$openingCash');
  }

  Future<void> closePOSSession(double closingCash) async {
    if (state.activePOSSession == null) return;
    final closed = state.activePOSSession!.copyWith(
      closingCash: closingCash,
      closingTime: DateTime.now(),
      status: POSSessionStatus.closed,
    );
    state = state.copyWith(activePOSSession: () => null);
    _writeAuditLog('Close POS Register', 'POSSession', closed.id, 'Status: OPEN', 'Status: CLOSED, Closing Cash: ₹$closingCash');
  }

  Future<void> holdPOSCart(Invoice invoice) async {
    state = state.copyWith(heldPOSCarts: [...state.heldPOSCarts, invoice]);
    _writeAuditLog('Hold POS Cart', 'POSCart', invoice.id, '', 'Hold Invoice: ${invoice.invoiceNumber}');
  }

  Future<void> resumePOSCart(String cartId) async {
    state = state.copyWith(
      heldPOSCarts: state.heldPOSCarts.where((inv) => inv.id != cartId).toList(),
    );
    _writeAuditLog('Resume POS Cart', 'POSCart', cartId, '', 'Resumed cart');
  }

  Future<void> deleteHeldPOSCart(String cartId) async {
    state = state.copyWith(
      heldPOSCarts: state.heldPOSCarts.where((inv) => inv.id != cartId).toList(),
    );
    _writeAuditLog('Cancel Held POS Cart', 'POSCart', cartId, '', 'Cancelled cart');
  }

  Future<void> updateInvoiceBranding(InvoiceBrandingConfig config) async {
    state = state.copyWith(invoiceBrandingConfig: config);
    _writeAuditLog('Update Invoice Branding', 'Branding', 'Settings', 'Old configuration', 'Updated branding settings');
  }

  Future<void> inviteUser(Map<String, dynamic> user) async {
    state = state.copyWith(customUsers: [...state.customUsers, user]);
    _writeAuditLog('Invite User', 'UserManagement', user['email'] ?? 'unknown', '', 'Role: ${user['role']}');
  }

  Future<void> updateUserPermissions(String email, String role, Map<String, bool> permissions) async {
    final updated = state.customUsers.map((user) {
      if (user['email'] == email) {
        return {
          'name': user['name'],
          'email': email,
          'role': role,
          'permissions': permissions,
        };
      }
      return user;
    }).toList();
    state = state.copyWith(customUsers: updated);
    _writeAuditLog('Update User Permissions', 'UserManagement', email, '', 'Updated role/permissions');
  }
}

final billingRepositoryProvider = StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier(ref);
});

List<Account> _getDefaultAccounts(String bizId) {
  final now = DateTime.now();
  return [
    Account(id: 'acc_cash', businessId: bizId, code: '1000', name: 'Cash Account', type: AccountType.asset, groupName: 'Current Assets', isSystemAccount: true, isActive: true, openingDebit: 15000.0, openingCredit: 0.0, currentBalance: 15000.0, createdAt: now),
    Account(id: 'acc_bank', businessId: bizId, code: '1001', name: 'Bank Account (Bunny Central)', type: AccountType.asset, groupName: 'Bank Accounts', isSystemAccount: true, isActive: true, openingDebit: 250000.0, openingCredit: 0.0, currentBalance: 250000.0, createdAt: now),
    Account(id: 'acc_ar', businessId: bizId, code: '1100', name: 'Accounts Receivable', type: AccountType.asset, groupName: 'Current Assets', isSystemAccount: true, isActive: true, openingDebit: 32500.0, openingCredit: 0.0, currentBalance: 32500.0, createdAt: now),
    Account(id: 'acc_ap', businessId: bizId, code: '2100', name: 'Accounts Payable', type: AccountType.liability, groupName: 'Current Liabilities', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 65800.0, currentBalance: -65800.0, createdAt: now),
    Account(id: 'acc_sales', businessId: bizId, code: '4000', name: 'Sales Revenue', type: AccountType.income, groupName: 'Revenue', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_purchases', businessId: bizId, code: '5000', name: 'Direct Purchases', type: AccountType.expense, groupName: 'Cost of Goods Sold', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_input_gst', businessId: bizId, code: '1200', name: 'GST Input Tax Credit', type: AccountType.asset, groupName: 'Current Assets', isSystemAccount: true, isActive: true, openingDebit: 5000.0, openingCredit: 0.0, currentBalance: 5000.0, createdAt: now),
    Account(id: 'acc_output_gst', businessId: bizId, code: '2200', name: 'GST Output Tax Liability', type: AccountType.liability, groupName: 'Current Liabilities', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 3500.0, currentBalance: -3500.0, createdAt: now),
    Account(id: 'acc_raw_stock', businessId: bizId, code: '1300', name: 'Raw Material Stock', type: AccountType.asset, groupName: 'Inventory', isSystemAccount: true, isActive: true, openingDebit: 45000.0, openingCredit: 0.0, currentBalance: 45000.0, createdAt: now),
    Account(id: 'acc_finished_stock', businessId: bizId, code: '1350', name: 'Finished Goods Stock', type: AccountType.asset, groupName: 'Inventory', isSystemAccount: true, isActive: true, openingDebit: 80000.0, openingCredit: 0.0, currentBalance: 80000.0, createdAt: now),
    Account(id: 'acc_labor', businessId: bizId, code: '5100', name: 'Production Labor Cost', type: AccountType.expense, groupName: 'Direct Expenses', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_overhead', businessId: bizId, code: '5200', name: 'Production Overhead', type: AccountType.expense, groupName: 'Direct Expenses', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_wastage', businessId: bizId, code: '5300', name: 'Production Wastage', type: AccountType.expense, groupName: 'Direct Expenses', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_scrap', businessId: bizId, code: '4200', name: 'Scrap Sales', type: AccountType.income, groupName: 'Other Income', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 0.0, currentBalance: 0.0, createdAt: now),
    Account(id: 'acc_capital', businessId: bizId, code: '3000', name: 'Capital Account', type: AccountType.equity, groupName: 'Capital', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 300000.0, currentBalance: -300000.0, createdAt: now),
    Account(id: 'acc_retained_earnings', businessId: bizId, code: '3100', name: 'Retained Earnings', type: AccountType.equity, groupName: 'Capital', isSystemAccount: true, isActive: true, openingDebit: 0.0, openingCredit: 16700.0, currentBalance: -16700.0, createdAt: now),
  ];
}

List<BankAccount> _getDefaultBankAccounts(String bizId) {
  return [
    BankAccount(
      id: 'bank_01',
      businessId: bizId,
      bankName: 'Bunny Central Bank',
      accountName: 'Primary Operating Account',
      accountNumber: '1234567890',
      ifsc: 'BCB0001234',
      branch: 'Bunnyland Central',
      accountType: 'Current',
      openingBalance: 250000.0,
      currentBalance: 250000.0,
      isActive: true,
    ),
    BankAccount(
      id: 'bank_02',
      businessId: bizId,
      bankName: 'Federal Salad Bank',
      accountName: 'Secondary Reserve Account',
      accountNumber: '9876543210',
      ifsc: 'FSB0009876',
      branch: 'Carrot District',
      accountType: 'Savings',
      openingBalance: 100000.0,
      currentBalance: 100000.0,
      isActive: true,
    ),
  ];
}

List<AccountingPeriod> _getDefaultPeriods(String bizId) {
  return [
    AccountingPeriod(
      id: 'per_01',
      businessId: bizId,
      name: 'FY 2026-27',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2027, 3, 31),
      status: PeriodStatus.open,
    ),
  ];
}

List<BOM> _getDefaultBOMs(String bizId) {
  return [
    BOM(
      id: 'bom_01',
      businessId: bizId,
      finishedProductId: 'prod_finished_01',
      finishedProductName: 'Premium Farm Bread (400g)',
      version: 'v1.0',
      items: [
        BOMItem(productId: 'prod_raw_01', productName: 'Wheat Grain (Raw)', quantity: 0.5, unit: 'Kg', wastagePercentage: 2.0),
        BOMItem(productId: 'prod_raw_02', productName: 'Baking Yeast Additives', quantity: 0.05, unit: 'Kg', wastagePercentage: 5.0),
      ],
      notes: 'Standard recipe for farm bread.',
      isActive: true,
    ),
  ];
}

List<NotificationModel> _getDefaultNotifications() {
  return [
    NotificationModel(
      id: 'not_01',
      title: 'Subscription Renewal Warning',
      description: 'Your trial plan expires in 2 days. Upgrade to Premium to avoid service limits.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationModel(
      id: 'not_02',
      title: 'Low Stock Alert',
      description: 'Product "Premium Tax Booklets" has fallen below the safety stock margin of 10 items.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
    ),
  ];
}
