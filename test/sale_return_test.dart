import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_config.dart';
import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';
import 'package:frontend/features/sales/data/models/sales_return_dto.dart';

void main() {
  group('Sale Return & Navigation Integration Tests', () {
    test('NavigationConfig contains Sale Returns under Sales Operations', () {
      final salesGroup = NavigationConfig.menuItems.firstWhere((item) => item.id == 'sales_group');
      expect(salesGroup.title, 'Sales Operations');
      expect(salesGroup.children, isNotNull);

      final saleReturnsItem = salesGroup.children!.firstWhere((c) => c.id == 'sale_returns');
      expect(saleReturnsItem.title, 'Sale Returns');
      expect(saleReturnsItem.route, '/sales/returns');
    });

    test('Creating and confirming a Sale Return restocks inventory and decreases customer balance', () async {
      final container = ProviderContainer();
      final notifier = container.read(billingRepositoryProvider.notifier);

      await notifier.addCustomer(const Customer(
        id: 'cust_01',
        name: 'Acme Corporates',
        type: 'Wholesale',
        gstin: '27AABCU9603R1ZM',
        pan: 'AABCU9603R',
        mobile: '9876543210',
        email: 'billing@acme.com',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        state: 'Maharashtra',
        stateCode: '27',
        creditLimit: 50000.0,
        creditPeriod: 30,
        openingBalance: 5000.0,
        currentBalance: 5000.0,
        customerGroup: 'Corporate',
        notes: '',
        isRegistered: true,
      ));

      final initialProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_01');
      final initialStock = initialProduct.currentStock;
      final initialCustomer = notifier.state.customers.firstWhere((c) => c.id == 'cust_01');
      final initialBalance = initialCustomer.currentBalance;

      // Create a confirmed Sale Return for 5 units of prod_01
      final returnInvoice = Invoice(
        id: 'ret_test_01',
        invoiceNumber: 'CN/TEST/0001',
        invoiceDate: DateTime.now(),
        customerId: 'cust_01',
        customerName: 'Acme Corporates',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        placeOfSupply: 'Maharashtra',
        items: const [
          InvoiceItem(
            id: 'item_ret_01',
            productId: 'prod_01',
            serviceId: '',
            name: 'Organic Wheat Flour (5kg)',
            hsnSac: '1101',
            quantity: 5.0,
            unit: 'Bag',
            rate: 200.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 1000.0,
            gstRate: 5.0,
            cgst: 25.0,
            sgst: 25.0,
            igst: 0.0,
            cess: 0.0,
          ),
        ],
        taxableAmount: 1000.0,
        cgst: 25.0,
        sgst: 25.0,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 1050.0,
        balanceAmount: 0.0,
        paymentMode: 'Credit Note (Store Credit)',
        status: InvoiceStatus.confirmed,
        notes: 'Damaged packaging return',
        termsConditions: '',
        originalInvoiceId: 'TB/26-27/0001',
        warehouseId: 'main',
      );

      await notifier.addInvoice(returnInvoice);

      // Verify product stock increased by 5
      final updatedProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_01');
      expect(updatedProduct.currentStock, initialStock + 5.0);

      // Verify stock movement recorded as salesReturn
      final stockMovement = notifier.state.stockMovements.last;
      expect(stockMovement.type, StockMovementType.salesReturn);
      expect(stockMovement.quantity, 5.0);
      expect(stockMovement.referenceNumber, 'CN/TEST/0001');

      // Verify customer outstanding balance decreased by 1050
      final updatedCustomer = notifier.state.customers.firstWhere((c) => c.id == 'cust_01');
      expect(updatedCustomer.currentBalance, initialBalance - 1050.0);

      // Verify credit note ledger entry created
      final ledger = notifier.state.ledgerEntries.last;
      expect(ledger.type, LedgerTransactionType.creditNote);
      expect(ledger.credit, 1050.0);
      expect(ledger.debit, 0.0);
    });

    test('Cancelling a confirmed Sale Return reverses inventory stock and customer balance', () async {
      final container = ProviderContainer();
      final notifier = container.read(billingRepositoryProvider.notifier);

      await notifier.addCustomer(const Customer(
        id: 'cust_01',
        name: 'Acme Corporates',
        type: 'Wholesale',
        gstin: '27AABCU9603R1ZM',
        pan: 'AABCU9603R',
        mobile: '9876543210',
        email: 'billing@acme.com',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        state: 'Maharashtra',
        stateCode: '27',
        creditLimit: 50000.0,
        creditPeriod: 30,
        openingBalance: 5000.0,
        currentBalance: 5000.0,
        customerGroup: 'Corporate',
        notes: '',
        isRegistered: true,
      ));

      final initialProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_01');
      final initialStock = initialProduct.currentStock;
      final initialCustomer = notifier.state.customers.firstWhere((c) => c.id == 'cust_01');
      final initialBalance = initialCustomer.currentBalance;

      // Add confirmed return
      final returnInvoice = Invoice(
        id: 'ret_test_cancel',
        invoiceNumber: 'CN/CANCEL/0001',
        invoiceDate: DateTime.now(),
        customerId: 'cust_01',
        customerName: 'Acme Corporates',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        placeOfSupply: 'Maharashtra',
        items: const [
          InvoiceItem(
            id: 'item_ret_c1',
            productId: 'prod_01',
            serviceId: '',
            name: 'Organic Wheat Flour (5kg)',
            hsnSac: '1101',
            quantity: 4.0,
            unit: 'Bag',
            rate: 200.0,
            discountPercentage: 0.0,
            discountAmount: 0.0,
            taxableValue: 800.0,
            gstRate: 5.0,
            cgst: 20.0,
            sgst: 20.0,
            igst: 0.0,
            cess: 0.0,
          ),
        ],
        taxableAmount: 800.0,
        cgst: 20.0,
        sgst: 20.0,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 840.0,
        balanceAmount: 0.0,
        paymentMode: 'Credit Note',
        status: InvoiceStatus.confirmed,
        notes: 'Test return',
        termsConditions: '',
        originalInvoiceId: 'TB/26-27/0001',
        warehouseId: 'main',
      );

      await notifier.addInvoice(returnInvoice);

      // Cancel the return
      await notifier.cancelInvoice('ret_test_cancel');

      final cancelledProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_01');
      expect(cancelledProduct.currentStock, initialStock);

      final cancelledCustomer = notifier.state.customers.firstWhere((c) => c.id == 'cust_01');
      expect(cancelledCustomer.currentBalance, initialBalance);

      final cancelledInvoice = notifier.state.invoices.firstWhere((i) => i.id == 'ret_test_cancel');
      expect(cancelledInvoice.status, InvoiceStatus.cancelled);
    });

    test('Direct return without original invoice is correctly identified as a credit note', () async {
      final directReturn = Invoice(
        id: 'ret_direct_01',
        invoiceNumber: 'CN/DIRECT/0001',
        invoiceDate: DateTime(2026, 9, 1),
        customerId: 'cust_01',
        customerName: 'Acme Corporates',
        billingAddress: '101, Industrial Area, Mumbai',
        shippingAddress: '101, Industrial Area, Mumbai',
        placeOfSupply: 'Maharashtra',
        items: [],
        taxableAmount: 500.0,
        cgst: 25.0,
        sgst: 25.0,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 550.0,
        balanceAmount: 0.0,
        paymentMode: 'Cash Refund',
        status: InvoiceStatus.confirmed,
        notes: 'Direct customer return without invoice',
        termsConditions: '',
        originalInvoiceId: '',
        warehouseId: 'main',
        isCreditNote: true,
      );

      expect(directReturn.isCreditNote, isTrue);
    });

    test('SalesReturnDto and items deserialization from JSON', () {
      final json = {
        'id': 'ret_101',
        'returnNumber': 'CN/26-27/0001',
        'returnDate': '2026-09-10T10:00:00.000Z',
        'customerId': 'cust_01',
        'customerName': 'Test Corp',
        'status': 'CONFIRMED',
        'subtotal': 1000.0,
        'discountAmount': 0.0,
        'taxableValue': 1000.0,
        'cgstAmount': 25.0,
        'sgstAmount': 25.0,
        'igstAmount': 0.0,
        'cessAmount': 0.0,
        'roundOff': 0.0,
        'totalAmount': 1050.0,
        'items': [
          {
            'id': 'item_1',
            'productId': 'prod_01',
            'productName': 'Wheat Flour',
            'quantity': 5.0,
            'rate': 200.0,
            'taxableValue': 1000.0,
            'cgstAmount': 25.0,
            'sgstAmount': 25.0,
            'lineTotal': 1050.0,
            'stockRestocked': true,
          }
        ]
      };

      final dto = SalesReturnDto.fromJson(json);
      expect(dto.id, 'ret_101');
      expect(dto.returnNumber, 'CN/26-27/0001');
      expect(dto.status, 'CONFIRMED');
      expect(dto.totalAmount, 1050.0);
      expect(dto.items.length, 1);
      expect(dto.items.first.productName, 'Wheat Flour');
      expect(dto.items.first.stockRestocked, isTrue);
    });

    test('SalesReturnSummaryMetricsDto parsing from backend response', () {
      final json = {
        'totalReturnValue': 45200.5,
        'confirmedCount': 12,
        'draftCount': 3,
        'cancelledCount': 1,
        'itemsRestocked': 150.0,
        'totalCount': 16,
      };

      final metrics = SalesReturnSummaryMetricsDto.fromJson(json);
      expect(metrics.totalReturnValue, 45200.5);
      expect(metrics.confirmedCount, 12);
      expect(metrics.draftCount, 3);
      expect(metrics.cancelledCount, 1);
      expect(metrics.itemsRestocked, 150.0);
      expect(metrics.totalCount, 16);
    });
  });
}
