// ============================================================================
// File: test/core_utils_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho core_utils.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/utils/date_formatter.dart';
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
      expect(
        DateFormatter.formatPriceRange(70000, 70000).contains('70.000'),
        isTrue,
      );
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
}
