import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/business_model.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final BusinessModel? activeBusiness;
  final bool isLoading;

  const BusinessState({
    this.businesses = const [],
    this.activeBusiness,
    this.isLoading = false,
  });

  BusinessState copyWith({
    List<BusinessModel>? businesses,
    BusinessModel? activeBusiness,
    bool? isLoading,
    bool clearActive = false,
  }) {
    return BusinessState(
      businesses: businesses ?? this.businesses,
      activeBusiness: clearActive ? null : (activeBusiness ?? this.activeBusiness),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BusinessNotifier extends StateNotifier<BusinessState> {
  final StorageService _storage;
  final UserModel? _user;

  BusinessNotifier(this._storage, this._user) : super(const BusinessState()) {
    loadBusinesses();
  }

  static List<BusinessModel> extractBusinesses(UserModel? user) {
    final list = <BusinessModel>[];
    if (user == null) return list;

    if (user.ownedBusinesses != null) {
      for (final item in user.ownedBusinesses!) {
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && !list.any((b) => b.id == id)) {
            list.add(BusinessModel(
              id: id,
              name: item['businessName']?.toString() ??
                  item['name']?.toString() ??
                  'My Business',
              type: item['tradeName']?.toString() ?? 'Retail',
              gstNumber: item['gstin']?.toString() ?? '',
              legalName: item['legalName']?.toString() ?? '',
              email: item['email']?.toString() ?? '',
              mobile: item['mobileNumber']?.toString() ?? '',
              state: item['state']?.toString() ?? 'Maharashtra',
            ));
          }
        }
      }
    }

    if (user.businessMemberships != null) {
      for (final item in user.businessMemberships!) {
        if (item is Map<String, dynamic>) {
          final biz = item['business'] is Map<String, dynamic>
              ? item['business'] as Map<String, dynamic>
              : null;
          final id = biz?['id']?.toString() ?? item['businessId']?.toString() ?? '';
          if (id.isNotEmpty && !list.any((b) => b.id == id)) {
            list.add(BusinessModel(
              id: id,
              name: biz?['businessName']?.toString() ??
                  biz?['name']?.toString() ??
                  'My Business',
              type: biz?['tradeName']?.toString() ?? 'Retail',
              gstNumber: biz?['gstin']?.toString() ?? '',
              legalName: biz?['legalName']?.toString() ?? '',
              email: biz?['email']?.toString() ?? '',
              mobile: biz?['mobileNumber']?.toString() ?? '',
              state: biz?['state']?.toString() ?? 'Maharashtra',
            ));
          }
        }
      }
    }

    return list;
  }

  static final List<BusinessModel> fallbackBusinesses = [
    const BusinessModel(
      id: 'biz_default',
      name: 'My Retail Store',
      type: 'Retail',
      gstNumber: '27AADCA1234F1Z5',
    ),
  ];

  Future<void> loadBusinesses() async {
    state = state.copyWith(isLoading: true);

    final realBusinesses = extractBusinesses(_user);
    final available =
        realBusinesses.isNotEmpty ? realBusinesses : fallbackBusinesses;

    final activeId = _storage.getActiveBusinessId();
    BusinessModel? active;

    if (activeId != null && activeId.isNotEmpty && !activeId.startsWith('biz_')) {
      final match = available.where((b) => b.id == activeId);
      if (match.isNotEmpty) {
        active = match.first;
      } else if (realBusinesses.isNotEmpty) {
        active = realBusinesses.first;
        await _storage.setActiveBusinessId(active.id);
      }
    } else if (realBusinesses.isNotEmpty) {
      active = realBusinesses.first;
      await _storage.setActiveBusinessId(active.id);
    } else if (available.isNotEmpty) {
      active = available.first;
    }

    state = BusinessState(
      businesses: available,
      activeBusiness: active,
      isLoading: false,
    );
  }

  Future<void> switchBusiness(String id) async {
    final active = state.businesses.firstWhere(
      (b) => b.id == id,
      orElse: () => state.businesses.first,
    );
    if (!active.id.startsWith('biz_')) {
      await _storage.setActiveBusinessId(active.id);
    }
    state = state.copyWith(activeBusiness: active);
  }

  Future<void> createBusiness({
    required String name,
    required String type,
    required String gstNumber,
  }) async {
    state = state.copyWith(isLoading: true);

    final newBiz = BusinessModel(
      id: 'biz_${state.businesses.length + 1}',
      name: name,
      type: type,
      gstNumber: gstNumber,
    );
    final updated = [...state.businesses, newBiz];
    state = BusinessState(
      businesses: updated,
      activeBusiness: newBiz,
      isLoading: false,
    );
  }
}

final businessProvider =
    StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final auth = ref.watch(authProvider);
  return BusinessNotifier(storage, auth.user);
});
