import '../models/billing_models.dart';
import '../../features/dashboard/presentation/providers/billing_repository.dart';

enum SearchCategory {
  customers('Customers'),
  suppliers('Suppliers'),
  products('Products'),
  services('Services'),
  invoices('Invoices'),
  payments('Payments'),
  receipts('Receipts'),
  general('General');

  final String label;
  const SearchCategory(this.label);
}

class SearchResult {
  final String title;
  final String subtitle;
  final SearchCategory category;
  final String route;
  final Map<String, String>? metadata;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
    this.metadata,
  });
}

class SearchRepository {
  Future<List<SearchResult>> search(String query, BillingState billingState, {SearchCategory? category}) async {
    if (query.trim().isEmpty) return [];

    final cleanQuery = query.toLowerCase().trim();
    final List<SearchResult> results = [];

    // 1. Search Customers
    for (var c in billingState.customers) {
      if (c.name.toLowerCase().contains(cleanQuery) ||
          c.mobile.contains(cleanQuery) ||
          c.gstin.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: c.name,
          subtitle: 'Customer - Mobile: ${c.mobile} | GSTIN: ${c.gstin}',
          category: SearchCategory.customers,
          route: '/customers/${c.id}',
        ));
      }
    }

    // 2. Search Suppliers
    for (var s in billingState.suppliers) {
      if (s.name.toLowerCase().contains(cleanQuery) ||
          s.mobile.contains(cleanQuery) ||
          s.gstin.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: s.name,
          subtitle: 'Supplier - Mobile: ${s.mobile} | GSTIN: ${s.gstin}',
          category: SearchCategory.suppliers,
          route: '/suppliers/${s.id}',
        ));
      }
    }

    // 3. Search Products
    for (var p in billingState.products) {
      if (p.name.toLowerCase().contains(cleanQuery) ||
          p.code.toLowerCase().contains(cleanQuery) ||
          p.sku.toLowerCase().contains(cleanQuery) ||
          p.barcode.contains(cleanQuery)) {
        results.add(SearchResult(
          title: p.name,
          subtitle: 'Product - SKU: ${p.sku} | Barcode: ${p.barcode} | Price: ₹${p.sellingPrice}',
          category: SearchCategory.products,
          route: '/products',
        ));
      }
    }

    // 4. Search Invoices
    for (var inv in billingState.invoices) {
      if (inv.invoiceNumber.toLowerCase().contains(cleanQuery) ||
          inv.customerName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: inv.invoiceNumber,
          subtitle: 'Invoice - Customer: ${inv.customerName} | Amount: ₹${inv.grandTotal} | Status: ${inv.status.name.toUpperCase()}',
          category: SearchCategory.invoices,
          route: '/sales/${inv.id}',
        ));
      }
    }

    // 5. Search Payments
    for (var pay in billingState.payments) {
      if (pay.referenceNumber.toLowerCase().contains(cleanQuery) ||
          pay.supplierName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: 'Payment - Ref: ${pay.referenceNumber}',
          subtitle: 'Payment Outward - Supplier: ${pay.supplierName} | Amount: ₹${pay.amount}',
          category: SearchCategory.payments,
          route: '/payments/new',
        ));
      }
    }

    // 6. Search Receipts
    for (var rec in billingState.receipts) {
      if (rec.referenceNumber.toLowerCase().contains(cleanQuery) ||
          rec.customerName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: 'Receipt - Ref: ${rec.referenceNumber}',
          subtitle: 'Payment Receipt - Customer: ${rec.customerName} | Amount: ₹${rec.amount}',
          category: SearchCategory.receipts,
          route: '/receipts/new',
        ));
      }
    }

    return results;
  }
}
