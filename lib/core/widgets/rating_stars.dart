import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Widget hiển thị đánh giá sao (1-5 sao) kèm số lượng đánh giá
class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final bool showRatingNumber;
  final Color starColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 16.0,
    this.showRatingNumber = true,
    this.starColor = const Color(0xFFFFB800),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          size: starSize,
          color: starColor,
        ),
        const SizedBox(width: AppDimensions.xxs),
        if (showRatingNumber) ...[
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'Mới',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (reviewCount != null && reviewCount! > 0) ...[
          const SizedBox(width: AppDimensions.xxs),
          Text(
            '($reviewCount)',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
