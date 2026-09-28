import 'face_shape.dart';
import 'face_shape_analyzer.dart';
import 'hairstyle_recommendation_engine.dart';

/// Gợi ý kiểu tóc trả về từ AI
class HairstyleSuggestion {
  final String id;
  final String reason;

  const HairstyleSuggestion({
    required this.id,
    required this.reason,
  });

  factory HairstyleSuggestion.fromJson(Map<String, dynamic> json) {
    return HairstyleSuggestion(
      id: json['id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
    };
  }
}

/// Kết quả phân tích từ quy trình AI Consulting (ML Kit Contours + Geometric Engine + Rules Matrix)
sealed class AIConsultResult {
  const AIConsultResult();

  factory AIConsultResult.success({
    required FaceShape faceShape,
    required List<HairstyleSuggestion> suggestions,
    FaceAnthropometricMetrics? metrics,
    RecommendationResult? recommendation,
  }) = AIConsultSuccess;

  factory AIConsultResult.validationFailed({
    required String message,
    required String hint,
  }) = AIConsultValidationFailed;

  factory AIConsultResult.fallbackNeeded({
    FaceShape? faceShape,
  }) = AIConsultFallbackNeeded;

  factory AIConsultResult.error({
    required String message,
  }) = AIConsultError;
}

class AIConsultSuccess extends AIConsultResult {
  final FaceShape faceShape;
  final List<HairstyleSuggestion> suggestions;
  final FaceAnthropometricMetrics? metrics;
  final RecommendationResult? recommendation;

  const AIConsultSuccess({
    required this.faceShape,
    required this.suggestions,
    this.metrics,
    this.recommendation,
  });
}

class AIConsultValidationFailed extends AIConsultResult {
  final String message;
  final String hint;

  const AIConsultValidationFailed({
    required this.message,
    required this.hint,
  });
}

class AIConsultFallbackNeeded extends AIConsultResult {
  final FaceShape? faceShape;

  const AIConsultFallbackNeeded({
    this.faceShape,
  });
}

class AIConsultError extends AIConsultResult {
  final String message;

  const AIConsultError({
    required this.message,
  });
}
