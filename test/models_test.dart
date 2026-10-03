// ============================================================================
// File: test/models_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho models.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/models/appointment_model.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/models/booked_slot_model.dart';
import 'package:hairfit_ai/models/hairstyle_model.dart';
import 'package:hairfit_ai/models/service_model.dart';
import 'package:hairfit_ai/models/user_model.dart';

void main() {
  group('UserModel Test', () {
    test('UserRole converts from string and to string correctly', () {
      expect(UserRole.fromString('customer'), equals(UserRole.customer));
      expect(UserRole.fromString('barber'), equals(UserRole.barber));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('UNKNOWN'), equals(UserRole.customer));
    });

    test('UserModel serializes and deserializes accurately', () {
      final user = UserModel(
        uid: 'user_123',
        email: 'test@hairfit.ai',
        displayName: 'Nguyễn Văn A',
        role: UserRole.customer,
        isBlocked: false,
      );

      final map = user.toMap();
      expect(map['uid'], equals('user_123'));
      expect(map['email'], equals('test@hairfit.ai'));
      expect(map['role'], equals('customer'));
      expect(map['isBlocked'], equals(false));

      final fromMap = UserModel.fromMap(map);
      expect(fromMap.uid, equals(user.uid));
      expect(fromMap.displayName, equals(user.displayName));
      expect(fromMap.isCustomer, isTrue);
    });
  });

  group('ServiceModel Test', () {
    test('Calculates slotCount based on 30-minute block correctly', () {
      const s1 = ServiceModel(
        id: '1',
        name: 'Cắt',
        price: 70000,
        durationMinutes: 30,
      );
      expect(s1.slotCount, equals(1));

      const s2 = ServiceModel(
        id: '2',
        name: 'Combo',
        price: 120000,
        durationMinutes: 60,
      );
      expect(s2.slotCount, equals(2));

      const s3 = ServiceModel(
        id: '3',
        name: 'Uốn',
        price: 180000,
        durationMinutes: 90,
      );
      expect(s3.slotCount, equals(3));
    });
  });

  group('HairstyleModel Test', () {
    test('matchesFaceShape correctly evaluates matching shapes', () {
      const style = HairstyleModel(
        id: 'undercut',
        name: 'Undercut',
        description: 'Kiểu tóc undercut',
        imageUrl: 'https://example.com/img.jpg',
        faceShapes: ['round', 'square', 'oval'],
        tags: ['nam', 'gọn'],
      );

      expect(style.matchesFaceShape('round'), isTrue);
      expect(style.matchesFaceShape('square'), isTrue);
      expect(style.matchesFaceShape('heart'), isFalse);
    });
  });

  group('BarberProfileModel Test', () {
    test('Calculates priceMin and priceMax from services automatically', () {
      final barber = BarberProfileModel(
        uid: 'barber_test',
        displayName: 'Test Barber',
        address: 'Đà Nẵng',
        location: const GeoLocation(latitude: 16.0, longitude: 108.0),
        services: const [
          ServiceModel(
            id: 's1',
            name: 'Dịch vụ 1',
            price: 80000,
            durationMinutes: 30,
          ),
          ServiceModel(
            id: 's2',
            name: 'Dịch vụ 2',
            price: 150000,
            durationMinutes: 60,
          ),
          ServiceModel(
            id: 's3',
            name: 'Dịch vụ 3',
            price: 120000,
            durationMinutes: 60,
          ),
        ],
      );

      final map = barber.toMap();
      expect(map['priceMin'], equals(80000));
      expect(map['priceMax'], equals(150000));
    });
  });

  group('AppointmentModel Test', () {
    test('canCustomerCancel returns true if >= 30 mins before start, false otherwise', () {
      final now = DateTime.now();

      // Trường hợp 1: Còn 60 phút nữa -> Hủy được
      final appointmentFuture = AppointmentModel(
        id: 'app_1',
        customerId: 'c1',
        barberId: 'b1',
        barberName: 'Barber A',
        customerName: 'Customer B',
        serviceId: 's1',
        serviceName: 'Cắt',
        price: 80000,
        durationMinutes: 30,
        date: '2026-10-10',
        startTime: '10:00',
        endTime: '10:30',
        startTimestamp: now.add(const Duration(minutes: 60)),
        endTimestamp: now.add(const Duration(minutes: 90)),
        slotIds: ['b1_2026-10-10_10-00'],
        status: AppointmentStatus.pending,
      );
      expect(appointmentFuture.canCustomerCancel(), isTrue);

      // Trường hợp 2: Chỉ còn 15 phút nữa -> Không hủy được
      final appointmentTooLate = appointmentFuture.copyWith(
        startTimestamp: now.add(const Duration(minutes: 15)),
      );
      expect(appointmentTooLate.canCustomerCancel(), isFalse);

      // Trường hợp 3: Đã completed -> Không hủy được
      final appointmentCompleted = appointmentFuture.copyWith(
        status: AppointmentStatus.completed,
      );
      expect(appointmentCompleted.canCustomerCancel(), isFalse);
    });
  });

  group('BookedSlotModel Test', () {
    test(
      'generateSlotId follows standard format: {barberId}_{yyyy-MM-dd}_{HH-mm}',
      () {
        final slotId = BookedSlotModel.generateSlotId(
          barberId: 'barber_456',
          date: '2026-10-10',
          time: '09:00',
        );
        expect(slotId, equals('barber_456_2026-10-10_09-00'));
      },
    );
  });
}
