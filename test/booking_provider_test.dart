import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/features/booking/data/slot_service.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/models/service_model.dart';
import 'package:hairfit_ai/providers/appointment_provider.dart';
import 'package:hairfit_ai/providers/booking_provider.dart';

void main() {
  group('Booking & Appointment Providers Unit Tests (Tasks 4.6, 4.11)', () {
    const service1 = ServiceModel(
      id: 'svc_1',
      name: 'Cắt tóc nam',
      price: 80000,
      durationMinutes: 30,
    );
    const service2 = ServiceModel(
      id: 'svc_2',
      name: 'Combo cắt + gội',
      price: 150000,
      durationMinutes: 60,
    );

    final barber = BarberProfileModel(
      uid: 'barber_123',
      displayName: 'Tiệm Hoàng',
      address: 'Đà Nẵng',
      location: const GeoLocation(latitude: 16.0, longitude: 108.0),
      services: const [service1, service2],
      workingHours: {
        'mon': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
      },
    );

    test('BookingState canSubmit correctly checks requirements', () {
      final stateEmpty = BookingState();
      expect(stateEmpty.canSubmit, isFalse);

      final stateWithService = stateEmpty.copyWith(selectedService: barber.services.first);
      expect(stateWithService.canSubmit, isFalse);

      final unavailableSlot = AvailableSlot(
        startTime: '09:00',
        endTime: '09:30',
        isAvailable: false,
        slotIds: const ['slot_1'],
        startTimestamp: DateTime(2026, 10, 10, 9, 0),
        endTimestamp: DateTime(2026, 10, 10, 9, 30),
      );

      final stateWithUnavailableSlot = stateWithService.copyWith(
        selectedSlot: unavailableSlot,
      );
      expect(stateWithUnavailableSlot.canSubmit, isFalse);

      final availableSlot = AvailableSlot(
        startTime: '10:00',
        endTime: '10:30',
        isAvailable: true,
        slotIds: const ['slot_2'],
        startTimestamp: DateTime(2026, 10, 10, 10, 0),
        endTimestamp: DateTime(2026, 10, 10, 10, 30),
      );

      final stateReady = stateWithService.copyWith(
        selectedSlot: availableSlot,
      );
      expect(stateReady.canSubmit, isTrue);

      final stateSubmitting = stateReady.copyWith(isSubmitting: true);
      expect(stateSubmitting.canSubmit, isFalse);
    });

    test('AppointmentActionState copyWith and clearMessages work as expected', () {
      const initial = AppointmentActionState();
      expect(initial.isLoading, isFalse);
      expect(initial.errorMessage, isNull);
      expect(initial.successMessage, isNull);

      final withSuccess = initial.copyWith(
        isLoading: false,
        successMessage: 'Thành công!',
      );
      expect(withSuccess.successMessage, 'Thành công!');

      final cleared = withSuccess.copyWith(clearMessages: true);
      expect(cleared.successMessage, isNull);
    });
  });
}
