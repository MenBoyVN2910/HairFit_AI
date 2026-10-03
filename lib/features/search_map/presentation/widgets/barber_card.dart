// ============================================================================
// File: lib/features/search_map/presentation/widgets/barber_card.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng search_map.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../providers/search_provider.dart';

/// Card thông tin thợ cắt tóc hiển thị trong danh sách tìm kiếm (Task 3.8)
class BarberCard extends StatelessWidget {
  final BarberWithDistance item;
  final VoidCallback? onTap;

  const BarberCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final barber = item.barber;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusMd,
        side: BorderSide(
          color: item.isMatchingHairstyle
              ? AppColors.accent.withValues(alpha: 0.6)
              : AppColors.border,
          width: item.isMatchingHairstyle ? 1.5 : 1.0,
        ),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar thợ / tiệm
                  AppAvatar(
                    imageUrl: barber.avatarUrl,
                    fallbackUrl: barber.coverUrl,
                    name: barber.displayName,
                    width: 68,
                    height: 68,
                    borderRadius: AppDimensions.borderRadiusSm,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.storefront_rounded,
                  ),
                  const SizedBox(width: AppDimensions.md),

                  // Thông tin cơ bản
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                barber.displayName,
                                style: AppTextStyles.h4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isMatchingHairstyle) ...[
                              const SizedBox(width: AppDimensions.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 11,
                                      color: AppColors.accent,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Phù hợp',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Đánh giá sao
                        Row(
                          children: [
                            RatingStars(
                              rating: barber.ratingAvg,
                              starSize: 13,
                              showRatingNumber: false,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              barber.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' (${barber.ratingCount})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Địa chỉ
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                barber.address,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppDimensions.sm),

              // Khoảng cách và mức giá
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Khoảng cách
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Cách bạn ${item.distanceFormatted}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),

                  // Khoảng giá
                  Text(
                    DateFormatter.formatPriceRange(
                      barber.priceMin,
                      barber.priceMax,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
