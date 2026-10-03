// ============================================================================
// File: test/barber_appointments_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho màn hình BarberAppointmentsScreen.
// Kết cấu:
//  - Sử dụng flutter_test và Riverpod ProviderScope để test BarberAppointmentsScreen.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/widgets/empty_state.dart';
import 'package:hairfit_ai/features/appointments/presentation/barber_appointments_screen.dart';
import 'package:hairfit_ai/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:hairfit_ai/models/appointment_model.dart';
import 'package:hairfit_ai/providers/appointment_provider.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets('BarberAppointmentsScreen displays EmptyState when list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<AppointmentModel>[]),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quản Lý Lịch Hẹn'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Không có yêu cầu đặt lịch nào đang chờ'), findsOneWidget);
  });

  testWidgets('BarberAppointmentsScreen displays appointment cards when list has pending', (
    tester,
  ) async {
    final now = DateTime.now();
    final sampleAppointment = AppointmentModel(
      id: 'app_1',
      customerId: 'cust_1',
      barberId: 'barber_1',
      barberName: 'Thợ Cắt Tóc A',
      customerName: 'Nguyễn Văn Khách',
      serviceId: 'svc_1',
      serviceName: 'Cắt tóc nam basic',
      price: 80000,
      durationMinutes: 30,
      date: '2026-10-02',
      startTime: '10:00',
      endTime: '10:30',
      startTimestamp: now.add(const Duration(hours: 2)),
      endTimestamp: now.add(const Duration(hours: 2, minutes: 30)),
      slotIds: const ['slot_1'],
      status: AppointmentStatus.pending,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<AppointmentModel>[sampleAppointment]),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quản Lý Lịch Hẹn'), findsOneWidget);
    expect(find.byType(AppointmentCard), findsOneWidget);
    expect(find.text('Khách hàng: Nguyễn Văn Khách'), findsOneWidget);
    expect(find.text('Tiếp nhận'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);

    final cardRect = tester.getRect(find.byType(AppointmentCard));
    debugPrint('*** Card Rect: $cardRect ***');
    expect(cardRect.height, greaterThan(50));
    expect(cardRect.width, greaterThan(100));
  });

  testWidgets('BarberAppointmentsScreen when stream is empty (uid is null)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pump();

    // Notice: with Stream.empty(), Riverpod StreamProvider stays in loading state (shimmer)!
    expect(find.byType(Shimmer), findsWidgets);
  });

  testWidgets('BarberAppointmentsScreen transitions from loading to data and shows cards', (
    tester,
  ) async {
    final now = DateTime.now();
    final sampleAppointment = AppointmentModel(
      id: 'app_1',
      customerId: 'cust_1',
      barberId: 'barber_1',
      barberName: 'Thợ Cắt Tóc A',
      customerName: 'Nguyễn Văn Khách',
      serviceId: 'svc_1',
      serviceName: 'Cắt tóc nam basic',
      price: 80000,
      durationMinutes: 30,
      date: '2026-10-02',
      startTime: '10:00',
      endTime: '10:30',
      startTimestamp: now.add(const Duration(hours: 2)),
      endTimestamp: now.add(const Duration(hours: 2, minutes: 30)),
      slotIds: const ['slot_1'],
      status: AppointmentStatus.pending,
    );

    final streamController = StreamController<List<AppointmentModel>>.broadcast();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => streamController.stream,
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    // Initial state: loading
    await tester.pump();
    expect(find.byType(Shimmer), findsWidgets);

    // Emit 2 pending appointments
    streamController.add([sampleAppointment, sampleAppointment.copyWith(id: 'app_2')]);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Quản Lý Lịch Hẹn'), findsOneWidget);
    expect(find.byType(AppointmentCard), findsNWidgets(2));
    expect(find.text('Khách hàng: Nguyễn Văn Khách'), findsNWidgets(2));

    await streamController.close();
  });

  testWidgets('BarberAppointmentsScreen renders safely with empty fields', (
    tester,
  ) async {
    final now = DateTime.now();
    final edgeCaseAppointment = AppointmentModel(
      id: 'app_empty',
      customerId: '',
      barberId: '',
      barberName: '',
      customerName: '',
      serviceId: '',
      serviceName: '',
      price: 0,
      durationMinutes: 0,
      date: '',
      startTime: '',
      endTime: '',
      startTimestamp: now,
      endTimestamp: now,
      slotIds: const [],
      status: AppointmentStatus.pending,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<AppointmentModel>[edgeCaseAppointment]),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quản Lý Lịch Hẹn'), findsOneWidget);
    expect(find.byType(AppointmentCard), findsOneWidget);
    expect(find.text('Khách hàng: Khách hàng'), findsOneWidget);
  });

  testWidgets('BarberAppointmentsScreen switches between tabs cleanly', (
    tester,
  ) async {
    final now = DateTime.now();
    final pendingApp = AppointmentModel(
      id: 'app_pending',
      customerId: 'cust_1',
      barberId: 'barber_1',
      barberName: 'Thợ A',
      customerName: 'Khách Pending',
      serviceId: 'svc_1',
      serviceName: 'Cắt tóc',
      price: 80000,
      durationMinutes: 30,
      date: '2026-10-02',
      startTime: '10:00',
      endTime: '10:30',
      startTimestamp: now,
      endTimestamp: now.add(const Duration(minutes: 30)),
      slotIds: const ['slot_1'],
      status: AppointmentStatus.pending,
    );

    final confirmedApp = pendingApp.copyWith(
      id: 'app_confirmed',
      customerName: 'Khách Confirmed',
      status: AppointmentStatus.confirmed,
    );

    final completedApp = pendingApp.copyWith(
      id: 'app_completed',
      customerName: 'Khách Completed',
      status: AppointmentStatus.completed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<AppointmentModel>[
              pendingApp,
              confirmedApp,
              completedApp,
            ]),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tab 0: Pending
    expect(find.text('Khách hàng: Khách Pending'), findsOneWidget);
    expect(find.text('Khách hàng: Khách Confirmed'), findsNothing);

    // Tap Tab 1: Confirmed
    await tester.tap(find.text('Đã nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Khách hàng: Khách Confirmed'), findsOneWidget);
    expect(find.text('Khách hàng: Khách Pending'), findsNothing);

    // Tap Tab 2: History
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();
    expect(find.text('Khách hàng: Khách Completed'), findsOneWidget);
  });

  testWidgets('BarberAppointmentsScreen renders navigation actions and bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barberAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<AppointmentModel>[]),
          ),
        ],
        child: const MaterialApp(
          home: BarberAppointmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar navigation icons
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_outlined), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.storefront_outlined), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Verify BottomNavigationBar items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Cửa tiệm'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });
}

