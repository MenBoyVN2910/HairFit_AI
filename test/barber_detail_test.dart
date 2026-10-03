import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/features/ai_consult/data/hairstyle_repository.dart';
import 'package:hairfit_ai/features/search_map/data/barber_repository.dart';
import 'package:hairfit_ai/features/search_map/presentation/barber_detail_screen.dart';
import 'package:hairfit_ai/models/barber_profile_model.dart';
import 'package:hairfit_ai/models/hairstyle_model.dart';
import 'package:hairfit_ai/models/service_model.dart';
import 'package:hairfit_ai/models/user_model.dart';
import 'package:hairfit_ai/providers/auth_provider.dart';
import 'package:hairfit_ai/providers/search_provider.dart';
import 'package:latlong2/latlong.dart';

class MockSearchNotifier extends SearchNotifier {
  @override
  Future<SearchMapState> build() async {
    return const SearchMapState(
      referenceLocation: LatLng(10.74, 106.63),
    );
  }
}
class FakeAuthNotifier extends AuthNotifier {
  final UserModel? _mockUser;
  FakeAuthNotifier(this._mockUser);

  @override
  FutureOr<UserModel?> build() => _mockUser;
}

void main() {
  testWidgets('BarberDetailScreen renders cover, store header, services and bottom bar', (
    tester,
  ) async {
    final mockBarber = BarberProfileModel(
      uid: 'barber_1',
      displayName: 'Thợ 1',
      address: '103H/6 Hoài Thanh, Phường Phú Định, Quận 8',
      location: const GeoLocation(latitude: 10.74, longitude: 106.63),
      approvalStatus: 'approved',
      avatarUrl: '',
      coverUrl: '',
      bio: 'Thợ cắt tóc chuyên nghiệp',
      priceMin: 50000,
      priceMax: 300000,
      ratingAvg: 4.8,
      ratingCount: 12,
      workingHours: {
        'mon': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'tue': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'wed': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'thu': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'fri': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'sat': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
        'sun': const DayWorkingHours(closed: false, open: '08:00', close: '20:00'),
      },
      services: [
        const ServiceModel(
          id: 'svc_1',
          name: 'Cắt tóc nam tiêu chuẩn',
          price: 100000,
          durationMinutes: 30,
          active: true,
        ),
      ],
      hairstyleIds: ['style_1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchNotifierProvider.overrideWith(() => MockSearchNotifier()),
          barberDetailProvider('barber_1').overrideWith((ref) => mockBarber),
          hairstylesProvider.overrideWith((ref) => [
            const HairstyleModel(
              id: 'style_1',
              name: 'Undercut Cổ Điển',
              faceShapes: ['oval'],
              tags: ['nam'],
              description: 'Mô tả kiểu tóc',
              imageUrl: '',
            ),
          ]),
          barberReviewsStreamProvider('barber_1').overrideWith(
            (ref) => Stream.value([]),
          ),
          authStateProvider.overrideWith(
            () => FakeAuthNotifier(null),
          ),
        ],
        child: const MaterialApp(
          home: BarberDetailScreen(barberId: 'barber_1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify SliverAppBar & store cover exists
    expect(find.byType(SliverAppBar), findsOneWidget);

    // Verify Barber store name, address, working hours, and services exist
    expect(find.text('Thợ 1'), findsOneWidget);
    expect(find.text('103H/6 Hoài Thanh, Phường Phú Định, Quận 8'), findsOneWidget);
    expect(find.text('Giờ hoạt động'), findsOneWidget);
    expect(find.text('Cắt tóc nam tiêu chuẩn'), findsOneWidget);

    // Verify bottom bar exists and does NOT take up the full screen
    expect(find.text('Đặt Lịch Hẹn'), findsOneWidget);
    final bodySize = tester.getSize(find.byType(CustomScrollView));
    expect(bodySize.height, greaterThan(400));
  });
}
