// ============================================================================
// File: lib/features/booking/presentation/widgets/service_selector.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng booking.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/service_model.dart';

/// Widget chọn dịch vụ cắt tóc / tạo kiểu (Task 4.7)
class ServiceSelector extends StatelessWidget {
  final List<ServiceModel> services;
  final ServiceModel? selectedService;
  final ValueChanged<ServiceModel> onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.services,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadiusMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            'Thợ chưa đăng ký dịch vụ nào.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1. Chọn dịch vụ', style: AppTextStyles.h4),
            Text(
              '${services.length} dịch vụ',
              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.sm),
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = selectedService?.id == service.id;

            return InkWell(
              onTap: () => onServiceSelected(service),
              borderRadius: AppDimensions.borderRadiusMd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.05)
                      : AppColors.surface,
                  borderRadius: AppDimensions.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.divider,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.durationMinutes} phút',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.formatCurrency(service.price),
                      style: AppTextStyles.h4.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
