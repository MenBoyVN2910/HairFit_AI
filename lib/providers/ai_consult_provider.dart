import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/seed_data_service.dart';
import '../features/ai_consult/data/hairstyle_repository.dart';
import '../features/ai_consult/domain/ai_consult_result.dart';
import '../features/ai_consult/domain/ai_consultant_service.dart';
import '../features/ai_consult/domain/face_shape.dart';
import '../features/ai_consult/domain/hairstyle_recommendation_engine.dart';
import '../models/hairstyle_model.dart';

/// Provider cung cấp instance điều phối AIConsultantService
final aiConsultantServiceProvider = Provider<AIConsultantService>((ref) {
  final service = AIConsultantService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Khóa lưu trữ trạng thái người dùng đồng ý điều khoản xử lý hình ảnh AI on-device
const String kAiConsentKey = 'ai_consult_consent_accepted';

/// Trạng thái của luồng AI Tư Vấn Kiểu Tóc (Task 5.7)
class AIConsultState {
  final bool hasConsent;
  final String? imagePath;
  final String? selectedGender;
  final String? selectedLength;
  final String? selectedTexture;
  final bool isAnalyzing;
  final AIConsultResult? result;
  final int? executionTimeMs;
  final String? errorMessage;
  final String? errorHint;

  const AIConsultState({
    this.hasConsent = false,
    this.imagePath,
    this.selectedGender,
    this.selectedLength,
    this.selectedTexture,
    this.isAnalyzing = false,
    this.result,
    this.executionTimeMs,
    this.errorMessage,
    this.errorHint,
  });

  AIConsultState copyWith({
    bool? hasConsent,
    String? imagePath,
    bool clearImage = false,
    String? selectedGender,
    String? selectedLength,
    String? selectedTexture,
    bool? isAnalyzing,
    AIConsultResult? result,
    bool clearResult = false,
    int? executionTimeMs,
    String? errorMessage,
    String? errorHint,
    bool clearError = false,
  }) {
    return AIConsultState(
      hasConsent: hasConsent ?? this.hasConsent,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      selectedGender: selectedGender ?? this.selectedGender,
      selectedLength: selectedLength ?? this.selectedLength,
      selectedTexture: selectedTexture ?? this.selectedTexture,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: clearResult ? null : (result ?? this.result),
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorHint: clearError ? null : (errorHint ?? this.errorHint),
    );
  }

  /// Kiểm tra có kết quả tư vấn thành công hay chưa
  bool get hasSuccessResult => result is AIConsultSuccess;

  /// Lấy kết quả thành công nếu có
  AIConsultSuccess? get successResult =>
      result is AIConsultSuccess ? result as AIConsultSuccess : null;
}

/// Notifier quản lý toàn bộ vòng đời và luồng dữ liệu AI Tư Vấn (Task 5.7)
class AIConsultNotifier extends StateNotifier<AIConsultState> {
  final AIConsultantService consultantService;
  final HairstyleRepository hairstyleRepository;
  final SharedPreferences? prefs;

  AIConsultNotifier({
    required this.consultantService,
    required this.hairstyleRepository,
    this.prefs,
  }) : super(AIConsultState(
          hasConsent: prefs?.getBool(kAiConsentKey) ?? false,
        )) {
    if (prefs == null) {
      _loadConsentFromStorage();
    }
  }

  Future<void> _loadConsentFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consented = prefs.getBool(kAiConsentKey) ?? false;
      state = state.copyWith(hasConsent: consented);
    } catch (e) {
      debugPrint('[AIConsultNotifier] Lỗi đọc SharedPreferences: $e');
    }
  }

  /// Người dùng chấp thuận quyền riêng tư (Task 5.8)
  Future<void> grantConsent() async {
    state = state.copyWith(hasConsent: true);
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setBool(kAiConsentKey, true);
    } catch (e) {
      debugPrint('[AIConsultNotifier] Lỗi lưu SharedPreferences: $e');
    }
  }

  /// Cập nhật đường dẫn ảnh chụp chân dung
  void setImage(String path) {
    state = state.copyWith(
      imagePath: path,
      clearResult: true,
      clearError: true,
    );
  }

  /// Xóa ảnh hiện tại để chụp lại
  void clearImage() {
    state = state.copyWith(
      clearImage: true,
      clearResult: true,
      clearError: true,
    );
  }

  /// Cập nhật sở thích (Giới tính, Độ dài, Chất tóc)
  void setPreferences({
    String? gender,
    String? length,
    String? texture,
  }) {
    state = state.copyWith(
      selectedGender: gender,
      selectedLength: length,
      selectedTexture: texture,
    );
  }

  /// Thực hiện quy trình phân tích AI on-device toàn diện (Task 5.9, 5.11, 5.15)
  Future<AIConsultResult> runAnalysis({
    List<HairstyleModel>? catalogOverride,
  }) async {
    if (state.imagePath == null || state.imagePath!.isEmpty) {
      const err = 'Vui lòng chụp ảnh hoặc chọn ảnh chân dung trước khi phân tích';
      state = state.copyWith(
        errorMessage: err,
        errorHint: 'Nhấn vào biểu tượng camera hoặc thư viện ảnh để bắt đầu',
      );
      return AIConsultResult.error(message: err);
    }

    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearResult: true,
    );

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Lấy danh mục kiểu tóc (ưu tiên override, sau đó Firestore, nếu lỗi dùng fallback seed catalog)
      List<HairstyleModel> catalog = catalogOverride ?? [];
      if (catalog.isEmpty) {
        try {
          catalog = await hairstyleRepository.getAllHairstyles();
        } catch (e) {
          debugPrint('[AIConsult] Lỗi lấy Firestore catalog, kích hoạt catalog seed dự phòng: $e');
        }
      }

      if (catalog.isEmpty) {
        catalog = SeedDataService.sampleHairstyles;
      }

      // 2. Chuyển đổi ảnh sang InputImage của ML Kit
      final inputImage = InputImage.fromFilePath(state.imagePath!);

      // 3. Thực hiện chuỗi xử lý 3 tầng 100% On-Device
      final consultResult = await consultantService.consult(
        inputImage: inputImage,
        catalog: catalog,
        gender: state.selectedGender,
        preferredLength: state.selectedLength,
        preferredTexture: state.selectedTexture,
      );

      final elapsed = stopwatch.elapsedMilliseconds;

      switch (consultResult) {
        case AIConsultSuccess():
          state = state.copyWith(
            isAnalyzing: false,
            result: consultResult,
            executionTimeMs: elapsed,
            clearError: true,
          );
        case AIConsultValidationFailed(:final message, :final hint):
          state = state.copyWith(
            isAnalyzing: false,
            result: consultResult,
            executionTimeMs: elapsed,
            errorMessage: message,
            errorHint: hint,
          );
        case AIConsultError(:final message):
          state = state.copyWith(
            isAnalyzing: false,
            result: consultResult,
            executionTimeMs: elapsed,
            errorMessage: message,
            errorHint: 'Bạn có thể thử lại hoặc sử dụng tính năng chọn dáng mặt thủ công',
          );
        case AIConsultFallbackNeeded():
          state = state.copyWith(
            isAnalyzing: false,
            result: consultResult,
            executionTimeMs: elapsed,
          );
      }

      return consultResult;
    } catch (e) {
      final elapsed = stopwatch.elapsedMilliseconds;
      debugPrint('[AIConsultNotifier] Exception trong runAnalysis: $e');
      final errorResult = AIConsultResult.error(
        message: 'Lỗi phân tích hình ảnh: $e',
      );

      state = state.copyWith(
        isAnalyzing: false,
        result: errorResult,
        executionTimeMs: elapsed,
        errorMessage: 'Không thể phân tích ảnh lúc này',
        errorHint: 'Vui lòng kiểm tra lại ảnh chụp hoặc chọn dáng mặt thủ công',
      );

      return errorResult;
    }
  }

  /// Fallback: Người dùng chọn dáng mặt thủ công (Task 5.13)
  Future<void> selectManualFaceShape(
    FaceShape shape, {
    List<HairstyleModel>? catalogOverride,
  }) async {
    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearResult: true,
    );

    try {
      List<HairstyleModel> catalog = catalogOverride ?? [];
      if (catalog.isEmpty) {
        try {
          catalog = await hairstyleRepository.getAllHairstyles();
        } catch (_) {}
      }
      if (catalog.isEmpty) {
        catalog = SeedDataService.sampleHairstyles;
      }

      const engine = HairstyleRecommendationEngine();
      final recommendation = engine.recommend(
        faceShape: shape,
        catalog: catalog,
        gender: state.selectedGender,
        preferredLength: state.selectedLength,
        preferredTexture: state.selectedTexture,
      );

      final suggestions = recommendation.primaryRecommendations.take(3).map((rec) {
        return HairstyleSuggestion(
          id: rec.style.id,
          reason: rec.matchReasonVi,
        );
      }).toList();

      final success = AIConsultResult.success(
        faceShape: shape,
        suggestions: suggestions,
        recommendation: recommendation,
      );

      state = state.copyWith(
        isAnalyzing: false,
        result: success,
        executionTimeMs: 5,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Lỗi khi xử lý gợi ý thủ công: $e',
      );
    }
  }

  /// Đặt lại trạng thái tư vấn về ban đầu
  void reset() {
    state = state.copyWith(
      clearImage: true,
      clearResult: true,
      clearError: true,
      isAnalyzing: false,
    );
  }
}

/// Provider chính cho toàn bộ tính năng AI Tư Vấn Kiểu Tóc
final aiConsultProvider =
    StateNotifierProvider<AIConsultNotifier, AIConsultState>((ref) {
  final consultantService = ref.watch(aiConsultantServiceProvider);
  final hairstyleRepository = ref.watch(hairstyleRepositoryProvider);
  return AIConsultNotifier(
    consultantService: consultantService,
    hairstyleRepository: hairstyleRepository,
  );
});
