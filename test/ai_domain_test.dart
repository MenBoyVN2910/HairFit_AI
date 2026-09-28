import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/services/seed_data_service.dart';
import 'package:hairfit_ai/features/ai_consult/domain/face_shape.dart';
import 'package:hairfit_ai/features/ai_consult/domain/face_shape_analyzer.dart';
import 'package:hairfit_ai/features/ai_consult/domain/hairstyle_recommendation_engine.dart';

void main() {
  group('FaceShape Domain Test', () {
    test('FaceShape correctly parses all valid shape strings', () {
      expect(FaceShape.fromString('oval'), equals(FaceShape.oval));
      expect(FaceShape.fromString('round'), equals(FaceShape.round));
      expect(FaceShape.fromString('square'), equals(FaceShape.square));
      expect(FaceShape.fromString('heart'), equals(FaceShape.heart));
      expect(FaceShape.fromString('oblong'), equals(FaceShape.oblong));
      expect(FaceShape.fromString('long'), equals(FaceShape.oblong));
      expect(FaceShape.fromString('invalid_shape'), equals(FaceShape.oval));
    });

    test('All FaceShapes have non-empty Vietnamese names and descriptions', () {
      for (final shape in FaceShape.values) {
        expect(shape.displayNameVi.isNotEmpty, isTrue);
        expect(shape.descriptionVi.isNotEmpty, isTrue);
        expect(shape.keyName.isNotEmpty, isTrue);
      }
    });
  });

  group('FaceShapeAnalyzer Geometric Classification Tests', () {
    const analyzer = FaceShapeAnalyzer();

    test('Classifies Square face correctly (wide jaw, balanced ratio)', () {
      final metrics = analyzer.classifyFromMetrics(
        faceHeight: 180,
        cheekboneWidth: 150, // aspectRatio = 1.20
        foreheadWidth: 145,
        jawlineWidth: 135, // jawSquareness = 135/150 = 0.90 >= 0.86
        chinWidth: 80,
      );
      expect(metrics.faceShape, equals(FaceShape.square));
      expect(metrics.jawSquareness, greaterThanOrEqualTo(0.86));
      expect(metrics.explanationVi.isNotEmpty, isTrue);
    });

    test('Classifies Round face correctly (short face, soft jawline)', () {
      final metrics = analyzer.classifyFromMetrics(
        faceHeight: 160,
        cheekboneWidth: 145, // aspectRatio = 1.10 < 1.28
        foreheadWidth: 125,
        jawlineWidth: 105, // jawSquareness = 105/145 = 0.72 < 0.86
        chinWidth: 60,
      );
      expect(metrics.faceShape, equals(FaceShape.round));
      expect(metrics.aspectRatio, lessThan(1.28));
    });

    test('Classifies Oblong face correctly (elongated ratio > 1.55)', () {
      final metrics = analyzer.classifyFromMetrics(
        faceHeight: 230,
        cheekboneWidth: 140, // aspectRatio = 230/140 = 1.64 > 1.55
        foreheadWidth: 135,
        jawlineWidth: 120,
        chinWidth: 65,
      );
      expect(metrics.faceShape, equals(FaceShape.oblong));
      expect(metrics.aspectRatio, greaterThan(1.55));
    });

    test('Classifies Heart face correctly (wide forehead, narrow pointed chin)', () {
      final metrics = analyzer.classifyFromMetrics(
        faceHeight: 190,
        cheekboneWidth: 145, // aspectRatio = 1.31
        foreheadWidth: 150,
        jawlineWidth: 110, // foreheadToJaw = 150/110 = 1.36 >= 1.22
        chinWidth: 40, // chinTaper = 40/110 = 0.36 <= 0.45
      );
      expect(metrics.faceShape, equals(FaceShape.heart));
      expect(metrics.foreheadToJawRatio, greaterThanOrEqualTo(1.22));
    });

    test('Classifies Oval face correctly (ideal golden ratio ~1.3-1.5)', () {
      final metrics = analyzer.classifyFromMetrics(
        faceHeight: 200,
        cheekboneWidth: 145, // aspectRatio = 200/145 = 1.38
        foreheadWidth: 130,
        jawlineWidth: 110, // jawSquareness = 0.76
        chinWidth: 55,
      );
      expect(metrics.faceShape, equals(FaceShape.oval));
      expect(metrics.aspectRatio, inInclusiveRange(1.28, 1.55));
    });
  });

  group('HairstyleRecommendationEngine Tests', () {
    const engine = HairstyleRecommendationEngine();

    test('Recommends styles matching Square face with specific reasons', () {
      final result = engine.recommend(
        faceShape: FaceShape.square,
        catalog: SeedDataService.sampleHairstyles,
      );

      expect(result.faceShape, equals(FaceShape.square));
      expect(result.generalAdviceVi.isNotEmpty, isTrue);
      expect(result.avoidAdviceVi.isNotEmpty, isTrue);
      expect(result.primaryRecommendations.isNotEmpty, isTrue);

      // Tất cả kiểu trong primaryRecommendations đều chứa 'square' trong faceShapes
      for (final rec in result.primaryRecommendations) {
        expect(rec.style.faceShapes.contains('square'), isTrue);
        expect(rec.matchReasonVi.isNotEmpty, isTrue);
        expect(rec.matchScore, greaterThan(0.5));
      }
    });

    test('Recommends styles matching Round face and provides styling tips', () {
      final result = engine.recommend(
        faceShape: FaceShape.round,
        catalog: SeedDataService.sampleHairstyles,
      );

      expect(result.faceShape, equals(FaceShape.round));
      expect(result.primaryRecommendations.isNotEmpty, isTrue);

      final styleIds = result.primaryRecommendations.map((r) => r.style.id).toList();
      expect(styleIds, anyOf(contains('pompadour'), contains('undercut'), contains('quiff')));
    });

    test('Recommends styles matching Heart face', () {
      final result = engine.recommend(
        faceShape: FaceShape.heart,
        catalog: SeedDataService.sampleHairstyles,
      );

      expect(result.faceShape, equals(FaceShape.heart));
      final styleIds = result.primaryRecommendations.map((r) => r.style.id).toList();
      expect(styleIds, anyOf(contains('layer_male'), contains('side_part'), contains('two_block')));
    });

    test('Recommends styles matching Oblong face', () {
      final result = engine.recommend(
        faceShape: FaceShape.oblong,
        catalog: SeedDataService.sampleHairstyles,
      );

      expect(result.faceShape, equals(FaceShape.oblong));
      final styleIds = result.primaryRecommendations.map((r) => r.style.id).toList();
      expect(styleIds, anyOf(contains('french_crop'), contains('side_part'), contains('layer_male')));
    });
  });

  group('SeedData Integrity Test', () {
    test('Seed data contains exactly 10 hairstyles', () {
      expect(SeedDataService.sampleHairstyles.length, equals(10));

      for (final style in SeedDataService.sampleHairstyles) {
        expect(style.id.isNotEmpty, isTrue);
        expect(style.name.isNotEmpty, isTrue);
        expect(style.faceShapes.isNotEmpty, isTrue);
        expect(style.tags.isNotEmpty, isTrue);
      }
    });

    test('Seed data contains exactly 5 barbers with valid durations and coords', () {
      expect(SeedDataService.sampleBarbers.length, equals(5));

      for (final barber in SeedDataService.sampleBarbers) {
        expect(barber.uid.isNotEmpty, isTrue);
        expect(barber.displayName.isNotEmpty, isTrue);
        expect(barber.location.latitude, greaterThan(0));
        expect(barber.location.longitude, greaterThan(0));
        expect(barber.services.isNotEmpty, isTrue);

        // Kiểm tra thời lượng mọi dịch vụ đều là bội số của 30 phút
        for (final svc in barber.services) {
          expect(svc.durationMinutes % 30, equals(0), reason: '${svc.name} duration is not a multiple of 30');
          expect(svc.price, greaterThan(0));
        }

        // Kiểm tra giờ làm việc có đủ các ngày
        expect(barber.workingHours.containsKey('mon'), isTrue);
        expect(barber.workingHours.containsKey('sun'), isTrue);
      }
    });
  });
}
