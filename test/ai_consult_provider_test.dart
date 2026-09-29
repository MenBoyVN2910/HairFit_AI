import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/models/hairstyle_model.dart';
import 'package:hairfit_ai/core/services/seed_data_service.dart';
import 'package:hairfit_ai/features/ai_consult/data/face_validation_service.dart';
import 'package:hairfit_ai/features/ai_consult/data/hairstyle_repository.dart';
import 'package:hairfit_ai/features/ai_consult/domain/ai_consult_result.dart';
import 'package:hairfit_ai/features/ai_consult/domain/ai_consultant_service.dart';
import 'package:hairfit_ai/features/ai_consult/domain/face_shape.dart';
import 'package:hairfit_ai/features/ai_consult/domain/face_shape_analyzer.dart';
import 'package:hairfit_ai/features/ai_consult/domain/hairstyle_recommendation_engine.dart';
import 'package:hairfit_ai/providers/ai_consult_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake HairstyleRepository dùng seed sample hairstyles trong test
class FakeFaceValidationService extends FaceValidationService {
  @override
  Future<void> dispose() async {}
}

class FakeHairstyleRepository implements HairstyleRepository {
  @override
  Future<List<HairstyleModel>> getAllHairstyles() async {
    return SeedDataService.sampleHairstyles;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AIConsultantService consultantService;
  late FakeHairstyleRepository fakeRepository;
  late AIConsultNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      kAiConsentKey: false,
    });
    final prefs = await SharedPreferences.getInstance();

    consultantService = AIConsultantService(
      faceValidator: FakeFaceValidationService(),
      faceShapeAnalyzer: const FaceShapeAnalyzer(),
      recommendationEngine: const HairstyleRecommendationEngine(),
    );
    fakeRepository = FakeHairstyleRepository();

    notifier = AIConsultNotifier(
      consultantService: consultantService,
      hairstyleRepository: fakeRepository as dynamic,
      prefs: prefs,
    );
  });

  tearDown(() async {
    await consultantService.dispose();
  });

  group('AIConsultProvider State & Flow Tests (Week 5)', () {
    test('Initial state has consent false and no selected image', () {
      expect(notifier.state.hasConsent, isFalse);
      expect(notifier.state.imagePath, isNull);
      expect(notifier.state.isAnalyzing, isFalse);
      expect(notifier.state.result, isNull);
      expect(notifier.state.hasSuccessResult, isFalse);
    });

    test('grantConsent updates state and persists flag', () async {
      await notifier.grantConsent();
      expect(notifier.state.hasConsent, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kAiConsentKey), isTrue);
    });

    test('setImage and clearImage manipulate state properly', () {
      notifier.setImage('/mock/path/portrait.jpg');
      expect(notifier.state.imagePath, equals('/mock/path/portrait.jpg'));
      expect(notifier.state.errorMessage, isNull);

      notifier.clearImage();
      expect(notifier.state.imagePath, isNull);
    });

    test('setPreferences updates gender, length, and texture', () {
      notifier.setPreferences(
        gender: 'male',
        length: 'short',
        texture: 'wavy',
      );

      expect(notifier.state.selectedGender, equals('male'));
      expect(notifier.state.selectedLength, equals('short'));
      expect(notifier.state.selectedTexture, equals('wavy'));
    });

    test('runAnalysis without image returns error result', () async {
      final result = await notifier.runAnalysis();
      expect(result, isA<AIConsultError>());
      expect(notifier.state.errorMessage, contains('chụp ảnh hoặc chọn ảnh'));
      expect(notifier.state.isAnalyzing, isFalse);
    });

    test('selectManualFaceShape (Fallback) immediately computes recommendations', () async {
      await notifier.selectManualFaceShape(
        FaceShape.round,
        catalogOverride: SeedDataService.sampleHairstyles,
      );

      expect(notifier.state.hasSuccessResult, isTrue);
      expect(notifier.state.successResult, isNotNull);

      final success = notifier.state.successResult!;
      expect(success.faceShape, equals(FaceShape.round));
      expect(success.recommendation, isNotNull);
      expect(success.recommendation!.primaryRecommendations, isNotEmpty);

      // Mặt tròn phải ưu tiên Undercut hoặc Pompadour tạo chiều cao
      final primaryStyleIds = success.recommendation!.primaryRecommendations
          .map((r) => r.style.id)
          .toList();
      expect(primaryStyleIds, anyOf(contains('undercut'), contains('pompadour')));

      // Mỗi kiểu đề xuất đều có matchScore, reason tiếng Việt và styling tips
      final topRec = success.recommendation!.primaryRecommendations.first;
      expect(topRec.matchScore, greaterThan(0.8));
      expect(topRec.matchReasonVi, isNotEmpty);
    });

    test('selectManualFaceShape for Square face prioritizes suitable styles', () async {
      await notifier.selectManualFaceShape(
        FaceShape.square,
        catalogOverride: SeedDataService.sampleHairstyles,
      );

      final success = notifier.state.successResult!;
      expect(success.faceShape, equals(FaceShape.square));
      expect(success.recommendation!.generalAdviceVi, contains('vuông'));
      expect(success.recommendation!.avoidAdviceVi, isNotEmpty);
    });

    test('reset clears image and result while preserving preferences', () {
      notifier.setImage('/mock/test.jpg');
      notifier.setPreferences(gender: 'male');
      notifier.reset();

      expect(notifier.state.imagePath, isNull);
      expect(notifier.state.result, isNull);
      expect(notifier.state.selectedGender, equals('male'));
    });
  });
}
