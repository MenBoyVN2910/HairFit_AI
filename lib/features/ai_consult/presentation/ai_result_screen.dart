import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../providers/ai_consult_provider.dart';
import 'widgets/hairstyle_result_card.dart';

/// Màn hình hiển thị kết quả phân tích AI & gợi ý kiểu tóc chi tiết (Task 5.12, 5.14)
class AIResultScreen extends ConsumerWidget {
  const AIResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiConsultProvider);
    final success = aiState.successResult;

    if (success == null || success.recommendation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kết Quả Phân Tích', style: AppTextStyles.h3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: EmptyState(
            title: 'Chưa có kết quả phân tích',
            message: 'Vui lòng chụp ảnh hoặc chọn dáng mặt để xem gợi ý kiểu tóc.',
            actionText: 'Quay lại chụp ảnh',
            icon: Icons.camera_alt_outlined,
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final shape = success.faceShape;
    final recommendation = success.recommendation!;
    final metrics = success.metrics;
    final executionMs = aiState.executionTimeMs ?? 45;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kết Quả AI Tư Vấn', style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Chọn thủ công',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/customer/manual-select'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Banner: Dáng mặt được xác định + Thời gian phân tích On-Device
            _buildFaceShapeHeader(context, shape, executionMs),
            const SizedBox(height: AppDimensions.lg),

            // 2. Chỉ số hình học nhân trắc (nếu phân tích từ camera ML Kit)
            if (metrics != null) ...[
              _buildMetricsCard(metrics),
              const SizedBox(height: AppDimensions.lg),
            ],

            // 3. Lời khuyên vàng & Điều nên tránh
            _buildAdviceCard(
              generalAdvice: recommendation.generalAdviceVi,
              avoidAdvice: recommendation.avoidAdviceVi,
            ),
            const SizedBox(height: AppDimensions.xl),

            // 4. Danh sách các kiểu tóc đề xuất chính (Top Recommendations)
            Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  'Top Kiểu Tóc Phù Hợp Nhất',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Được tính toán và xếp hạng theo ma trận quy tắc chuyên gia kết hợp hình học khuôn mặt của bạn.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.md),

            ...recommendation.primaryRecommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final rec = entry.value;
              return HairstyleResultCard(
                rank: index + 1,
                recommendation: rec,
                onFindBarbers: () {
                  // Chuyển tiếp sang bản đồ tìm thợ có filter theo kiểu tóc này (Task 5.14)
                  context.push('/customer/search?hairstyleId=${rec.style.id}');
                },
              );
            }),

            // 5. Gợi ý thay thế nếu có
            if (recommendation.alternativeRecommendations.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.md),
              Text(
                'Kiểu tóc thay thế khác để thử nghiệm:',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppDimensions.sm),
              ...recommendation.alternativeRecommendations.map((rec) {
                return HairstyleResultCard(
                  rank: 4,
                  recommendation: rec,
                  onFindBarbers: () {
                    context.push('/customer/search?hairstyleId=${rec.style.id}');
                  },
                );
              }),
            ],

            const SizedBox(height: AppDimensions.xl),

            // 6. Nút hành động phụ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Phân tích ảnh khác'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/customer/search'),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Xem tất cả thợ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceShapeHeader(
    BuildContext context,
    dynamic shape,
    int executionMs,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDimensions.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: AppColors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÁNG KHUÔN MẶT CỦA BẠN',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      shape.displayNameVi,
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: AppDimensions.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${executionMs}ms',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            shape.descriptionVi,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(dynamic metrics) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: AppDimensions.xs),
              Text(
                'Chỉ số hình học nhân trắc (132 Điểm Contours)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: AppDimensions.md),
          Row(
            children: [
              _buildMetricItem(
                'Tỷ lệ Dài/Rộng',
                metrics.aspectRatio.toStringAsFixed(2),
                'Mặt chuẩn: 1.3 - 1.5',
              ),
              _buildMetricItem(
                'Độ vuông hàm',
                metrics.jawToCheekRatio.toStringAsFixed(2),
                '>= 0.86 là mặt vuông',
              ),
              _buildMetricItem(
                'Trán / Quai hàm',
                metrics.foreheadToJawRatio.toStringAsFixed(2),
                '> 1.2 là mặt trái tim',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String hint) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard({
    required String generalAdvice,
    required String avoidAdvice,
  }) {
    return Column(
      children: [
        // Lời khuyên vàng
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lời khuyên vàng khi tạo kiểu:',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      generalAdvice,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // Điều nên tránh
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.highlight_off_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiểu tóc nên tránh:',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      avoidAdvice,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
