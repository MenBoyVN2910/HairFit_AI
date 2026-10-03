// ============================================================================
// File: lib/features/ai_consult/presentation/ai_spike_test_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng ai_consult.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seed_data_service.dart';
import '../../../core/widgets/app_button.dart';
import '../data/face_validation_service.dart';
import '../domain/face_shape_analyzer.dart';
import '../domain/hairstyle_recommendation_engine.dart';

/// Màn hình Spike AI & Kiểm Thử Kiến Trúc Mới On-Device Hoàn Toàn
class AISpikeTestScreen extends StatefulWidget {
  const AISpikeTestScreen({super.key});

  @override
  State<AISpikeTestScreen> createState() => _AISpikeTestScreenState();
}

class _AISpikeTestScreenState extends State<AISpikeTestScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceValidationService _faceValidator = FaceValidationService();
  final FaceShapeAnalyzer _faceShapeAnalyzer = const FaceShapeAnalyzer();
  final HairstyleRecommendationEngine _recommendationEngine =
      const HairstyleRecommendationEngine();

  XFile? _selectedImage;

  // ML Kit & Geometric On-Device State
  bool _isTestingMlKit = false;
  FaceValidationResult? _mlKitResult;
  FaceAnthropometricMetrics? _faceMetrics;
  RecommendationResult? _recommendationResult;
  int? _mlKitLatencyMs;
  int? _analysisLatencyMs;

  // Seed Data State
  bool _isSeeding = false;
  String? _seedStatusMessage;

  @override
  void dispose() {
    _faceValidator.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _selectedImage = file;
          _mlKitResult = null;
          _faceMetrics = null;
          _recommendationResult = null;
          _mlKitLatencyMs = null;
          _analysisLatencyMs = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
    }
  }

  Future<void> _runOnDeviceAnalysis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isTestingMlKit = true;
      _mlKitResult = null;
      _faceMetrics = null;
      _recommendationResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);

      // Tầng 1: Validate chất lượng ảnh bằng Google ML Kit
      final validationResult = await _faceValidator.validateFace(inputImage);
      final mlKitTime = stopwatch.elapsedMilliseconds;

      FaceAnthropometricMetrics? metrics;
      RecommendationResult? recommendations;
      int? analysisTime;

      // Tầng 2 & 3: Tính toán hình học nhân trắc học & Khớp ma trận gợi ý kiểu tóc
      if (validationResult.isValid && validationResult.face != null) {
        final analysisStopwatch = Stopwatch()..start();

        metrics = _faceShapeAnalyzer.analyze(validationResult.face!);
        recommendations = _recommendationEngine.recommend(
          faceShape: metrics.faceShape,
          catalog: SeedDataService.sampleHairstyles,
        );

        analysisStopwatch.stop();
        analysisTime = analysisStopwatch.elapsedMilliseconds;
      }

      stopwatch.stop();

      setState(() {
        _mlKitResult = validationResult;
        _faceMetrics = metrics;
        _recommendationResult = recommendations;
        _mlKitLatencyMs = mlKitTime;
        _analysisLatencyMs = analysisTime;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi kiểm tra On-Device: $e')));
    } finally {
      setState(() {
        _isTestingMlKit = false;
      });
    }
  }

  Future<void> _runSeedData() async {
    setState(() {
      _isSeeding = true;
      _seedStatusMessage = 'Đang nạp 10 kiểu tóc & 5 thợ mẫu vào Firestore...';
    });

    try {
      final seedService = SeedDataService();
      await seedService.seedAll(overwrite: true);
      setState(() {
        _seedStatusMessage = '✅ Nạp dữ liệu Seed Data thành công!';
      });
    } catch (e) {
      setState(() {
        _seedStatusMessage =
            '⚠️ Lỗi nạp Seed Data: $e\n(Hãy bật Firestore Database trên Firebase Console)';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _runClearSampleBarbers() async {
    setState(() {
      _isSeeding = true;
      _seedStatusMessage = 'Đang xoá 5 thợ mẫu Seed Data khỏi Firestore...';
    });

    try {
      final seedService = SeedDataService();
      await seedService.clearSampleBarbers();
      setState(() {
        _seedStatusMessage = '🗑️ Đã xoá sạch 5 thợ mẫu Seed Data thành công!';
      });
    } catch (e) {
      setState(() {
        _seedStatusMessage = '⚠️ Lỗi xoá Seed Data: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spike AI On-Device & Seed Data'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSelectionSection(),
            const SizedBox(height: AppDimensions.lg),
            _buildOnDeviceAnalysisSection(),
            if (_recommendationResult != null) ...[
              const SizedBox(height: AppDimensions.lg),
              _buildRecommendationSection(),
            ],
            const SizedBox(height: AppDimensions.lg),
            _buildSeedDataSection(),
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Chọn hoặc chụp ảnh khuôn mặt',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppDimensions.sm),
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: AppDimensions.borderRadiusMd,
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ] else ...[
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: AppDimensions.borderRadiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: AppDimensions.xs),
                    Text(
                      'Chưa có ảnh nào được chọn',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Chụp ảnh',
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppButton.outline(
                    text: 'Chọn từ thư viện',
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnDeviceAnalysisSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '2. Phân Tích Hình Học On-Device (ML Kit Contours)',
                    style: AppTextStyles.h4,
                  ),
                ),
                if (_analysisLatencyMs != null && _mlKitLatencyMs != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppDimensions.borderRadiusSm,
                    ),
                    child: Text(
                      'ML: ${_mlKitLatencyMs}ms | Thuật toán: ${_analysisLatencyMs}ms',
                      style: AppTextStyles.badgeText.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            const Text(
              'Trích xuất 132 điểm viền khuôn mặt (Contours) & tính toán tỷ lệ nhân trắc học hình học tức thì (< 50ms, 100% offline, miễn phí).',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.md),
            AppButton(
              text: 'Quét & Phân Tích Dáng Mặt On-Device',
              isLoading: _isTestingMlKit,
              onPressed: _selectedImage == null ? null : _runOnDeviceAnalysis,
            ),
            if (_mlKitResult != null) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: _mlKitResult!.isValid
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: AppDimensions.borderRadiusSm,
                  border: Border.all(
                    color: _mlKitResult!.isValid
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _mlKitResult!.isValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: _mlKitResult!.isValid
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            _mlKitResult!.isValid
                                ? 'ẢNH HỢP LỆ VÀ ĐÃ TRÍCH XUẤT ĐƯỢC ĐIỂM VIỀN'
                                : 'ẢNH KHÔNG ĐẠT YÊU CẦU',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _mlKitResult!.isValid
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppDimensions.md),
                    Text(
                      '• Góc nghiêng ngang (Euler Y): ${_mlKitResult!.eulerY?.toStringAsFixed(1)}° (Chuẩn <= 20°)',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      '• Góc cúi/ngửa (Euler X): ${_mlKitResult!.eulerX?.toStringAsFixed(1)}° (Chuẩn <= 15°)',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      '• Chiều rộng khuôn mặt: ${_mlKitResult!.boundingBoxWidth?.toStringAsFixed(0)}px',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (!_mlKitResult!.isValid) ...[
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'Lỗi: ${_mlKitResult!.errorMessage}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_mlKitResult!.errorHint != null)
                        Text(
                          'Hướng dẫn: ${_mlKitResult!.errorHint}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            if (_faceMetrics != null) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: AppDimensions.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        Expanded(
                          child: Text(
                            'KẾT QUẢ DÁNG MẶT: ${_faceMetrics!.faceShape.displayNameVi.toUpperCase()}',
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      _faceMetrics!.explanationVi,
                      style: AppTextStyles.bodySmall,
                    ),
                    const Divider(height: AppDimensions.md),
                    const Text(
                      'Chi tiết chỉ số nhân trắc học hình học:',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Wrap(
                      spacing: AppDimensions.sm,
                      runSpacing: AppDimensions.xs,
                      children: [
                        _buildMetricChip(
                          'Tỷ lệ dài/rộng',
                          _faceMetrics!.aspectRatio.toStringAsFixed(2),
                        ),
                        _buildMetricChip(
                          'Độ vuông góc hàm',
                          '${(_faceMetrics!.jawSquareness * 100).toStringAsFixed(0)}%',
                        ),
                        _buildMetricChip(
                          'Tỷ lệ trán/hàm',
                          _faceMetrics!.foreheadToJawRatio.toStringAsFixed(2),
                        ),
                        _buildMetricChip(
                          'Độ tin cậy',
                          '${(_faceMetrics!.confidence * 100).toStringAsFixed(0)}%',
                        ),
                        _buildMetricChip(
                          'Điểm viền contour',
                          '${_faceMetrics!.contourPointsCount} pts',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: AppDimensions.borderRadiusSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRecommendationSection() {
    final result = _recommendationResult!;
    return Card(
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.content_cut,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    '3. Gợi Ý Kiểu Tóc Phù Hợp (${result.faceShape.displayNameVi})',
                    style: AppTextStyles.h4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Lời khuyên vàng: ${result.generalAdviceVi}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '⚠️ Nên tránh: ${result.avoidAdviceVi}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            const Text(
              'Danh sách kiểu tóc phù hợp nhất từ Catalog:',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: AppDimensions.sm),
            ...result.primaryRecommendations.map(
              (rec) => _buildHairstyleCard(rec),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHairstyleCard(RecommendedHairstyle rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppDimensions.borderRadiusSm,
            child: Image.network(
              rec.style.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                color: AppColors.inputBackground,
                child: const Icon(
                  Icons.image_not_supported,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(rec.style.name, style: AppTextStyles.h4),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: AppDimensions.borderRadiusSm,
                      ),
                      child: Text(
                        'Độ hợp: ${(rec.matchScore * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(rec.matchReasonVi, style: AppTextStyles.bodySmall),
                if (rec.stylingTips.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Mẹo: ${rec.stylingTips.first}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedDataSection() {
    return Card(
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. Khởi Tạo Dữ Liệu Demo (Seed Data)',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppDimensions.xs),
            const Text(
              'Nạp 10 kiểu tóc vào hairstyleCatalog và 5 tiệm thợ vào barberProfiles trong Firestore.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    text: 'Nạp Seed Data',
                    isLoading: _isSeeding,
                    onPressed: _runSeedData,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppButton.outline(
                    text: 'Xoá 5 thợ mẫu',
                    isLoading: _isSeeding,
                    onPressed: _runClearSampleBarbers,
                  ),
                ),
              ],
            ),
            if (_seedStatusMessage != null) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: AppDimensions.borderRadiusSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _seedStatusMessage!,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
