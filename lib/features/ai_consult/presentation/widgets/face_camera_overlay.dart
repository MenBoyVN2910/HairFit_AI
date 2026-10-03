// ============================================================================
// File: lib/features/ai_consult/presentation/widgets/face_camera_overlay.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng ai_consult.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget khung hình oval hướng dẫn người dùng căn chỉnh khuôn mặt chuẩn xác (Task 5.10)
/// Đảm bảo góc nghiêng Euler Y <= 20°, Euler X <= 15° và kích thước khuôn mặt chiếm tối thiểu 25% khung hình
class FaceCameraOverlay extends StatelessWidget {
  final String? guideMessage;
  final bool isValid;
  final VoidCallback? onDismiss;

  const FaceCameraOverlay({
    super.key,
    this.guideMessage,
    this.isValid = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ovalWidth = constraints.maxWidth * 0.72;
        final ovalHeight = constraints.maxHeight * 0.58;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Lớp phủ nền mờ tối xung quanh
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: ovalWidth,
                      height: ovalHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(180, 240),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viền oval phát sáng hiển thị hướng dẫn
            Align(
              alignment: Alignment.center,
              child: Container(
                width: ovalWidth,
                height: ovalHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(180, 240),
                  ),
                  border: Border.all(
                    color: isValid ? AppColors.accent : AppColors.error,
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isValid ? AppColors.accent : AppColors.error)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Điểm ngắm tâm mắt (Center Eye Guideline)
            Positioned(
              top: (constraints.maxHeight - ovalHeight) / 2 + ovalHeight * 0.38,
              child: Container(
                width: ovalWidth * 0.65,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),

            // Thông điệp hướng dẫn phía trên
            Positioned(
              top: AppDimensions.xxl,
              left: AppDimensions.lg,
              right: AppDimensions.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: AppDimensions.borderRadiusMd,
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isValid
                          ? Icons.camera_front_rounded
                          : Icons.warning_amber_rounded,
                      color: isValid ? AppColors.accent : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Flexible(
                      child: Text(
                        guideMessage ??
                            'Giữ thẳng đầu và căn khuôn mặt vào khung oval',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hướng dẫn chi tiết phía dưới
            Positioned(
              bottom: AppDimensions.xl,
              left: AppDimensions.lg,
              right: AppDimensions.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: AppDimensions.borderRadiusMd,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTipItem(
                          Icons.wb_sunny_outlined,
                          'Đảm bảo đủ ánh sáng, không ngược sáng',
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        _buildTipItem(
                          Icons.face_retouching_natural_outlined,
                          'Tháo kính râm, khẩu trang hoặc mũ che trán',
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        _buildTipItem(
                          Icons.crop_free_outlined,
                          'Nhìn trực diện vào camera, không nghiêng đầu',
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null) ...[
                    const SizedBox(height: AppDimensions.md),
                    TextButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, color: Colors.white70),
                      label: Text(
                        'Đóng khung hướng dẫn',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
