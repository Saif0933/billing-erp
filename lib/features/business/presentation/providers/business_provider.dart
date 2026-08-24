import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/business_model.dart';
import '../../../../core/storage/storage_service.dart';
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

  BusinessNotifier(this._storage) : super(const BusinessState()) {
    loadBusinesses();
  }

  static final List<BusinessModel> mockBusinesses = [
    const BusinessModel(id: 'biz_01', name: 'Tax Bunny Retail Store', type: 'Retail', gstNumber: '27AADCA1234F1Z5'),
    const BusinessModel(id: 'biz_02', name: 'Bunny Wholesale Agency', type: 'Wholesale', gstNumber: '27AADCA5678F1Z9'),
  ];

  Future<void> loadBusinesses() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final activeId = _storage.getActiveBusinessId();
    BusinessModel? active;
    if (activeId != null) {
      active = mockBusinesses.firstWhere((b) => b.id == activeId, orElse: () => mockBusinesses.first);
    } else if (mockBusinesses.isNotEmpty) {
      active = mockBusinesses.first;
      await _storage.setActiveBusinessId(active.id);
    }

    state = BusinessState(
      businesses: mockBusinesses,
      activeBusiness: active,
      isLoading: false,
    );
  }

  Future<void> switchBusiness(String id) async {
    final active = state.businesses.firstWhere((b) => b.id == id, orElse: () => state.businesses.first);
    await _storage.setActiveBusinessId(active.id);
    state = state.copyWith(activeBusiness: active);
  }

  Future<void> createBusiness({
    required String name,
    required String type,
    required String gstNumber,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final newBiz = BusinessModel(
      id: 'biz_${state.businesses.length + 1}',
      name: name,
      type: type,
      gstNumber: gstNumber,
    );
    final updated = [...state.businesses, newBiz];
    await _storage.setActiveBusinessId(newBiz.id);
    state = BusinessState(
      businesses: updated,
      activeBusiness: newBiz,
      isLoading: false,
    );
  }
}

final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BusinessNotifier(storage);
});
