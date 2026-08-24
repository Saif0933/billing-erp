import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/models/accounting_models.dart';
import 'package:frontend/core/models/manufacturing_models.dart';
import 'package:frontend/core/models/billing_models.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/dashboard/presentation/providers/billing_repository.dart';

void main() {
  group('Phase 3 Accounting & Manufacturing Integration Tests', () {
    late ProviderContainer container;
    late BillingNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      notifier = container.read(billingRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initializes state with mock accounting profiles & default BOM recipes', () {
      final state = notifier.state;

      expect(state.accounts.isNotEmpty, true);
      expect(state.bankAccounts.isNotEmpty, true);
      expect(state.accountingPeriods.isNotEmpty, true);
      expect(state.boms.isNotEmpty, true);

      final cashAcc = state.accounts.firstWhere((a) => a.id == 'acc_cash');
      expect(cashAcc.currentBalance, 15000.0);

      final breadBom = state.boms.firstWhere((b) => b.id == 'bom_01');
      expect(breadBom.finishedProductId, 'prod_finished_01');
      expect(breadBom.items.length, 2);
    });

    test('Double-Entry Posting Engine: Sales Invoice Confirmation & Cancellation', () async {
      final initialAR = notifier.state.accounts.firstWhere((a) => a.id == 'acc_ar').currentBalance;
      final initialSales = notifier.state.accounts.firstWhere((a) => a.id == 'acc_sales').currentBalance;

      final item = InvoiceItem(
        id: 'item_inv_1',
        productId: 'prod_finished_01',
        serviceId: '',
        name: 'Premium Farm Bread',
        hsnSac: '1905',
        quantity: 10,
        unit: 'Pcs',
        rate: 50.0,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        taxableValue: 500.0,
        gstRate: 18,
        cgst: 45.0,
        sgst: 45.0,
        igst: 0.0,
        cess: 0.0,
      );

      final invoice = Invoice(
        id: 'inv_acc_test',
        invoiceNumber: 'INV-ACC-001',
        invoiceDate: DateTime.now(),
        customerId: notifier.state.customers.first.id,
        customerName: notifier.state.customers.first.name,
        billingAddress: 'Address',
        shippingAddress: 'Address',
        placeOfSupply: 'Maharashtra',
        items: [item],
        taxableAmount: 500.0,
        cgst: 45.0,
        sgst: 45.0,
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: 590.0,
        balanceAmount: 590.0,
        paymentMode: 'UPI',
        status: InvoiceStatus.draft,
        notes: '',
        termsConditions: '',
        warehouseId: 'main',
      );

      await notifier.addInvoice(invoice);
      expect(notifier.state.journalEntries.any((je) => je.referenceId == invoice.id), false);

      await notifier.confirmInvoice(invoice.id);

      final journalEntries = notifier.state.journalEntries;
      final postedJe = journalEntries.firstWhere((je) => je.referenceId == invoice.id && je.status == JournalStatus.posted);
      
      expect(postedJe.narration, contains(invoice.invoiceNumber));
      
      final arLine = postedJe.lines.firstWhere((l) => l.accountId == 'acc_ar');
      expect(arLine.debit, 590.0);
      expect(arLine.credit, 0.0);

      final salesLine = postedJe.lines.firstWhere((l) => l.accountId == 'acc_sales');
      expect(salesLine.debit, 0.0);
      expect(salesLine.credit, 500.0);

      final updatedAR = notifier.state.accounts.firstWhere((a) => a.id == 'acc_ar').currentBalance;
      final updatedSales = notifier.state.accounts.firstWhere((a) => a.id == 'acc_sales').currentBalance;
      expect(updatedAR, initialAR + 590.0);
      expect(updatedSales, initialSales + 500.0);

      await notifier.cancelInvoice(invoice.id);
      
      final reversedJe = notifier.state.journalEntries.firstWhere((je) => je.narration.contains('Reversal Entry') && je.referenceId == invoice.id);
      expect(reversedJe.status, JournalStatus.posted);
      
      final reverseARLine = reversedJe.lines.firstWhere((l) => l.accountId == 'acc_ar');
      expect(reverseARLine.credit, 590.0);

      final restoredAR = notifier.state.accounts.firstWhere((a) => a.id == 'acc_ar').currentBalance;
      expect(restoredAR, initialAR);
    });

    test('Manufacturing Run Cost Computations & Inventory Ledger Postings', () async {
      final initialRawProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_raw_01');
      final initialFinishedProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_finished_01');

      expect(initialRawProduct.currentStock > 0.0, true);

      final activeBOM = notifier.state.boms.firstWhere((b) => b.id == 'bom_01');
      final double targetQty = 10.0;

      final List<ProductionConsumptionItem> requirements = activeBOM.items.map<ProductionConsumptionItem>((item) {
        final double qty = item.quantity * targetQty;
        return ProductionConsumptionItem(
          productId: item.productId,
          productName: item.productName,
          quantityRequired: qty + (qty * (item.wastagePercentage / 100.0)),
          quantityConsumed: qty + (qty * (item.wastagePercentage / 100.0)),
          unit: item.unit,
        );
      }).toList();

      final order = ProductionOrder(
        id: 'po_test_run',
        businessId: 'biz_01',
        productionNumber: 'PRUN-TEST-001',
        date: DateTime.now(),
        finishedProductId: activeBOM.finishedProductId,
        finishedProductName: activeBOM.finishedProductName,
        bomId: activeBOM.id,
        bomVersion: activeBOM.version,
        quantity: targetQty,
        rawMaterialWarehouseId: 'main',
        warehouseId: 'main',
        rawMaterialCost: 0.0,
        laborCost: 0.0,
        overheadCost: 0.0,
        scrapValue: 0.0,
        totalCost: 0.0,
        status: ProductionStatus.draft,
        notes: '',
        consumedItems: requirements,
        wastageItems: [],
      );

      await notifier.addProductionOrder(order);

      await notifier.startProduction(order.id);
      expect(notifier.state.productionOrders.firstWhere((o) => o.id == order.id).status, ProductionStatus.inProgress);

      final double labor = 200.0;
      final double overhead = 100.0;

      await notifier.completeProduction(
        orderId: order.id,
        laborCost: labor,
        overheadCost: overhead,
        actualConsumption: requirements,
        wastageItems: [
          ProductionWastageItem(productId: 'prod_raw_01', productName: 'Wheat Grain', quantity: 0.1, type: 'SCRAP', reason: 'Test scrap'),
        ],
      );

      final completedOrder = notifier.state.productionOrders.firstWhere((o) => o.id == order.id);
      expect(completedOrder.status, ProductionStatus.completed);
      expect(completedOrder.totalCost > 0.0, true);

      final finishedProduct = notifier.state.products.firstWhere((p) => p.id == 'prod_finished_01');
      expect(finishedProduct.currentStock, initialFinishedProduct.currentStock + targetQty);

      final journal = notifier.state.journalEntries.firstWhere((je) => je.referenceId == order.id);
      double drSum = 0.0;
      double crSum = 0.0;
      for (var l in journal.lines) {
        drSum += l.debit;
        crSum += l.credit;
      }
      expect(double.parse(drSum.toStringAsFixed(2)), double.parse(crSum.toStringAsFixed(2)));
    });

    test('Job Work Register: Dispatch raw materials and receive finished goods', () async {
      final initialRawStock = notifier.state.products.firstWhere((p) => p.id == 'prod_raw_01').currentStock;

      final order = JobWorkOrder(
        id: 'jw_test_run',
        businessId: 'biz_01',
        jobWorkerId: 'jw_worker_01',
        jobWorkerName: 'Contractor Bunny',
        rawMaterialId: 'prod_raw_01',
        rawMaterialName: 'Wheat Grain',
        quantitySent: 20.0,
        dateSent: DateTime.now(),
        reference: 'JW-TEST-001',
        expectedReturnDate: DateTime.now().add(const Duration(days: 14)),
        finishedProductId: 'prod_finished_01',
        finishedProductName: 'Premium Farm Bread',
        expectedFinishedQuantity: 30.0,
        receivedFinishedQuantity: 0.0,
        scrapQuantity: 0.0,
        jobWorkCharges: 500.0,
        status: JobWorkStatus.sent,
      );

      await notifier.addJobWorkOrder(order);

      final sentRawStock = notifier.state.products.firstWhere((p) => p.id == 'prod_raw_01').currentStock;
      expect(sentRawStock, initialRawStock - 20.0);

      await notifier.receiveJobWork(order.id, 30.0, 1.5);

      final completedOrder = notifier.state.jobWorkOrders.firstWhere((o) => o.id == order.id);
      expect(completedOrder.status, JobWorkStatus.completed);
      expect(completedOrder.receivedFinishedQuantity, 30.0);
      expect(completedOrder.scrapQuantity, 1.5);
    });
  });
}
