import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/utils/date_formatter.dart';
import 'package:hairfit_ai/core/utils/distance_helper.dart';
import 'package:hairfit_ai/core/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('Email validator accepts valid emails and rejects invalid ones', () {
      expect(Validators.email('test@gmail.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co'), isNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('abcdef123'), isNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('Confirm password validator matches passwords correctly', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('secret123', 'secret456'), isNotNull);
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
    });

    test('Phone validator checks Vietnamese phone numbers', () {
      expect(Validators.phone('0912345678'), isNull);
      expect(Validators.phone('0387654321'), isNull);
      expect(Validators.phone('0123456789'), isNotNull); // Đầu số không hợp lệ
      expect(Validators.phone('123456'), isNotNull);
    });

    test('Service duration validator requires multiples of 30 minutes', () {
      expect(Validators.serviceDuration(30), isNull);
      expect(Validators.serviceDuration(60), isNull);
      expect(Validators.serviceDuration(90), isNull);
      expect(Validators.serviceDuration(45), isNotNull);
      expect(Validators.serviceDuration(0), isNotNull);
    });
  });

  group('DateFormatter Test', () {
    test('formatCurrency formats Vietnamese dong correctly', () {
      final formatted = DateFormatter.formatCurrency(70000);
      expect(formatted.contains('70.000'), isTrue);
      expect(formatted.contains('đ'), isTrue);
    });

    test('formatPriceRange formats range correctly', () {
      expect(DateFormatter.formatPriceRange(70000, 70000).contains('70.000'), isTrue);
      final range = DateFormatter.formatPriceRange(70000, 150000);
      expect(range.contains('70.000'), isTrue);
      expect(range.contains('150.000'), isTrue);
    });

    test('toIsoDateString and parseIsoDate work symmetrically', () {
      final dt = DateTime(2026, 10, 15);
      final isoStr = DateFormatter.toIsoDateString(dt);
      expect(isoStr, equals('2026-10-15'));

      final parsed = DateFormatter.parseIsoDate(isoStr);
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2026));
      expect(parsed.month, equals(10));
      expect(parsed.day, equals(15));
    });
  });

  group('DistanceHelper Test', () {
    test('calculateDistanceKm calculates distance between coordinates correctly', () {
      // Khoảng cách giữa 2 điểm mẫu tại Đà Nẵng: (16.0544, 108.2022) và (16.0680, 108.2160)
      final distanceKm = DistanceHelper.calculateDistanceKm(
        startLatitude: 16.0544,
        startLongitude: 108.2022,
        endLatitude: 16.0680,
        endLongitude: 108.2160,
      );

      expect(distanceKm, greaterThan(1.0));
      expect(distanceKm, lessThan(3.0));
    });

    test('formatDistance displays m for < 1km and km for >= 1km', () {
      expect(DistanceHelper.formatDistance(0.45), equals('450 m'));
      expect(DistanceHelper.formatDistance(1.234), equals('1.2 km'));
    });
  });
}
