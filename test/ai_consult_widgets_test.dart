import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/services/seed_data_service.dart';
import 'package:hairfit_ai/features/ai_consult/domain/ai_consultant_service.dart';
import 'package:hairfit_ai/features/ai_consult/domain/face_shape.dart';
import 'package:hairfit_ai/features/ai_consult/domain/hairstyle_recommendation_engine.dart';
import 'package:hairfit_ai/features/ai_consult/presentation/ai_result_screen.dart';
import 'package:hairfit_ai/features/ai_consult/presentation/manual_select_screen.dart';
import 'package:hairfit_ai/features/ai_consult/presentation/widgets/face_camera_overlay.dart';
import 'package:hairfit_ai/features/ai_consult/presentation/widgets/hair_info_selector.dart';
import 'package:hairfit_ai/features/ai_consult/presentation/widgets/hairstyle_result_card.dart';
import 'package:hairfit_ai/providers/ai_consult_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_consult_provider_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Week 5 UI & Widget Tests', () {
    testWidgets('FaceCameraOverlay renders guidance tips and reacts to dismiss',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaceCameraOverlay(
              guideMessage: 'Căn chỉnh khuôn mặt',
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Căn chỉnh khuôn mặt'), findsOneWidget);
      expect(find.textContaining('Đảm bảo đủ ánh sáng'), findsOneWidget);
      expect(find.textContaining('Tháo kính râm'), findsOneWidget);

      final dismissButton = find.text('Đóng khung hướng dẫn');
      expect(dismissButton, findsOneWidget);
      await tester.tap(dismissButton);
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('HairInfoSelector renders preference chips and responds to taps',
        (tester) async {
      String? selectedGender;
      String? selectedLength;
      String? selectedTexture;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HairInfoSelector(
              selectedGender: selectedGender,
              selectedLength: selectedLength,
              selectedTexture: selectedTexture,
              onGenderChanged: (val) => selectedGender = val,
              onLengthChanged: (val) => selectedLength = val,
              onTextureChanged: (val) => selectedTexture = val,
            ),
          ),
        ),
      );

      expect(find.text('Sở thích tạo kiểu (Tùy chọn)'), findsOneWidget);
      expect(find.text('Nam'), findsOneWidget);
      expect(find.text('Tóc ngắn'), findsOneWidget);
      expect(find.text('Tóc thẳng'), findsOneWidget);

      await tester.tap(find.text('Nam'));
      await tester.pump();
      expect(selectedGender, equals('male'));

      await tester.tap(find.text('Tóc ngắn'));
      await tester.pump();
      expect(selectedLength, equals('short'));

      await tester.tap(find.text('Tóc thẳng'));
      await tester.pump();
      expect(selectedTexture, equals('straight'));
    });

    testWidgets('HairstyleResultCard renders styling tips, match score and triggers callback',
        (tester) async {
      bool tappedFindBarbers = false;
      final style = SeedDataService.sampleHairstyles.first;
      final rec = RecommendedHairstyle(
        style: SeedDataService.sampleHairstyles.first,
        matchScore: 0.95,
        matchReasonVi: 'Cắt gọn hai bên giúp làm thon gọn khuôn mặt tròn.',
        stylingTips: const ['Sấy vuốt ngược tạo phồng', 'Dùng sáp clay mờ'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HairstyleResultCard(
                recommendation: rec,
                rank: 1,
                onFindBarbers: () {
                  tappedFindBarbers = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('#1 GỢI Ý'), findsOneWidget);
      expect(find.text(style.name), findsOneWidget);
      expect(find.text('95% Phù hợp'), findsOneWidget);
      expect(find.textContaining('Cắt gọn hai bên'), findsOneWidget);
      expect(find.textContaining('Sấy vuốt ngược'), findsOneWidget);

      final ctaButton = find.text('Tìm thợ cắt kiểu ${style.name}');
      expect(ctaButton, findsOneWidget);
      await tester.tap(ctaButton);
      await tester.pump();

      expect(tappedFindBarbers, isTrue);
    });

    testWidgets('ManualSelectScreen displays all 5 face shapes and selects shape',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final consultantService = AIConsultantService(
        faceValidator: FakeFaceValidationService(),
      );
      final fakeRepo = FakeHairstyleRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultProvider.overrideWith((ref) => AIConsultNotifier(
                  consultantService: consultantService,
                  hairstyleRepository: fakeRepo as dynamic,
                  prefs: prefs,
                )),
          ],
          child: const MaterialApp(
            home: ManualSelectScreen(),
          ),
        ),
      );

      expect(find.text('Chọn Dáng Mặt Thủ Công'), findsOneWidget);
      expect(find.textContaining('Trái xoan'), findsOneWidget);
      expect(find.textContaining('Mặt tròn'), findsOneWidget);
      expect(find.textContaining('Mặt vuông'), findsOneWidget);
      expect(find.textContaining('Mặt trái tim'), findsOneWidget);
      expect(find.textContaining('Mặt dài'), findsOneWidget);

      // Chọn Mặt Tròn
      await tester.tap(find.textContaining('Mặt tròn').first);
      await tester.pump();

      expect(find.textContaining('Mặt tròn'), findsWidgets);
    });

    testWidgets('AIResultScreen displays EmptyState when no result exists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final consultantService = AIConsultantService(
        faceValidator: FakeFaceValidationService(),
      );
      final fakeRepo = FakeHairstyleRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultProvider.overrideWith((ref) => AIConsultNotifier(
                  consultantService: consultantService,
                  hairstyleRepository: fakeRepo as dynamic,
                  prefs: prefs,
                )),
          ],
          child: const MaterialApp(
            home: AIResultScreen(),
          ),
        ),
      );

      expect(find.text('Chưa có kết quả phân tích'), findsOneWidget);
      expect(find.text('Quay lại chụp ảnh'), findsOneWidget);
    });

    testWidgets('AIResultScreen displays full recommendations when result is present',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final consultantService = AIConsultantService(
        faceValidator: FakeFaceValidationService(),
      );
      final fakeRepo = FakeHairstyleRepository();

      final notifier = AIConsultNotifier(
        consultantService: consultantService,
        hairstyleRepository: fakeRepo as dynamic,
        prefs: prefs,
      );

      // Tạo kết quả manual cho mặt vuông
      await notifier.selectManualFaceShape(
        FaceShape.square,
        catalogOverride: SeedDataService.sampleHairstyles,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiConsultProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: AIResultScreen(),
          ),
        ),
      );

      expect(find.text('DÁNG KHUÔN MẶT CỦA BẠN'), findsOneWidget);
      expect(find.textContaining('Mặt vuông'), findsWidgets);
      expect(find.text('Top Kiểu Tóc Phù Hợp Nhất'), findsOneWidget);
      expect(find.text('Lời khuyên vàng khi tạo kiểu:'), findsOneWidget);
      expect(find.text('Kiểu tóc nên tránh:'), findsOneWidget);
    });
  });
}
