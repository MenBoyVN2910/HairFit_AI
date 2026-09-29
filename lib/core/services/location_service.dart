import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/business_constants.dart';

/// Kết quả lấy vị trí người dùng
class LocationResult {
  final LatLng coordinates;
  final bool isFallback;
  final LocationPermission permission;
  final bool isServiceEnabled;
  final String? errorMessage;

  const LocationResult({
    required this.coordinates,
    required this.isFallback,
    required this.permission,
    required this.isServiceEnabled,
    this.errorMessage,
  });

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;

  /// Tạo toạ độ mặc định (Đà Nẵng) khi gặp lỗi hoặc người dùng từ chối quyền
  factory LocationResult.fallback({
    required LocationPermission permission,
    required bool isServiceEnabled,
    String? errorMessage,
  }) {
    return LocationResult(
      coordinates: const LatLng(
        BusinessConstants.defaultLatitude,
        BusinessConstants.defaultLongitude,
      ),
      isFallback: true,
      permission: permission,
      isServiceEnabled: isServiceEnabled,
      errorMessage: errorMessage,
    );
  }
}

/// Dịch vụ quản lý quyền và lấy vị trí GPS (Task 3.1)
class LocationService {
  /// Toạ độ mặc định
  static const LatLng defaultCoordinates = LatLng(
    BusinessConstants.defaultLatitude,
    BusinessConstants.defaultLongitude,
  );

  /// Kiểm tra dịch vụ định vị (GPS) trên thiết bị có đang bật không
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('⚠️ [LocationService] Lỗi kiểm tra service: $e');
      return false;
    }
  }

  /// Kiểm tra trạng thái cấp quyền hiện tại
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('⚠️ [LocationService] Lỗi kiểm tra permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Yêu cầu cấp quyền truy cập vị trí
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('⚠️ [LocationService] Lỗi yêu cầu permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Lấy toạ độ vị trí hiện tại của người dùng.
  /// Nếu người dùng từ chối, tắt GPS hoặc timeout, tự động trả về toạ độ mặc định (Đà Nẵng).
  Future<LocationResult> getCurrentPosition({
    bool fallbackToDefault = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    bool serviceEnabled = false;
    LocationPermission permission = LocationPermission.denied;

    try {
      serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [LocationService] Dịch vụ định vị GPS đang tắt.');
        return LocationResult.fallback(
          permission: permission,
          isServiceEnabled: false,
          errorMessage: 'Dịch vụ định vị GPS trên máy đang tắt. Sử dụng vị trí trung tâm TP. ${BusinessConstants.defaultCityName}.',
        );
      }

      permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ [LocationService] Người dùng từ chối cấp quyền vị trí.');
          return LocationResult.fallback(
            permission: permission,
            isServiceEnabled: serviceEnabled,
            errorMessage: 'Bạn đã từ chối cấp quyền vị trí. Đang hiển thị bản đồ tại ${BusinessConstants.defaultCityName}.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [LocationService] Quyền vị trí bị từ chối vĩnh viễn.');
        return LocationResult.fallback(
          permission: permission,
          isServiceEnabled: serviceEnabled,
          errorMessage: 'Quyền vị trí bị chặn vĩnh viễn trong Cài đặt máy. Đang hiển thị bản đồ tại ${BusinessConstants.defaultCityName}.',
        );
      }

      // Đã có quyền -> Lấy toạ độ
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      debugPrint('📍 [LocationService] Lấy toạ độ thành công: (${position.latitude}, ${position.longitude})');
      return LocationResult(
        coordinates: LatLng(position.latitude, position.longitude),
        isFallback: false,
        permission: permission,
        isServiceEnabled: serviceEnabled,
      );
    } catch (e) {
      debugPrint('⚠️ [LocationService] Lỗi khi lấy GPS: $e');
      return LocationResult.fallback(
        permission: permission,
        isServiceEnabled: serviceEnabled,
        errorMessage: 'Không thể lấy tín hiệu GPS chính xác. Đang sử dụng vị trí mặc định.',
      );
    }
  }

  /// Mở màn hình Cài đặt ứng dụng của máy
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Mở màn hình Cài đặt dịch vụ Vị trí của máy
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

/// Provider cung cấp LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// FutureProvider lấy vị trí hiện tại của người dùng (tự động fallback nếu cần)
final currentUserLocationProvider = FutureProvider<LocationResult>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.getCurrentPosition();
});
