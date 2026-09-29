import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/hairstyle_recommendation_engine.dart';

/// Card hiển thị chi tiết một kiểu tóc được AI gợi ý (Task 5.10, 5.12)
/// Bao gồm: Tên kiểu, ảnh minh họa, điểm tương thích (Match Score),
/// lý do nhân trắc học phù hợp, mẹo tạo nếp thực tế và nút CTA tìm thợ
class HairstyleResultCard extends StatelessWidget {
  final RecommendedHairstyle recommendation;
  final int rank; // 1, 2, 3...
  final VoidCallback onFindBarbers;

  const HairstyleResultCard({
    super.key,
    required this.recommendation,
    required this.rank,
    required this.onFindBarbers,
  });

  @override
  Widget build(BuildContext context) {
    final style = recommendation.style;
    final matchPercent = (recommendation.matchScore * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.borderRadiusLg,
        border: Border.all(
          color: rank == 1 ? AppColors.accent.withValues(alpha: 0.5) : AppColors.divider,
          width: rank == 1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: rank == 1 ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Rank badge + Tên kiểu tóc + Match Score
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              AppDimensions.md,
              AppDimensions.md,
              AppDimensions.xs,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rank == 1 ? AppColors.accent : AppColors.secondary,
                    borderRadius: AppDimensions.borderRadiusSm,
                  ),
                  child: Text(
                    '#$rank GỢI Ý',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                Expanded(
                  child: Text(
                    style.name,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: AppDimensions.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$matchPercent% Phù hợp',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mô tả ngắn & Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            child: Text(
              style.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          if (style.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.md,
                AppDimensions.xs,
                AppDimensions.md,
                0,
              ),
              child: Wrap(
                spacing: AppDimensions.xs,
                children: style.tags.map((tag) {
                  return Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.background,
                    padding: EdgeInsets.zero,
                    label: Text(
                      '#$tag',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: AppDimensions.sm),

          // Khối ảnh kiểu tóc minh họa
          if (style.imageUrl.isNotEmpty)
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              decoration: BoxDecoration(
                borderRadius: AppDimensions.borderRadiusMd,
                color: AppColors.background,
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: style.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildImageFallback(),
              ),
            )
          else
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppDimensions.borderRadiusMd,
              ),
              child: _buildImageFallback(),
            ),

          const SizedBox(height: AppDimensions.md),

          // Khối lý do AI đề xuất (Match Reason)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: AppDimensions.borderRadiusMd,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tại sao hợp với khuôn mặt bạn?',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.matchReasonVi,
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

          // Mẹo tạo nếp thực tế (Styling Tips) nếu có
          if (recommendation.stylingTips.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        'Mẹo sấy & vuốt tạo nếp chuẩn salon:',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...recommendation.stylingTips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(' • ', style: TextStyle(color: AppColors.accent)),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.md),

          // Nút CTA: Tìm thợ cắt kiểu này
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              0,
              AppDimensions.md,
              AppDimensions.md,
            ),
            child: AppButton(
              text: 'Tìm thợ cắt kiểu ${style.name}',
              icon: const Icon(Icons.map_outlined, color: Colors.white, size: 18),
              onPressed: onFindBarbers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.content_cut_rounded,
            size: 36,
            color: AppColors.accent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.style.name,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
