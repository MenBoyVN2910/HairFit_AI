// ============================================================================
// File: lib/features/search_map/presentation/widgets/barber_bottom_sheet.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng search_map.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../providers/search_provider.dart';

/// Bottom sheet hiển thị tóm tắt thông tin thợ khi bấm vào marker trên bản đồ (Task 3.6)
class BarberBottomSheet extends StatelessWidget {
  final BarberWithDistance item;

  const BarberBottomSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, BarberWithDistance item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarberBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barber = item.barber;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLg),
          topRight: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.md,
        AppDimensions.lg,
        AppDimensions.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Header: Avatar, Name, Rating, Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: barber.avatarUrl,
                fallbackUrl: barber.coverUrl,
                name: barber.displayName,
                width: 72,
                height: 72,
                borderRadius: AppDimensions.borderRadiusMd,
                fit: BoxFit.cover,
                fallbackIcon: Icons.storefront_rounded,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            barber.displayName,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(
                          rating: barber.ratingAvg,
                          starSize: 15,
                          showRatingNumber: false,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          barber.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' (${barber.ratingCount} đánh giá)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cách bạn ${item.distanceFormatted}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          if (item.isMatchingHairstyle) ...[
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppDimensions.borderRadiusSm,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Thợ có hỗ trợ cắt kiểu tóc phù hợp với khuôn mặt bạn!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimensions.md),

          // Địa chỉ chi tiết
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(barber.address, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Khoảng giá
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Khoảng giá: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                DateFormatter.formatPriceRange(
                  barber.priceMin,
                  barber.priceMax,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          // Xem nhanh dịch vụ nếu có
          if (barber.services.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            Text(
              'Dịch vụ tiêu biểu (${barber.services.length} dịch vụ)',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppDimensions.xs),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: barber.services.take(3).map((s) {
                return Chip(
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.border),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${s.name} • ${DateFormatter.formatCurrency(s.price)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppDimensions.lg),

          // Hai nút hành động: Xem chi tiết & Đặt lịch
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  text: 'Xem chi tiết',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/customer/barber/${barber.uid}');
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: AppButton(
                  text: 'Đặt lịch ngay',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/customer/booking/${barber.uid}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
