import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_dto.dart';
import '../services/product_api_service.dart';

/// Real REST API implementation of ProductRepository.
/// No mock-product fallback — only database products can be listed / sold.
class ApiProductRepository implements ProductRepository {
  final ProductApiService _apiService;

  ApiProductRepository(this._apiService);

  @override
  Future<List<Product>> getProducts({String? query, String? category}) async {
    final res = await _apiService.getProducts(
      search: query,
      category: category,
      limit: 100,
    );
    return res.products.map((dto) => dto.toDomainProduct()).toList();
  }

  @override
  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      final dto = await _apiService.findProductByBarcode(barcode);
      return dto.toDomainProduct();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
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
      gstRatePercent: product.gstRate,
      currentStock: product.stock.toDouble(),
      stock: product.stock,
      unit: product.unit,
      primaryUnit: product.unit.toUpperCase(),
      openingStock: product.stock.toDouble(),
      supplierId: product.supplierId,
      supplierName: product.supplierName,
    );

    final created = await _apiService.createProduct(dto);
    return created.toDomainProduct();
  }

  @override
  Future<Product> updateProduct(Product product) async {
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
      gstRatePercent: product.gstRate,
      currentStock: product.stock.toDouble(),
      stock: product.stock,
      unit: product.unit,
      primaryUnit: product.unit.toUpperCase(),
      supplierId: product.supplierId,
      supplierName: product.supplierName,
    );

    final updated = await _apiService.updateProduct(dto);
    return updated.toDomainProduct();
  }

  @override
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
