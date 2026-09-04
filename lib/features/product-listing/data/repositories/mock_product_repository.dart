import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/mock_products_data.dart';

/// In-memory implementation of [ProductRepository].
/// Maintains local catalog state and simulates real-time search & barcode discovery.
class MockProductRepository implements ProductRepository {
  final List<Product> _catalog = List<Product>.from(kInitialMockProducts);

  @override
  Future<List<Product>> getProducts({String? query, String? category}) async {
    // Simulate brief non-blocking latency for architectural realism
    await Future.delayed(const Duration(milliseconds: 20));

    return _catalog.where((p) {
      final matchesCat = category == null ||
          category.isEmpty ||
          category.toLowerCase() == 'all' ||
          p.category.toLowerCase() == category.toLowerCase();

      final q = query?.toLowerCase().trim() ?? '';
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);

      return matchesCat && matchesQuery;
    }).toList();
  }

  @override
  Future<Product?> findProductByBarcode(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 15));
    final normalized = barcode.trim().toUpperCase();

    try {
      return _catalog.firstWhere(
        (p) => p.barcode.trim().toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 20));

    // If barcode already exists, update it, otherwise prepend to catalog
    final existingIndex = _catalog.indexWhere(
      (p) => p.barcode.trim().toUpperCase() == product.barcode.trim().toUpperCase(),
    );

    if (existingIndex >= 0) {
      _catalog[existingIndex] = product;
    } else {
      _catalog.insert(0, product);
    }

    return product;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _catalog.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      _catalog[index] = product;
      return product;
    } else {
      _catalog.insert(0, product);
      return product;
    }
  }

  @override
  Future<bool> deleteProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final initialLen = _catalog.length;
    _catalog.removeWhere((p) => p.id == productId);
    return _catalog.length < initialLen;
  }
}
