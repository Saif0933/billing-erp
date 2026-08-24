import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/core/services/gst_calculation_service.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';

void main() {
  group('GST Engine Calculations', () {
    test('Intra-state supply (CGST 5% + SGST 5% on 10% total)', () {
      final res = GstCalculationService.calculate(
        quantity: 2,
        rate: 500,
        discountPercentage: 10,
        gstRate: 10,
        businessStateCode: '27', // Maharashtra
        placeOfSupplyStateCode: '27', // Maharashtra
        customerGstType: 'Regular',
      );

      // gross = 1000, discount = 100, taxable = 900
      expect(res.taxableValue, 900.0);
      expect(res.cgstAmount, 45.0); // 4.5% of 900
      expect(res.sgstAmount, 45.0); // 4.5% of 900
      expect(res.igstAmount, 0.0);
      expect(res.grandTotal, 990.0);
    });

    test('Inter-state supply (IGST 18% on total)', () {
      final res = GstCalculationService.calculate(
        quantity: 1,
        rate: 1000,
        discountPercentage: 0,
        gstRate: 18,
        businessStateCode: '27', // Maharashtra
        placeOfSupplyStateCode: '29', // Karnataka
        customerGstType: 'Regular',
      );

      expect(res.taxableValue, 1000.0);
      expect(res.cgstAmount, 0.0);
      expect(res.sgstAmount, 0.0);
      expect(res.igstAmount, 180.0);
      expect(res.grandTotal, 1180.0);
    });
  });

  group('Atomic Transactions & Ledgers', () {
    late ProviderContainer container;
    late BillingNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(billingRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Confirming draft invoice updates inventory stock levels and customer ledgers', () async {
      // 1. Initial State checks
      final initialCustBalance = notifier.state.customers.first.currentBalance;
      final initialProductStock = notifier.state.products.first.currentStock;

      // Create a draft invoice
      final item = InvoiceItem(
        id: 'item_1',
        productId: notifier.state.products.first.id,
        serviceId: '',
        name: notifier.state.products.first.name,
        hsnSac: 'HSN1',
        quantity: 2,
        unit: 'Pcs',
        rate: notifier.state.products.first.sellingPrice,
        discountPercentage: 0,
        discountAmount: 0,
        taxableValue: notifier.state.products.first.sellingPrice * 2,
        gstRate: 18,
        cgst: (notifier.state.products.first.sellingPrice * 2) * 0.09,
        sgst: (notifier.state.products.first.sellingPrice * 2) * 0.09,
        igst: 0,
        cess: 0,
      );

      final total = item.taxableValue + item.cgst + item.sgst;

      final invoice = Invoice(
        id: 'inv_test_1',
        invoiceNumber: 'INV-TEST-001',
        invoiceDate: DateTime.now(),
        customerId: notifier.state.customers.first.id,
        customerName: notifier.state.customers.first.name,
        billingAddress: 'Address',
        shippingAddress: 'Address',
        placeOfSupply: 'Maharashtra',
        items: [item],
        taxableAmount: item.taxableValue,
        cgst: item.cgst,
        sgst: item.sgst,
        igst: 0,
        cess: 0,
        roundOff: 0,
        grandTotal: total,
        balanceAmount: total,
        paymentMode: 'Bank',
        status: InvoiceStatus.draft,
        notes: '',
        termsConditions: '',
      );

      await notifier.addInvoice(invoice);

      // Draft invoice shouldn't affect stock or balances yet
      expect(notifier.state.products.first.currentStock, initialProductStock);
      expect(notifier.state.customers.first.currentBalance, initialCustBalance);

      // 2. Confirm invoice
      await notifier.confirmInvoice('inv_test_1');

      // Now stock should decrease and customer balance should increase
      expect(notifier.state.products.first.currentStock, initialProductStock - 2);
      expect(notifier.state.customers.first.currentBalance, initialCustBalance + total);

      // Confirm ledger entry is recorded
      final salesLedgerEntry = notifier.state.ledgerEntries.firstWhere((e) => e.referenceNumber == 'INV-TEST-001');
      expect(salesLedgerEntry.debit, total);
    });

    test('Receipt allocation updates invoice outstanding balance and ledger credit entries', () async {
      // Setup a confirmed invoice
      final item = InvoiceItem(
        id: 'item_2',
        productId: notifier.state.products.first.id,
        serviceId: '',
        name: notifier.state.products.first.name,
        hsnSac: 'HSN1',
        quantity: 1,
        unit: 'Pcs',
        rate: 1000,
        discountPercentage: 0,
        discountAmount: 0,
        taxableValue: 1000,
        gstRate: 0,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
      );

      final invoice = Invoice(
        id: 'inv_test_2',
        invoiceNumber: 'INV-TEST-002',
        invoiceDate: DateTime.now(),
        customerId: notifier.state.customers.first.id,
        customerName: notifier.state.customers.first.name,
        billingAddress: 'Address',
        shippingAddress: 'Address',
        placeOfSupply: 'Maharashtra',
        items: [item],
        taxableAmount: 1000,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
        roundOff: 0,
        grandTotal: 1000,
        balanceAmount: 1000,
        paymentMode: 'Bank',
        status: InvoiceStatus.confirmed,
        notes: '',
        termsConditions: '',
      );

      await notifier.addInvoice(invoice);
      await notifier.confirmInvoice('inv_test_2');

      // Initial state checks
      final invoicePrePay = notifier.state.invoices.firstWhere((i) => i.id == 'inv_test_2');
      expect(invoicePrePay.balanceAmount, 1000.0);
      expect(invoicePrePay.status, InvoiceStatus.confirmed);

      // Register Receipt of 600
      final receipt = Receipt(
        id: 'rec_test_1',
        customerId: notifier.state.customers.first.id,
        customerName: notifier.state.customers.first.name,
        amount: 600,
        date: DateTime.now(),
        paymentMode: 'UPI',
        referenceNumber: 'TXN-REC-001',
        notes: 'Partial payment',
        allocations: [
          ReceiptAllocation(invoiceId: 'inv_test_2', amountAllocated: 600),
        ],
      );

      await notifier.addReceipt(receipt);

      final invoicePostPay = notifier.state.invoices.firstWhere((i) => i.id == 'inv_test_2');
      expect(invoicePostPay.balanceAmount, 400.0);
      expect(invoicePostPay.status, InvoiceStatus.partiallyPaid);

      // Verify general ledger shows credit entry for the payment
      final ledgerCreditEntry = notifier.state.ledgerEntries.firstWhere((e) => e.referenceNumber == 'TXN-REC-001');
      expect(ledgerCreditEntry.credit, 600.0);
    });
  });
}
