import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/features/booking/data/slot_service.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/models/booked_slot_model.dart';
import 'package:hairfit_ai/models/service_model.dart';

void main() {
  group('SlotService Unit Tests (Tasks 4.1, 4.2, 4.3)', () {
    late SlotService slotService;
    late BarberProfileModel sampleBarber;
    late ServiceModel service30m;
    late ServiceModel service60m;
    late ServiceModel service90m;

    setUp(() {
      slotService = const SlotService();

      service30m = const ServiceModel(
        id: 'svc_cut',
        name: 'Cắt tóc nam tiêu chuẩn',
        price: 80000,
        durationMinutes: 30,
      );

      service60m = const ServiceModel(
        id: 'svc_combo',
        name: 'Combo Cắt + Gội + Vuốt sáp',
        price: 150000,
        durationMinutes: 60,
      );

      service90m = const ServiceModel(
        id: 'svc_perm',
        name: 'Uốn tóc Premlock',
        price: 350000,
        durationMinutes: 90,
      );

      sampleBarber = BarberProfileModel(
        uid: 'barber_test_01',
        displayName: 'Tiệm Cắt Tóc Test',
        address: '123 Nguyễn Văn Linh, Đà Nẵng',
        location: const GeoLocation(latitude: 16.06, longitude: 108.21),
        services: [service30m, service60m, service90m],
        workingHours: {
          'mon': const DayWorkingHours(closed: false, open: '09:00', close: '12:00'), // 3 tiếng = 6 slots 30m
          'tue': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
          'wed': const DayWorkingHours(closed: false, open: '09:00', close: '18:00'),
          'thu': const DayWorkingHours(closed: false, open: '09:00', close: '18:00'),
          'fri': const DayWorkingHours(closed: false, open: '09:00', close: '18:00'),
          'sat': const DayWorkingHours(closed: false, open: '09:00', close: '18:00'),
          'sun': const DayWorkingHours(closed: true, open: '09:00', close: '18:00'), // Chủ nhật nghỉ
        },
        exceptions: [
          const WorkException(
            date: '2026-10-15',
            closed: true,
            reason: 'Nghỉ bảo trì tiệm',
          ),
        ],
      );
    });

    test('weekdayToKey correctly maps all weekdays', () {
      expect(SlotService.weekdayToKey(DateTime.monday), 'mon');
      expect(SlotService.weekdayToKey(DateTime.tuesday), 'tue');
      expect(SlotService.weekdayToKey(DateTime.wednesday), 'wed');
      expect(SlotService.weekdayToKey(DateTime.thursday), 'thu');
      expect(SlotService.weekdayToKey(DateTime.friday), 'fri');
      expect(SlotService.weekdayToKey(DateTime.saturday), 'sat');
      expect(SlotService.weekdayToKey(DateTime.sunday), 'sun');
    });

    test('timeToMinutes and minutesToTime work symmetrically', () {
      expect(SlotService.timeToMinutes('09:00'), 540);
      expect(SlotService.timeToMinutes('12:30'), 750);
      expect(SlotService.minutesToTime(540), '09:00');
      expect(SlotService.minutesToTime(750), '12:30');
    });

    test('Returns empty slots when barber is closed on that weekday (Sunday)', () {
      // 2026-10-11 là Chủ nhật
      final sunday = DateTime(2026, 10, 11);
      final currentMockTime = DateTime(2026, 10, 10, 8, 0);

      final slots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: sunday,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );

      expect(slots, isEmpty);
    });

    test('Returns empty slots when selected date matches closed exception (Task 4.2)', () {
      // 2026-10-15 có trong exceptions (closed: true)
      final exceptionDate = DateTime(2026, 10, 15);
      final currentMockTime = DateTime(2026, 10, 10, 8, 0);

      final slots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: exceptionDate,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );

      expect(slots, isEmpty);
    });

    test('Returns empty slots when date is in the past or > 30 days ahead', () {
      final currentMockTime = DateTime(2026, 10, 10, 10, 0);
      final pastDate = DateTime(2026, 10, 9);
      final tooFarDate = DateTime(2026, 11, 15); // > 30 ngày

      final pastSlots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: pastDate,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );
      expect(pastSlots, isEmpty);

      final farSlots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: tooFarDate,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );
      expect(farSlots, isEmpty);
    });

    test('Generates correct count of 30-min slots for working hours 09:00 - 12:00 (Task 4.1)', () {
      // 2026-10-12 là Thứ hai: mở 09:00, đóng 12:00 (180 phút = 6 slots 30m)
      final monday = DateTime(2026, 10, 12);
      final currentMockTime = DateTime(2026, 10, 10, 8, 0); // Đặt từ hôm trước

      final slots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: monday,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );

      // Slots: 09:00, 09:30, 10:00, 10:30, 11:00, 11:30 (tổng 6)
      expect(slots.length, 6);
      expect(slots.first.startTime, '09:00');
      expect(slots.first.endTime, '09:30');
      expect(slots.last.startTime, '11:30');
      expect(slots.last.endTime, '12:00');
      expect(slots.every((s) => s.isAvailable), isTrue);
    });

    test('Handles multi-slot service (60m = 2 slots) correctly (Task 4.3)', () {
      // 09:00 -> 12:00 với 60 phút
      // Các slot bắt đầu có thể: 09:00-10:00, 09:30-10:30, 10:00-11:00, 10:30-11:30, 11:00-12:00 (5 vị trí)
      final monday = DateTime(2026, 10, 12);
      final currentMockTime = DateTime(2026, 10, 10, 8, 0);

      final slots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: monday,
        selectedService: service60m,
        existingBookedSlots: [],
        currentTime: currentMockTime,
      );

      expect(slots.length, 5);
      expect(slots.first.startTime, '09:00');
      expect(slots.first.endTime, '10:00');
      expect(slots.first.slotIds.length, 2);
      expect(slots.first.slotIds, [
        'barber_test_01_2026-10-12_09-00',
        'barber_test_01_2026-10-12_09-30',
      ]);
    });

    test('Enforces lead time rule (30 minutes ahead) for same-day bookings', () {
      // Đặt cho ngày hôm nay lúc 09:40
      // Lead time cutoff là 09:40 + 30m = 10:10
      // Khung giờ 09:00, 09:30, 10:00 phải bị đánh dấu không khả dụng
      // Khung giờ từ 10:30 trở đi mới khả dụng
      final monday = DateTime(2026, 10, 12);
      final sameDayTime = DateTime(2026, 10, 12, 9, 40);

      final slots = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: monday,
        selectedService: service30m,
        existingBookedSlots: [],
        currentTime: sameDayTime,
      );

      expect(slots.length, 6);
      expect(slots[0].startTime, '09:00');
      expect(slots[0].isAvailable, isFalse); // < 09:40 (quá khứ)

      expect(slots[1].startTime, '09:30');
      expect(slots[1].isAvailable, isFalse); // < 09:40 (quá khứ)

      expect(slots[2].startTime, '10:00');
      expect(slots[2].isAvailable, isFalse); // < 10:10 (sát giờ < 30m)

      expect(slots[3].startTime, '10:30');
      expect(slots[3].isAvailable, isTrue); // >= 10:10 (hợp lệ)

      expect(slots[4].startTime, '11:00');
      expect(slots[4].isAvailable, isTrue);

      expect(slots[5].startTime, '11:30');
      expect(slots[5].isAvailable, isTrue);
    });

    test('Correctly marks slots unavailable when already booked in existingBookedSlots', () {
      final monday = DateTime(2026, 10, 12);
      final currentMockTime = DateTime(2026, 10, 10, 8, 0);

      // Giả sử slot 10:00 đã có người đặt
      final booked = [
        BookedSlotModel(
          id: 'barber_test_01_2026-10-12_10-00',
          barberId: 'barber_test_01',
          date: '2026-10-12',
          time: '10:00',
          appointmentId: 'apt_123',
          startTimestamp: DateTime(2026, 10, 12, 10, 0),
        ),
      ];

      // Với dịch vụ 30 phút: chỉ slot 10:00 bị khóa
      final slots30 = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: monday,
        selectedService: service30m,
        existingBookedSlots: booked,
        currentTime: currentMockTime,
      );

      final slot1000 = slots30.firstWhere((s) => s.startTime == '10:00');
      expect(slot1000.isAvailable, isFalse);
      expect(slot1000.unavailabilityReason, 'Đã có người đặt');

      final slot0930 = slots30.firstWhere((s) => s.startTime == '09:30');
      expect(slot0930.isAvailable, isTrue);

      // Với dịch vụ 60 phút: cả slot 09:30-10:30 VÀ 10:00-11:00 đều bị khóa vì đều chạm vào 10:00!
      final slots60 = slotService.generateAvailableSlots(
        barberProfile: sampleBarber,
        selectedDate: monday,
        selectedService: service60m,
        existingBookedSlots: booked,
        currentTime: currentMockTime,
      );

      final slot60_0930 = slots60.firstWhere((s) => s.startTime == '09:30');
      final slot60_1000 = slots60.firstWhere((s) => s.startTime == '10:00');
      final slot60_1030 = slots60.firstWhere((s) => s.startTime == '10:30');

      expect(slot60_0930.isAvailable, isFalse); // Cần 09:30 VÀ 10:00
      expect(slot60_1000.isAvailable, isFalse); // Cần 10:00 VÀ 10:30
      expect(slot60_1030.isAvailable, isTrue); // Cần 10:30 VÀ 11:00 (trống!)
    });
  });
}
