import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_dto.dart';
import '../services/product_api_service.dart';
import 'mock_product_repository.dart';

/// Real REST API implementation of ProductRepository backed by ProductApiService.
/// Falls back to local MockProductRepository when offline or when initial seeding is needed.
class ApiProductRepository implements ProductRepository {
  final ProductApiService _apiService;
  final MockProductRepository _fallback;

  ApiProductRepository(this._apiService, [MockProductRepository? fallback])
      : _fallback = fallback ?? MockProductRepository();

  @override
  Future<List<Product>> getProducts({String? query, String? category}) async {
    try {
      final res = await _apiService.getProducts(
        search: query,
        category: category,
        limit: 100,
      );

      final domainList =
          res.products.map((dto) => dto.toDomainProduct()).toList();

      if (domainList.isNotEmpty) {
        return domainList;
      }
      // If server returns empty list initially, fallback to demo products
      return _fallback.getProducts(query: query, category: category);
    } catch (_) {
      return _fallback.getProducts(query: query, category: category);
    }
  }

  @override
  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      final dto = await _apiService.findProductByBarcode(barcode);
      return dto.toDomainProduct();
    } catch (_) {
      // Fall back to local in-memory catalog
      return _fallback.findProductByBarcode(barcode);
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    try {
      final dto = ProductDto(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        sku: product.sku,
        category: product.category,
        sellingPrice: product.sellingPrice,
        purchasePrice: product.purchasePrice,
        mrp: product.mrp,
        gstRate: product.gstRate,
        currentStock: product.stock.toDouble(),
        stock: product.stock,
        unit: product.unit,
      );

      final created = await _apiService.createProduct(dto);
      return created.toDomainProduct();
    } catch (_) {
      return _fallback.addProduct(product);
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final dto = ProductDto(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        sku: product.sku,
        category: product.category,
        sellingPrice: product.sellingPrice,
        purchasePrice: product.purchasePrice,
        mrp: product.mrp,
        gstRate: product.gstRate,
        currentStock: product.stock.toDouble(),
        stock: product.stock,
        unit: product.unit,
      );

      final updated = await _apiService.updateProduct(dto);
      return updated.toDomainProduct();
    } catch (_) {
      return _fallback.updateProduct(product);
    }
  }

  @override
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      return true;
    } catch (_) {
      return _fallback.deleteProduct(productId);
    }
  }
}
