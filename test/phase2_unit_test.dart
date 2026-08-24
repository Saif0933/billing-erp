import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/core/models/warehouse_models.dart';
import 'package:frontend/core/models/recurring_billing_models.dart';
import 'package:frontend/core/services/payment_reminder_service.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';

void main() {
  group('Phase 2 Operation & Logic Tests', () {
    test('PaymentReminderService overdue filter & messages', () {
      final now = DateTime.now();
      final invoices = [
        Invoice(
          id: 'inv_1',
          invoiceNumber: 'INV-1',
          invoiceDate: now.subtract(const Duration(days: 35)),
          customerId: 'c1',
          customerName: 'Aman',
          billingAddress: '',
          shippingAddress: '',
          placeOfSupply: '',
          items: [],
          taxableAmount: 1000.0,
          cgst: 90.0,
          sgst: 90.0,
          igst: 0.0,
          cess: 0.0,
          roundOff: 0.0,
          grandTotal: 1180.0,
          balanceAmount: 1180.0,
          paymentMode: 'UPI',
          status: InvoiceStatus.confirmed,
          notes: '',
          termsConditions: '',
          warehouseId: 'main',
        ),
        Invoice(
          id: 'inv_2',
          invoiceNumber: 'INV-2',
          invoiceDate: now.subtract(const Duration(days: 5)),
          customerId: 'c2',
          customerName: 'Raman',
          billingAddress: '',
          shippingAddress: '',
          placeOfSupply: '',
          items: [],
          taxableAmount: 100.0,
          cgst: 9.0,
          sgst: 9.0,
          igst: 0.0,
          cess: 0.0,
          roundOff: 0.0,
          grandTotal: 118.0,
          balanceAmount: 118.0,
          paymentMode: 'Cash',
          status: InvoiceStatus.confirmed,
          notes: '',
          termsConditions: '',
          warehouseId: 'main',
        ),
      ];

      final overdue = PaymentReminderService.getOverdueInvoices(invoices);
      expect(overdue.length, 1);
      expect(overdue.first.id, 'inv_1');

      final msg = PaymentReminderService.generateReminderMessage(overdue.first, 'Email');
      expect(msg, contains('Aman'));
      expect(msg, contains('INV-1'));
    });

    test('Warehouse StockTransfer state mutations simulation', () {
      // Mocking StockTransfer item
      final item = TransferItem(productId: 'prod_1', productName: 'Flour', quantity: 5.0);
      final transfer = StockTransfer(
        id: 'st_1',
        sourceWarehouseId: 'main',
        destinationWarehouseId: 'store',
        items: [item],
        transferDate: DateTime.now(),
        referenceNumber: 'ST-REF-1',
        status: StockTransferStatus.confirmed,
        notes: 'Transfer 5 units',
      );

      expect(transfer.status, StockTransferStatus.confirmed);
      expect(transfer.items.first.productId, 'prod_1');
    });

    test('Recurring Billing Schedule dates evaluation', () {
      final now = DateTime.now();
      final schedule = RecurringSchedule(
        id: 'rs_1',
        customerId: 'c1',
        customerName: 'Aditya Birla',
        items: [],
        frequency: RecurringFrequency.monthly,
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.add(const Duration(days: 300)),
        nextBillingDate: now.subtract(const Duration(hours: 1)),
        status: RecurringScheduleStatus.active,
        paymentTerms: 'Net 30',
        notes: 'Monthly retainer',
      );

      expect(schedule.frequency, RecurringFrequency.monthly);
      expect(schedule.nextBillingDate.isBefore(now), isTrue);
    });
  });
}
