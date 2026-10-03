// ============================================================================
// File: test/booking_widgets_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho booking_widgets.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:hairfit_ai/features/booking/data/slot_service.dart';
import 'package:hairfit_ai/features/booking/presentation/widgets/booking_summary.dart';
import 'package:hairfit_ai/features/booking/presentation/widgets/date_picker.dart';
import 'package:hairfit_ai/features/booking/presentation/widgets/service_selector.dart';
import 'package:hairfit_ai/features/booking/presentation/widgets/time_slot_grid.dart';
import 'package:hairfit_ai/models/appointment_model.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/models/service_model.dart';

void main() {
  group('Booking & Appointment Widgets Unit Tests (Week 4)', () {
    const sampleService = ServiceModel(
      id: 'svc_01',
      name: 'Combo Cắt Tóc Đẳng Cấp',
      price: 100000,
      durationMinutes: 30,
    );

    final sampleBarber = BarberProfileModel(
      uid: 'barber_test_widget',
      displayName: 'Tiệm Cắt Tóc Hoàng Gia',
      address: '100 Lê Duẩn, Đà Nẵng',
      location: const GeoLocation(latitude: 16.06, longitude: 108.21),
      services: const [sampleService],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '20:00',
        ),
        'sun': const DayWorkingHours(
          closed: true,
          open: '08:00',
          close: '20:00',
        ),
      },
    );

    testWidgets(
      'ServiceSelector renders service name, price and responds to selection',
      (tester) async {
        ServiceModel? selected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ServiceSelector(
                services: [sampleService],
                selectedService: null,
                onServiceSelected: (svc) => selected = svc,
              ),
            ),
          ),
        );

        expect(find.text('Combo Cắt Tóc Đẳng Cấp'), findsOneWidget);
        expect(find.textContaining('100.000'), findsOneWidget);

        await tester.tap(find.text('Combo Cắt Tóc Đẳng Cấp'));
        await tester.pump();

        expect(selected?.id, 'svc_01');
      },
    );

    testWidgets(
      'BookingDatePicker renders horizontally and triggers callback',
      (tester) async {
        DateTime? pickedDate;
        final today = DateTime.now();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingDatePicker(
                selectedDate: today,
                barber: sampleBarber,
                onDateSelected: (d) => pickedDate = d,
              ),
            ),
          ),
        );

        expect(find.text('2. Chọn ngày hẹn'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // Nhấn vào một item ngày (tìm widget InkWell trong list)
        final inkWells = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsWidgets);
        await tester.tap(inkWells.first);
        await tester.pump();
        expect(pickedDate, isNotNull);
      },
    );

    testWidgets(
      'TimeSlotGrid renders slots with available and selected states',
      (tester) async {
        AvailableSlot? chosenSlot;
        final slot1 = AvailableSlot(
          startTime: '09:00',
          endTime: '09:30',
          isAvailable: true,
          slotIds: ['barber_1_2026-10-10_09-00'],
          startTimestamp: DateTime(2026, 10, 10, 9, 0),
          endTimestamp: DateTime(2026, 10, 10, 9, 30),
        );
        final slot2 = AvailableSlot(
          startTime: '09:30',
          endTime: '10:00',
          isAvailable: false,
          slotIds: ['barber_1_2026-10-10_09-30'],
          unavailabilityReason: 'Đã có người đặt',
          startTimestamp: DateTime(2026, 10, 10, 9, 30),
          endTimestamp: DateTime(2026, 10, 10, 10, 0),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeSlotGrid(
                slots: [slot1, slot2],
                selectedSlot: null,
                isLoading: false,
                onSlotSelected: (s) => chosenSlot = s,
              ),
            ),
          ),
        );

        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('09:30'), findsOneWidget);
        expect(find.text('Trống'), findsOneWidget);
        expect(find.text('Đã đặt'), findsOneWidget);

        // Nhấn vào slot trống
        await tester.tap(find.text('09:00'));
        await tester.pump();
        expect(chosenSlot?.startTime, '09:00');

        // Nhấn vào slot đã đặt (không trigger callback)
        chosenSlot = null;
        await tester.tap(find.text('09:30'));
        await tester.pump();
        expect(chosenSlot, isNull);
      },
    );

    testWidgets('BookingSummary renders all details and accepts note input', (
      tester,
    ) async {
      String typedNote = '';

      final slot = AvailableSlot(
        startTime: '10:00',
        endTime: '10:30',
        isAvailable: true,
        slotIds: ['barber_1_2026-10-10_10-00'],
        startTimestamp: DateTime(2026, 10, 10, 10, 0),
        endTimestamp: DateTime(2026, 10, 10, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookingSummary(
                barber: sampleBarber,
                service: sampleService,
                selectedDate: DateTime(2026, 10, 10),
                selectedSlot: slot,
                note: '',
                onNoteChanged: (n) => typedNote = n,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tiệm Cắt Tóc Hoàng Gia'), findsOneWidget);
      expect(find.text('10:00 - 10:30'), findsOneWidget);
      expect(find.textContaining('100.000'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Cắt tỉa gọn gàng');
      expect(typedNote, 'Cắt tỉa gọn gàng');
    });

    testWidgets(
      'AppointmentCard in Customer View displays barber info and cancel button when allowed',
      (tester) async {
        bool cancelTapped = false;

        // Lịch hẹn cách hiện tại 2 tiếng (canCustomerCancel() = true)
        final futureStart = DateTime.now().add(const Duration(hours: 2));
        final futureEnd = futureStart.add(const Duration(minutes: 30));

        final appointment = AppointmentModel(
          id: 'apt_test_01',
          customerId: 'cust_01',
          customerName: 'Nguyễn Văn A',
          barberId: 'barber_01',
          barberName: '30Shine Đà Nẵng',
          serviceId: 'svc_01',
          serviceName: 'Cắt tóc tiêu chuẩn',
          price: 90000,
          durationMinutes: 30,
          date: '2026-10-10',
          startTime: '14:00',
          endTime: '14:30',
          startTimestamp: futureStart,
          endTimestamp: futureEnd,
          slotIds: const ['slot_1'],
          status: AppointmentStatus.pending,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCard(
                appointment: appointment,
                isBarberView: false,
                onCancel: () => cancelTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('30Shine Đà Nẵng'), findsOneWidget);
        expect(
          find.text('Dịch vụ: Cắt tóc tiêu chuẩn (30 phút)'),
          findsOneWidget,
        );
        expect(find.textContaining('90.000'), findsOneWidget);
        expect(find.text('Hủy lịch hẹn'), findsOneWidget);

        await tester.tap(find.text('Hủy lịch hẹn'));
        await tester.pump();
        expect(cancelTapped, isTrue);
      },
    );

    testWidgets(
      'AppointmentCard in Barber View shows confirm and reject buttons for pending',
      (tester) async {
        bool confirmTapped = false;
        bool rejectTapped = false;

        final appointment = AppointmentModel(
          id: 'apt_test_02',
          customerId: 'cust_02',
          customerName: 'Trần Văn Nam',
          barberId: 'barber_01',
          barberName: '30Shine Đà Nẵng',
          serviceId: 'svc_01',
          serviceName: 'Cắt tóc tiêu chuẩn',
          price: 90000,
          durationMinutes: 30,
          date: '2026-10-10',
          startTime: '15:00',
          endTime: '15:30',
          startTimestamp: DateTime(2026, 10, 10, 15, 0),
          endTimestamp: DateTime(2026, 10, 10, 15, 30),
          slotIds: const ['slot_2'],
          status: AppointmentStatus.pending,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCard(
                appointment: appointment,
                isBarberView: true,
                onConfirm: () => confirmTapped = true,
                onReject: () => rejectTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Khách hàng: Trần Văn Nam'), findsOneWidget);
        expect(find.text('Tiếp nhận'), findsOneWidget);
        expect(find.text('Từ chối'), findsOneWidget);

        await tester.tap(find.text('Tiếp nhận'));
        await tester.pump();
        expect(confirmTapped, isTrue);

        await tester.tap(find.text('Từ chối'));
        await tester.pump();
        expect(rejectTapped, isTrue);
      },
    );
  });
}
