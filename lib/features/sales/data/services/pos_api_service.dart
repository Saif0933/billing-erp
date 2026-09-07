import '../../../../core/models/billing_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/pos_dto.dart';

/// Service connecting Flutter POS Frontend directly to Backend POS Module
class PosApiService {
  final ApiClient _apiClient;

  PosApiService(this._apiClient);

  /// 1. Fetch POS Product Catalog with live warehouse stock
  Future<List<Product>> getProducts({
    String? search,
    String? category,
    String? barcode,
    String? warehouseId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['q'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (barcode != null && barcode.trim().isNotEmpty) {
      queryParams['barcode'] = barcode.trim();
    }
    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      queryParams['warehouseId'] = warehouseId.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.posProducts,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final productsRaw = payload['products'] as List<dynamic>? ?? [];

    return productsRaw
        .map((p) => PosProductDto.fromJson(p as Map<String, dynamic>).toDomain())
        .toList();
  }

  /// 2. Fast barcode scan lookup
  Future<Product?> scanBarcode(String barcode) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.posScan}/${Uri.encodeComponent(barcode.trim())}',
      );
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final productRaw = payload['product'] as Map<String, dynamic>? ?? payload;

      return PosProductDto.fromJson(productRaw).toDomain();
    } catch (_) {
      return null;
    }
  }

  /// 3. Search & Fetch Customers for POS
  Future<List<Customer>> getCustomers({String? search, int limit = 50}) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['q'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.posCustomers,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    List<dynamic> customersRaw = [];
    if (rawData is Map<String, dynamic>) {
      final inner = rawData['data'];
      if (inner is List) {
        customersRaw = inner;
      } else if (inner is Map<String, dynamic> && inner['customers'] is List) {
        customersRaw = inner['customers'] as List;
      } else if (rawData['customers'] is List) {
        customersRaw = rawData['customers'] as List;
      }
    } else if (rawData is List) {
      customersRaw = rawData;
    }

    return customersRaw.map((c) {
      final json = c as Map<String, dynamic>;
      final gstin = json['gstin']?.toString() ?? '';
      final stateCode = json['stateCode']?.toString().isNotEmpty == true
          ? json['stateCode'].toString()
          : (gstin.length >= 2 ? gstin.substring(0, 2) : '27');
      final openingBalance = (json['openingBalance'] as num?)?.toDouble() ?? 0.0;

      return Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Customer',
        type: json['customerType']?.toString() ?? json['type']?.toString() ?? 'Retail',
        gstin: gstin,
        pan: json['pan']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? json['mobileNumber']?.toString() ?? json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        billingAddress: json['billingAddress']?.toString() ?? '',
        shippingAddress: json['shippingAddress']?.toString() ?? '',
        state: json['state']?.toString() ?? 'Delhi',
        stateCode: stateCode,
        creditPeriod: (json['creditPeriod'] as num?)?.toInt() ?? 0,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
        openingBalance: openingBalance,
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? openingBalance,
        customerGroup: json['customerGroup']?.toString() ?? json['type']?.toString() ?? 'General',
        notes: json['notes']?.toString() ?? '',
        isRegistered: json['isRegistered'] == true || gstin.isNotEmpty,
      );
    }).toList();
  }

  /// 4. Fast Quick Customer Registration directly at POS counter
  Future<Customer> quickCreateCustomer({
    required String name,
    required String phone,
    String? email,
    String? gstin,
    String? state,
    String? address,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.posQuickCustomer,
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'mobileNumber': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (gstin != null && gstin.trim().isNotEmpty) 'gstin': gstin.trim(),
        if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
        if (address != null && address.trim().isNotEmpty) ...{
          'address': address.trim(),
          'billingAddress': address.trim(),
        },
      },
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final c = payload['customer'] as Map<String, dynamic>? ?? payload;

    final customerGstin = c['gstin']?.toString() ?? gstin ?? '';
    final customerStateCode = c['stateCode']?.toString().isNotEmpty == true
        ? c['stateCode'].toString()
        : (customerGstin.length >= 2 ? customerGstin.substring(0, 2) : '27');
    final openingBal = (c['openingBalance'] as num?)?.toDouble() ?? 0.0;

    return Customer(
      id: c['id']?.toString() ?? '',
      name: c['name']?.toString() ?? name,
      type: c['customerType']?.toString() ?? c['type']?.toString() ?? 'Retail',
      gstin: customerGstin,
      pan: c['pan']?.toString() ?? '',
      mobile: c['mobile']?.toString() ?? c['mobileNumber']?.toString() ?? c['phone']?.toString() ?? phone,
      email: c['email']?.toString() ?? email ?? '',
      billingAddress: c['billingAddress']?.toString() ?? address ?? '',
      shippingAddress: c['shippingAddress']?.toString() ?? address ?? '',
      state: c['state']?.toString() ?? state ?? 'Delhi',
      stateCode: customerStateCode,
      creditLimit: (c['creditLimit'] as num?)?.toDouble() ?? 0.0,
      creditPeriod: (c['creditPeriod'] as num?)?.toInt() ?? 0,
      openingBalance: openingBal,
      currentBalance: (c['currentBalance'] as num?)?.toDouble() ?? openingBal,
      customerGroup: c['customerGroup']?.toString() ?? 'General',
      notes: c['notes']?.toString() ?? '',
      isRegistered: c['isRegistered'] == true || customerGstin.isNotEmpty,
    );
  }

  /// 5. Open POS Register / Cash Drawer Session
  Future<POSSession> openSession({
    required double openingCash,
    String registerNumber = 'REG-01',
    String counterName = 'Main Counter',
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.posSessionOpen,
      data: {
        'openingCash': openingCash,
        'registerNumber': registerNumber,
        'counterName': counterName,
        'notes': ?notes,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final sessionRaw = payload['session'] as Map<String, dynamic>? ?? payload;

    return PosSessionDto.fromJson(sessionRaw).toDomain();
  }

  /// 6. Check Active Register Session
  Future<POSSession?> getActiveSession() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.posSessionActive);
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;

      if (payload['active'] == true && payload['session'] != null) {
        return PosSessionDto.fromJson(
          payload['session'] as Map<String, dynamic>,
        ).toDomain();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 7. Close POS Register / Cash Drawer Session
  Future<Map<String, dynamic>> closeSession({
    required double closingCash,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.posSessionClose,
      data: {
        'closingCash': closingCash,
        'notes': ?notes,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }

  /// 8. POS Fast Billing Checkout Transaction
  Future<PosCheckoutResponse> checkout(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.posCheckout,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final result = (data['data'] as Map<String, dynamic>?) ?? data;

    return PosCheckoutResponse.fromJson(result);
  }

  /// 9. Hold / Park Transaction
  Future<Invoice> holdCart(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.posHoldCart,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final payloadData = (data['data'] as Map<String, dynamic>?) ?? data;
    final invoiceRaw = payloadData['invoice'] as Map<String, dynamic>? ?? payloadData;

    return PosCheckoutResponse.fromJson({'invoice': invoiceRaw}).invoice;
  }

  /// 10. Fetch Held Carts
  Future<List<Invoice>> getHeldCarts() async {
    final response = await _apiClient.get(ApiEndpoints.posHeldCarts);
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final listRaw = payload['heldCarts'] as List<dynamic>? ?? [];

    return listRaw.map((item) {
      final m = item as Map<String, dynamic>;
      final invoiceRaw = m['invoice'] as Map<String, dynamic>? ?? m;
      return PosCheckoutResponse.fromJson({'invoice': invoiceRaw}).invoice;
    }).toList();
  }

  /// 11. Resume Held Cart
  Future<Map<String, dynamic>> resumeCart(String heldCartId) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.posResumeCart}/$heldCartId',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }

  /// 12. Delete Held Cart
  Future<bool> deleteHeldCart(String heldCartId) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.posHeldCarts}/$heldCartId',
    );
    final data = response.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// 13. Fetch 80mm Thermal Receipt Layout & Reprint Data
  Future<PosThermalReceiptDto> getReceipt(String invoiceId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.posReceipt}/$invoiceId',
    );
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return PosThermalReceiptDto.fromJson(payload);
  }

  /// 14. Fetch Daily POS Terminal Dashboard Metrics
  Future<PosDashboardSummaryDto> getDashboardSummary() async {
    final response = await _apiClient.get(ApiEndpoints.posDashboardSummary);
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return PosDashboardSummaryDto.fromJson(payload);
  }
}
