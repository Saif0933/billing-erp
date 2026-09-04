import '../entities/product.dart';

/// Abstract repository interface for product discovery and management.
/// Designed so that mock implementation can be swapped for a REST API client
/// without touching the UI or business logic.
abstract class ProductRepository {
  /// Fetch list of products with optional query and category filtering
  Future<List<Product>> getProducts({String? query, String? category});

  /// Find a specific product by its exact barcode (EAN-13, EAN-8, UPC, Code-128, etc.)
  Future<Product?> findProductByBarcode(String barcode);

  /// Add a newly created product to the catalogue
  Future<Product> addProduct(Product product);

  /// Update an existing product
  Future<Product> updateProduct(Product product);

  /// Delete a product
  Future<bool> deleteProduct(String productId);
}
