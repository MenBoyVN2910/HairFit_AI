// ============================================================================
// File: lib/features/ai_consult/presentation/ai_consult_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng ai_consult.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/ai_consult_provider.dart';
import '../domain/ai_consult_result.dart';
import 'widgets/face_camera_overlay.dart';
import 'widgets/hair_info_selector.dart';

/// Màn hình chính của luồng AI Tư Vấn Kiểu Tóc (Task 5.8, 5.9, 5.11, 5.15)
/// Hỗ trợ: Consent popup bảo mật, chụp ảnh camera, chọn từ thư viện,
/// chọn sở thích tóc, overlay căn chỉnh khuôn mặt, và phân tích On-Device < 60ms.
class AIConsultScreen extends ConsumerStatefulWidget {
  const AIConsultScreen({super.key});

  @override
  ConsumerState<AIConsultScreen> createState() => _AIConsultScreenState();
}

class _AIConsultScreenState extends ConsumerState<AIConsultScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _showCameraOverlayGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsentRequirement();
    });
  }

  void _checkConsentRequirement() {
    final aiState = ref.read(aiConsultProvider);
    if (!aiState.hasConsent) {
      _showConsentDialog();
    }
  }

  /// Hiển thị Popup xác nhận quyền riêng tư trước khi xử lý ảnh (Task 5.8)
  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.xs),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              const Expanded(
                child: Text('Cam Kết Bảo Mật AI', style: AppTextStyles.h4),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HairFit AI ứng dụng công nghệ 100% On-Device AI xử lý hoàn toàn cục bộ trên thiết bị của bạn:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                _buildConsentBullet(
                  Icons.check_circle_outline_rounded,
                  'Ảnh chân dung KHÔNG BAO GIỜ bị tải lên đám mây hoặc lưu trữ trên Firebase.',
                ),
                const SizedBox(height: AppDimensions.xs),
                _buildConsentBullet(
                  Icons.check_circle_outline_rounded,
                  'Toạ độ 132 điểm viền khuôn mặt được phân tích trong bộ nhớ RAM tạm thời (< 60ms) và tự hủy sau phiên tư vấn.',
                ),
                const SizedBox(height: AppDimensions.xs),
                _buildConsentBullet(
                  Icons.check_circle_outline_rounded,
                  'Hoạt động hoàn toàn ngoại tuyến (Offline), không làm lộ dữ liệu sinh trắc học.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Nếu từ chối, điều hướng sang màn hình chọn thủ công
                context.push('/customer/manual-select');
              },
              child: Text(
                'Chọn thủ công',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(aiConsultProvider.notifier).grantConsent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
              ),
              child: const Text('Tôi đồng ý'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsentBullet(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final aiState = ref.read(aiConsultProvider);
    if (!aiState.hasConsent) {
      _showConsentDialog();
      return;
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (file != null) {
        ref.read(aiConsultProvider.notifier).setImage(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi truy cập camera/ảnh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onStartAnalysis() async {
    final notifier = ref.read(aiConsultProvider.notifier);
    final result = await notifier.runAnalysis();

    if (!mounted) return;

    if (result is AIConsultSuccess) {
      // Chuyển tiếp sang màn hình kết quả (Task 5.12)
      context.push('/customer/ai-result');
    } else if (result is AIConsultValidationFailed) {
      _showFaceValidationErrorDialog(result.message, result.hint);
    } else if (result is AIConsultError) {
      _showFaceValidationErrorDialog(
        result.message,
        'Không thể nhận diện được khuôn mặt từ bức ảnh này. Vui lòng chọn ảnh chụp rõ mặt nhìn thẳng hoặc thử chọn dáng mặt thủ công.',
      );
    }
  }

  void _showFaceValidationErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            const Expanded(
              child: Text('Ảnh Không Hợp Lệ', style: AppTextStyles.h4),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push('/customer/manual-select');
            },
            child: const Text('Chọn thủ công'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _pickImage(ImageSource.gallery);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chọn ảnh khác'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiConsultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Tư Vấn Kiểu Tóc', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Chọn thủ công',
            icon: const Icon(Icons.touch_app_outlined),
            onPressed: () => context.push('/customer/manual-select'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tiêu đề giới thiệu
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppDimensions.borderRadiusLg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhận diện dáng mặt 100% On-Device',
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tốc độ < 60ms, bảo mật ảnh cục bộ, gợi ý kiểu tóc chuẩn salon.',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // 2. Khu vực ảnh chân dung (Photo Picker / Preview Card)
                _buildPhotoCard(aiState),
                const SizedBox(height: AppDimensions.lg),

                // 3. Thông báo lỗi hoặc hướng dẫn căn chỉnh (nếu có lỗi validation)
                if (aiState.errorMessage != null) ...[
                  _buildErrorGuidanceCard(aiState),
                  const SizedBox(height: AppDimensions.lg),
                ],

                // 4. Chọn sở thích tóc (Giới tính, Độ dài, Chất tóc)
                HairInfoSelector(
                  selectedGender: aiState.selectedGender,
                  selectedLength: aiState.selectedLength,
                  selectedTexture: aiState.selectedTexture,
                  onGenderChanged: (val) {
                    ref
                        .read(aiConsultProvider.notifier)
                        .setPreferences(gender: val);
                  },
                  onLengthChanged: (val) {
                    ref
                        .read(aiConsultProvider.notifier)
                        .setPreferences(length: val);
                  },
                  onTextureChanged: (val) {
                    ref
                        .read(aiConsultProvider.notifier)
                        .setPreferences(texture: val);
                  },
                ),
                const SizedBox(height: AppDimensions.xl),

                // 5. Nút bấm Bắt đầu phân tích AI
                AppButton(
                  text: aiState.isAnalyzing
                      ? 'Đang phân tích khuôn mặt (< 60ms)...'
                      : 'Phân tích dáng mặt & Gợi ý kiểu tóc',
                  icon: const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  isLoading: aiState.isAnalyzing,
                  onPressed: aiState.imagePath == null || aiState.isAnalyzing
                      ? null
                      : _onStartAnalysis,
                ),
                const SizedBox(height: AppDimensions.md),

                // 6. Nút fallback chọn thủ công
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/customer/manual-select'),
                    icon: const Icon(Icons.style_outlined, size: 18),
                    label: Text(
                      'Hoặc tự chọn dáng mặt thủ công',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.xxl),
              ],
            ),
          ),

          // Lớp phủ hướng dẫn khung oval nếu bật
          if (_showCameraOverlayGuide)
            Positioned.fill(
              child: FaceCameraOverlay(
                onDismiss: () {
                  setState(() {
                    _showCameraOverlayGuide = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(AIConsultState state) {
    final hasImage = state.imagePath != null && state.imagePath!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.borderRadiusLg,
        border: Border.all(
          color: hasImage
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: AppDimensions.borderRadiusMd,
                  child: Image.file(
                    File(state.imagePath!),
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.xs),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        ref.read(aiConsultProvider.notifier).clearImage();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Chụp lại'),
                ),
                const SizedBox(width: AppDimensions.md),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Chọn ảnh khác'),
                ),
              ],
            ),
          ] else ...[
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppDimensions.borderRadiusMd,
                border: Border.all(
                  color: AppColors.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_front_rounded,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Chụp hoặc chọn ảnh chân dung nhìn thẳng',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đảm bảo khuôn mặt rõ nét, không bị che khuất',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn từ máy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCameraOverlayGuide = true;
                });
              },
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: Text(
                'Xem hướng dẫn căn chỉnh khuôn mặt chuẩn',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorGuidanceCard(AIConsultState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: Text(
                  state.errorMessage ?? 'Ảnh chưa đạt tiêu chuẩn nhận diện',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (state.errorHint != null) ...[
            const SizedBox(height: 4),
            Text(
              state.errorHint!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.push('/customer/manual-select'),
                child: const Text('Chọn dáng mặt thủ công'),
              ),
              const SizedBox(width: AppDimensions.xs),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Chụp lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
