// ============================================================================
// File: lib/providers/search_provider.dart
// Mục đích: Quản lý trạng thái (State Management) cho search.
// Kết cấu:
//  - Sử dụng Riverpod (Notifier/StateNotifier/Provider) để cung cấp trạng thái và xử lý logic nghiệp vụ.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/services/location_service.dart';
import '../core/utils/distance_helper.dart';
import '../features/search_map/data/barber_repository.dart';
import '../models/barber_profile_model.dart';

/// Dữ liệu thợ cắt tóc kèm thông tin khoảng cách đã tính toán (Task 3.4 & 3.8)
class BarberWithDistance {
  final BarberProfileModel barber;
  final double distanceMeters;
  final String distanceFormatted;
  final bool isMatchingHairstyle;

  const BarberWithDistance({
    required this.barber,
    required this.distanceMeters,
    required this.distanceFormatted,
    required this.isMatchingHairstyle,
  });

  BarberWithDistance copyWith({
    BarberProfileModel? barber,
    double? distanceMeters,
    String? distanceFormatted,
    bool? isMatchingHairstyle,
  }) {
    return BarberWithDistance(
      barber: barber ?? this.barber,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceFormatted: distanceFormatted ?? this.distanceFormatted,
      isMatchingHairstyle: isMatchingHairstyle ?? this.isMatchingHairstyle,
    );
  }
}

/// Trạng thái tìm kiếm và hiển thị bản đồ (Task 3.4)
class SearchMapState {
  final LatLng? userGpsLocation;
  final LatLng referenceLocation;
  final bool isGpsFallback;
  final String? locationMessage;
  final String? selectedHairstyleId;
  final String searchQuery;
  final int? maxPriceFilter;
  final List<BarberProfileModel> allApprovedBarbers;
  final List<BarberWithDistance> displayBarbers;
  final BarberProfileModel? selectedBarber;
  final bool isListView;
  final bool isLocating;

  const SearchMapState({
    this.userGpsLocation,
    required this.referenceLocation,
    this.isGpsFallback = false,
    this.locationMessage,
    this.selectedHairstyleId,
    this.searchQuery = '',
    this.maxPriceFilter,
    this.allApprovedBarbers = const [],
    this.displayBarbers = const [],
    this.selectedBarber,
    this.isListView = false,
    this.isLocating = false,
  });

  /// Số thợ thực sự phù hợp với kiểu tóc được chọn
  int get matchingCount =>
      displayBarbers.where((b) => b.isMatchingHairstyle).length;

  /// Đã chọn kiểu tóc nhưng không có thợ nào hỗ trợ trong hệ thống
  bool get hasNoMatchingForHairstyle =>
      selectedHairstyleId != null &&
      selectedHairstyleId!.isNotEmpty &&
      matchingCount == 0 &&
      displayBarbers.isNotEmpty;

  SearchMapState copyWith({
    LatLng? userGpsLocation,
    LatLng? referenceLocation,
    bool? isGpsFallback,
    String? locationMessage,
    String? selectedHairstyleId,
    bool clearHairstyleFilter = false,
    String? searchQuery,
    int? maxPriceFilter,
    bool clearPriceFilter = false,
    List<BarberProfileModel>? allApprovedBarbers,
    List<BarberWithDistance>? displayBarbers,
    BarberProfileModel? selectedBarber,
    bool clearSelectedBarber = false,
    bool? isListView,
    bool? isLocating,
  }) {
    return SearchMapState(
      userGpsLocation: userGpsLocation ?? this.userGpsLocation,
      referenceLocation: referenceLocation ?? this.referenceLocation,
      isGpsFallback: isGpsFallback ?? this.isGpsFallback,
      locationMessage: locationMessage ?? this.locationMessage,
      selectedHairstyleId: clearHairstyleFilter
          ? null
          : (selectedHairstyleId ?? this.selectedHairstyleId),
      searchQuery: searchQuery ?? this.searchQuery,
      maxPriceFilter: clearPriceFilter
          ? null
          : (maxPriceFilter ?? this.maxPriceFilter),
      allApprovedBarbers: allApprovedBarbers ?? this.allApprovedBarbers,
      displayBarbers: displayBarbers ?? this.displayBarbers,
      selectedBarber: clearSelectedBarber
          ? null
          : (selectedBarber ?? this.selectedBarber),
      isListView: isListView ?? this.isListView,
      isLocating: isLocating ?? this.isLocating,
    );
  }
}

/// Notifier quản lý logic tìm kiếm thợ, tính khoảng cách và lọc kiểu tóc (Task 3.4, 3.9, 3.11)
class SearchNotifier extends AsyncNotifier<SearchMapState> {
  @override
  Future<SearchMapState> build() async {
    final locationService = ref.watch(locationServiceProvider);
    final barberRepo = ref.watch(barberRepositoryProvider);

    // 1. Lấy vị trí người dùng (hoặc fallback mặc định Đà Nẵng)
    final locResult = await locationService.getCurrentPosition();

    // 2. Lấy danh sách thợ approved từ Firestore (Stream real-time)
    final barbersAsync = ref.watch(approvedBarbersStreamProvider);
    List<BarberProfileModel> barbers = barbersAsync.value ?? [];

    if (barbers.isEmpty) {
      try {
        barbers = await barberRepo.getApprovedBarbers();
      } catch (e) {
        debugPrint('⚠️ [SearchNotifier] Không thể tải thợ: $e');
      }
    }

    final refPoint = locResult.coordinates;
    final processedBarbers = _computeAndSortBarbers(
      barbers: barbers,
      refLocation: refPoint,
      hairstyleId: null,
      query: '',
    );

    return SearchMapState(
      userGpsLocation: locResult.isFallback ? null : locResult.coordinates,
      referenceLocation: refPoint,
      isGpsFallback: locResult.isFallback,
      locationMessage: locResult.errorMessage,
      allApprovedBarbers: barbers,
      displayBarbers: processedBarbers,
    );
  }

  /// Tính toán khoảng cách và sắp xếp danh sách thợ (Task 3.3, 3.4, 3.9, 6.11)
  List<BarberWithDistance> _computeAndSortBarbers({
    required List<BarberProfileModel> barbers,
    required LatLng refLocation,
    required String? hairstyleId,
    required String query,
    int? maxPrice,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Lọc theo từ khoá tìm kiếm và khoảng giá tối đa
    final filtered = barbers.where((b) {
      if (cleanQuery.isNotEmpty) {
        final matchName = b.displayName.toLowerCase().contains(cleanQuery);
        final matchAddress = b.address.toLowerCase().contains(cleanQuery);
        if (!matchName && !matchAddress) return false;
      }
      if (maxPrice != null && maxPrice > 0) {
        if (b.priceMin > maxPrice) return false;
      }
      return true;
    }).toList();

    // 2. Tính khoảng cách Haversine từ toạ độ tham chiếu đến từng thợ
    final withDistanceList = filtered.map((b) {
      final distance = DistanceHelper.calculateDistanceMeters(
        lat1: refLocation.latitude,
        lon1: refLocation.longitude,
        lat2: b.location.latitude,
        lon2: b.location.longitude,
      );

      final isMatching = (hairstyleId != null && hairstyleId.isNotEmpty)
          ? b.hairstyleIds.contains(hairstyleId)
          : false;

      return BarberWithDistance(
        barber: b,
        distanceMeters: distance,
        distanceFormatted: DistanceHelper.formatDistance(distance),
        isMatchingHairstyle: isMatching,
      );
    }).toList();

    // 3. Sắp xếp:
    // - Nếu có lọc kiểu tóc: Ưu tiên thợ phù hợp lên đầu.
    // - Trong cùng nhóm phù hợp / không phù hợp: Sắp xếp khoảng cách gần nhất lên trước.
    withDistanceList.sort((a, b) {
      if (hairstyleId != null && hairstyleId.isNotEmpty) {
        if (a.isMatchingHairstyle && !b.isMatchingHairstyle) return -1;
        if (!a.isMatchingHairstyle && b.isMatchingHairstyle) return 1;
      }
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    return withDistanceList;
  }

  /// Cập nhật bộ lọc kiểu tóc (Task 3.9)
  void setHairstyleFilter(String? hairstyleId) {
    state.whenData((currentState) {
      final processed = _computeAndSortBarbers(
        barbers: currentState.allApprovedBarbers,
        refLocation: currentState.referenceLocation,
        hairstyleId: hairstyleId,
        query: currentState.searchQuery,
        maxPrice: currentState.maxPriceFilter,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          selectedHairstyleId: hairstyleId,
          clearHairstyleFilter: hairstyleId == null,
          displayBarbers: processed,
        ),
      );
    });
  }

  /// Cập nhật bộ lọc giá tối đa (Task 6.11)
  void setMaxPriceFilter(int? maxPrice) {
    state.whenData((currentState) {
      final processed = _computeAndSortBarbers(
        barbers: currentState.allApprovedBarbers,
        refLocation: currentState.referenceLocation,
        hairstyleId: currentState.selectedHairstyleId,
        query: currentState.searchQuery,
        maxPrice: maxPrice,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          maxPriceFilter: maxPrice,
          clearPriceFilter: maxPrice == null,
          displayBarbers: processed,
        ),
      );
    });
  }

  /// Tìm kiếm bằng từ khoá
  void setSearchQuery(String query) {
    state.whenData((currentState) {
      final processed = _computeAndSortBarbers(
        barbers: currentState.allApprovedBarbers,
        refLocation: currentState.referenceLocation,
        hairstyleId: currentState.selectedHairstyleId,
        query: query,
        maxPrice: currentState.maxPriceFilter,
      );

      state = AsyncValue.data(
        currentState.copyWith(searchQuery: query, displayBarbers: processed),
      );
    });
  }

  /// Cập nhật toạ độ tâm tham chiếu (khi người dùng kéo bản đồ hoặc bấm GPS)
  void setReferenceLocation(LatLng newLocation) {
    state.whenData((currentState) {
      final processed = _computeAndSortBarbers(
        barbers: currentState.allApprovedBarbers,
        refLocation: newLocation,
        hairstyleId: currentState.selectedHairstyleId,
        query: currentState.searchQuery,
        maxPrice: currentState.maxPriceFilter,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          referenceLocation: newLocation,
          displayBarbers: processed,
        ),
      );
    });
  }

  /// Làm mới vị trí GPS của người dùng (nút "Vị trí của tôi")
  Future<void> refreshUserLocation() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isLocating: true));

    final locationService = ref.read(locationServiceProvider);
    final locResult = await locationService.getCurrentPosition();

    final processed = _computeAndSortBarbers(
      barbers: currentState.allApprovedBarbers,
      refLocation: locResult.coordinates,
      hairstyleId: currentState.selectedHairstyleId,
      query: currentState.searchQuery,
    );

    state = AsyncValue.data(
      currentState.copyWith(
        userGpsLocation: locResult.isFallback ? null : locResult.coordinates,
        referenceLocation: locResult.coordinates,
        isGpsFallback: locResult.isFallback,
        locationMessage: locResult.errorMessage,
        displayBarbers: processed,
        isLocating: false,
      ),
    );
  }

  /// Chọn một thợ trên bản đồ để mở bottom sheet / xem chi tiết
  void selectBarber(BarberProfileModel? barber) {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(
          selectedBarber: barber,
          clearSelectedBarber: barber == null,
        ),
      );
    });
  }

  /// Chuyển đổi giữa chế độ xem Bản đồ (Map) và Danh sách (List) (Task 3.7)
  void toggleViewMode() {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(isListView: !currentState.isListView),
      );
    });
  }

  /// Tải lại toàn bộ dữ liệu thợ từ server
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await build());
  }
}

/// Provider chính cho tính năng tìm kiếm và bản đồ thợ (Task 3.4)
final searchNotifierProvider =
    AsyncNotifierProvider<SearchNotifier, SearchMapState>(() {
      return SearchNotifier();
    });
