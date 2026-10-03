// ============================================================================
// File: test/search_provider_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho search_provider.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/utils/distance_helper.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/providers/search_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Search & Distance Logic Tests (Task 3.4 & 3.9)', () {
    final refPoint = const LatLng(16.0544, 108.2022); // Đà Nẵng Center

    final barber1 = BarberProfileModel(
      uid: 'b1',
      displayName: 'Tiệm Cắt Gần Nhất',
      address: '100 Nguyễn Văn Linh',
      location: const GeoLocation(
        latitude: 16.0550,
        longitude: 108.2030,
      ), // ~100m
      hairstyleIds: ['undercut', 'side_part'],
    );

    final barber2 = BarberProfileModel(
      uid: 'b2',
      displayName: 'Tiệm Ở Xa Phù Hợp Tóc',
      address: '900 Ngô Quyền',
      location: const GeoLocation(
        latitude: 16.0800,
        longitude: 108.2300,
      ), // ~4km
      hairstyleIds: ['pompadour', 'layer_male'],
    );

    final barber3 = BarberProfileModel(
      uid: 'b3',
      displayName: 'Tiệm Trung Bình',
      address: '200 Lê Duẩn',
      location: const GeoLocation(
        latitude: 16.0680,
        longitude: 108.2160,
      ), // ~2km
      hairstyleIds: ['undercut'],
    );

    test('Computes distances and formats properly for all barbers', () {
      final barbers = [barber1, barber2, barber3];
      final processed = barbers.map((b) {
        final d = DistanceHelper.calculateDistanceMeters(
          lat1: refPoint.latitude,
          lon1: refPoint.longitude,
          lat2: b.location.latitude,
          lon2: b.location.longitude,
        );
        return BarberWithDistance(
          barber: b,
          distanceMeters: d,
          distanceFormatted: DistanceHelper.formatDistance(d),
          isMatchingHairstyle: false,
        );
      }).toList();

      processed.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      expect(processed[0].barber.uid, equals('b1'));
      expect(processed[1].barber.uid, equals('b3'));
      expect(processed[2].barber.uid, equals('b2'));
      expect(
        processed[0].distanceMeters,
        lessThan(processed[1].distanceMeters),
      );
    });

    test('Hairstyle filter prioritizes matching barbers at the top', () {
      final barbers = [barber1, barber2, barber3];
      const selectedStyle = 'pompadour';

      final processed = barbers.map((b) {
        final d = DistanceHelper.calculateDistanceMeters(
          lat1: refPoint.latitude,
          lon1: refPoint.longitude,
          lat2: b.location.latitude,
          lon2: b.location.longitude,
        );
        final isMatch = b.hairstyleIds.contains(selectedStyle);
        return BarberWithDistance(
          barber: b,
          distanceMeters: d,
          distanceFormatted: DistanceHelper.formatDistance(d),
          isMatchingHairstyle: isMatch,
        );
      }).toList();

      processed.sort((a, b) {
        if (a.isMatchingHairstyle && !b.isMatchingHairstyle) return -1;
        if (!a.isMatchingHairstyle && b.isMatchingHairstyle) return 1;
        return a.distanceMeters.compareTo(b.distanceMeters);
      });

      // barber2 matches pompadour, so it should be prioritized first despite being further away
      expect(processed.first.barber.uid, equals('b2'));
      expect(processed.first.isMatchingHairstyle, isTrue);

      // Remaining non-matching barbers should still be sorted by distance
      expect(processed[1].barber.uid, equals('b1'));
      expect(processed[2].barber.uid, equals('b3'));
    });

    test('Search query matches displayName or address case-insensitively', () {
      final barbers = [barber1, barber2, barber3];
      const query = 'lê duẩn';

      final matched = barbers.where((b) {
        final q = query.toLowerCase();
        return b.displayName.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q);
      }).toList();

      expect(matched.length, equals(1));
      expect(matched.first.uid, equals('b3'));
    });
  });
}
