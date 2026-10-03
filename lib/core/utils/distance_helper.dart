// ============================================================================
// File: lib/core/utils/distance_helper.dart
// Mục đích: Cung cấp các hàm tiện ích (Utility/Helper) dùng chung.
// Kết cấu:
//  - Các hàm logic nhỏ, tính toán, format dữ liệu độc lập với UI.
// ============================================================================

import 'dart:math' as math;

/// Utility tính toán khoảng cách địa lý và định dạng khoảng cách (Task 3.3)
class DistanceHelper {
  DistanceHelper._();

  /// Bán kính trái đất tính bằng mét (Earth radius in meters)
  static const double earthRadiusMeters = 6371000.0;

  /// Tính khoảng cách giữa hai toạ độ (lat1, lon1) và (lat2, lon2) theo công thức Haversine.
  /// Kết quả trả về tính theo mét (meters).
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    // Chuyển đổi độ sang radian
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final deltaPhi = (lat2 - lat1) * math.pi / 180.0;
    final deltaLambda = (lon2 - lon1) * math.pi / 180.0;

    // Công thức Haversine
    final a =
        math.sin(deltaPhi / 2.0) * math.sin(deltaPhi / 2.0) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2.0) *
            math.sin(deltaLambda / 2.0);

    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));

    return earthRadiusMeters * c;
  }

  /// Tính khoảng cách tính theo Kilomet (km)
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return calculateDistanceMeters(
          lat1: lat1,
          lon1: lon1,
          lat2: lat2,
          lon2: lon2,
        ) /
        1000.0;
  }

  /// Định dạng khoảng cách thân thiện với người dùng Việt Nam
  /// Ví dụ:
  /// - 450m -> "450 m"
  /// - 1200m -> "1.2 km"
  /// - 15800m -> "15.8 km"
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 0) return '0 m';

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000.0;
      if (km < 10) {
        return '${km.toStringAsFixed(1)} km';
      } else {
        return '${km.toStringAsFixed(0)} km';
      }
    }
  }
}
