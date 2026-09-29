import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/ai_consult_provider.dart';
import '../domain/face_shape.dart';

/// Màn hình chọn dáng mặt thủ công - Phương án dự phòng hoàn hảo khi không chụp ảnh (Task 5.13)
class ManualSelectScreen extends ConsumerStatefulWidget {
  const ManualSelectScreen({super.key});

  @override
  ConsumerState<ManualSelectScreen> createState() => _ManualSelectScreenState();
}

class _ManualSelectScreenState extends ConsumerState<ManualSelectScreen> {
  FaceShape? _selectedShape;

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiConsultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chọn Dáng Mặt Thủ Công', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner giải thích
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: AppDimensions.borderRadiusMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      'Nếu bạn không tiện chụp ảnh hoặc camera bị lỗi, hãy chọn dáng khuôn mặt tương đồng nhất dưới đây. Thuật toán chuyên gia sẽ lập tức đề xuất kiểu tóc tối ưu.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            Text(
              'Danh sách các dáng khuôn mặt chuẩn:',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.md),

            // Danh sách các dáng mặt
            ...FaceShape.values.map((shape) {
              final isSelected = _selectedShape == shape;
              return _buildFaceShapeCard(shape, isSelected);
            }),

            const SizedBox(height: AppDimensions.xxl),

            // Nút bấm xác nhận & xem kết quả
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _selectedShape == null || aiState.isAnalyzing
                    ? null
                    : () async {
                        await ref
                            .read(aiConsultProvider.notifier)
                            .selectManualFaceShape(_selectedShape!);
                        if (context.mounted) {
                          context.push('/customer/ai-result');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.borderRadiusMd,
                  ),
                ),
                icon: aiState.isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  aiState.isAnalyzing
                      ? 'Đang đối soát quy tắc...'
                      : 'Xem gợi ý kiểu tóc cho ${_selectedShape?.displayNameVi ?? ""}',
                  style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceShapeCard(FaceShape shape, bool isSelected) {
    final meta = _getShapeMetadata(shape);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedShape = shape;
        });
      },
      borderRadius: AppDimensions.borderRadiusLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppDimensions.md),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDimensions.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon biểu trưng dáng mặt
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: AppDimensions.borderRadiusMd,
              ),
              child: Icon(
                meta.icon,
                color: isSelected ? AppColors.accent : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.md),

            // Nội dung đặc điểm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        shape.displayNameVi,
                        style: AppTextStyles.h4.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        '(${shape.name.toUpperCase()})',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.accent : AppColors.divider,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.features,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.styleHint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _FaceShapeMeta _getShapeMetadata(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:
        return const _FaceShapeMeta(
          icon: Icons.egg_outlined,
          features: 'Tỷ lệ hoàng kim cân đối, cằm thuôn tròn nhẹ.',
          styleHint: 'Hợp với gần như mọi kiểu tóc: Undercut, Side Part, Layer, Pompadour...',
        );
      case FaceShape.round:
        return const _FaceShapeMeta(
          icon: Icons.circle_outlined,
          features: 'Chiều dài và rộng tương đương, xương hàm tròn mềm.',
          styleHint: 'Nên sấy vuốt phồng cao đỉnh đầu (Pompadour, Quiff) và fade gọn 2 bên để kéo thon mặt.',
        );
      case FaceShape.square:
        return const _FaceShapeMeta(
          icon: Icons.crop_square_rounded,
          features: 'Khung xương quai hàm mạnh mẽ, vuông vức, góc cạnh.',
          styleHint: 'Ưu tiên Side part rẽ ngôi chéo, textured quiff hoặc undercut làm mềm đường góc cạnh.',
        );
      case FaceShape.heart:
        return const _FaceShapeMeta(
          icon: Icons.favorite_border_rounded,
          features: 'Trán rộng, gò má cao và cằm thon gọn nhọn dần.',
          styleHint: 'Hợp với kiểu tóc có mái rủ, Layer tỉa tầng, Middle part rẽ ngôi cân đối phần trán.',
        );
      case FaceShape.oblong:
        return const _FaceShapeMeta(
          icon: Icons.rectangle_outlined,
          features: 'Chiều dọc khuôn mặt dài hơn bề ngang rõ rệt.',
          styleHint: 'Nên chọn mái rủ hoặc tạo độ phồng nhẹ hai bên để làm gương mặt trông đầy đặn hơn.',
        );
    }
  }
}

class _FaceShapeMeta {
  final IconData icon;
  final String features;
  final String styleHint;

  const _FaceShapeMeta({
    required this.icon,
    required this.features,
    required this.styleHint,
  });
}
