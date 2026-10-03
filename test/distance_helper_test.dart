// ============================================================================
// File: test/distance_helper_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho distance_helper.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/utils/distance_helper.dart';

void main() {
  group('DistanceHelper Tests (Task 3.3)', () {
    test('calculateDistanceMeters returns 0 for identical points', () {
      final d = DistanceHelper.calculateDistanceMeters(
        lat1: 16.0544,
        lon1: 108.2022,
        lat2: 16.0544,
        lon2: 108.2022,
      );
      expect(d, equals(0.0));
    });

    test('calculateDistanceMeters computes accurate distance between Da Nang points', () {
      // 123 Nguyễn Văn Linh (16.0544, 108.2022) to 45 Lê Duẩn (16.0680, 108.2160)
      final distance = DistanceHelper.calculateDistanceMeters(
        lat1: 16.0544,
        lon1: 108.2022,
        lat2: 16.0680,
        lon2: 108.2160,
      );

      // Khoảng cách thực tế giữa 2 điểm này xấp xỉ ~2.1 km
      expect(distance, greaterThan(2000));
      expect(distance, lessThan(2400));
    });

    test('calculateDistanceKm converts meters to km correctly', () {
      final km = DistanceHelper.calculateDistanceKm(
        lat1: 16.0544,
        lon1: 108.2022,
        lat2: 16.0680,
        lon2: 108.2160,
      );
      expect(km, greaterThan(2.0));
      expect(km, lessThan(2.4));
    });

    test('formatDistance formats meters and kilometers properly', () {
      expect(DistanceHelper.formatDistance(0), equals('0 m'));
      expect(DistanceHelper.formatDistance(450.4), equals('450 m'));
      expect(DistanceHelper.formatDistance(999), equals('999 m'));
      expect(DistanceHelper.formatDistance(1000), equals('1.0 km'));
      expect(DistanceHelper.formatDistance(1250), equals('1.3 km'));
      expect(DistanceHelper.formatDistance(5400), equals('5.4 km'));
      expect(DistanceHelper.formatDistance(15600), equals('16 km'));
    });
  });
}
