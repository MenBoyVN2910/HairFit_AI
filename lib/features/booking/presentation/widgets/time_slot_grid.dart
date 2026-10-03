// ============================================================================
// File: lib/features/booking/presentation/widgets/time_slot_grid.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng booking.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/slot_service.dart';

/// Widget hiển thị lưới các khung giờ (Task 4.8)
///
/// Hỗ trợ 3 trạng thái rõ ràng:
/// 1. Khả dụng (Trống, sẵn sàng đặt)
/// 2. Đang được chọn (Highlighted)
/// 3. Không khả dụng (Đã có người đặt hoặc đã qua giờ)
class TimeSlotGrid extends StatelessWidget {
  final List<AvailableSlot> slots;
  final AvailableSlot? selectedSlot;
  final bool isLoading;
  final ValueChanged<AvailableSlot> onSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.isLoading,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('3. Chọn khung giờ', style: AppTextStyles.h4),
            if (!isLoading && slots.isNotEmpty)
              Text(
                '${slots.where((s) => s.isAvailable).length} giờ trống',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        if (isLoading)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.accent),
          )
        else if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.borderRadiusMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppDimensions.xs),
                Text(
                  'Không có khung giờ trống trong ngày này',
                  style: AppTextStyles.labelMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2),
                Text(
                  'Tiệm có thể đóng cửa hoặc đã kín lịch. Vui lòng chọn ngày khác.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
              mainAxisSpacing: AppDimensions.sm,
              crossAxisSpacing: AppDimensions.sm,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.5 : 2.1,
            ),
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = selectedSlot?.startTime == slot.startTime;
              final isAvailable = slot.isAvailable;

              return InkWell(
                onTap: isAvailable ? () => onSlotSelected(slot) : null,
                borderRadius: AppDimensions.borderRadiusSm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : (isAvailable
                              ? AppColors.surface
                              : AppColors.background.withValues(alpha: 0.8)),
                    borderRadius: AppDimensions.borderRadiusSm,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : (isAvailable
                                ? AppColors.divider
                                : AppColors.divider.withValues(alpha: 0.5)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.startTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isAvailable
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isAvailable
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.5,
                                        )),
                            decoration: isAvailable
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          isAvailable
                              ? 'Trống'
                              : (slot.unavailabilityReason?.contains('sát') ??
                                        false
                                    ? 'Sát giờ'
                                    : (slot.unavailabilityReason?.contains(
                                                'Đã qua',
                                              ) ??
                                              false
                                          ? 'Quá giờ'
                                          : 'Đã đặt')),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white70
                                : (isAvailable
                                      ? AppColors.success
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.6,
                                        )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
