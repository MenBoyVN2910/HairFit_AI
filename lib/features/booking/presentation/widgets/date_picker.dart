// ============================================================================
// File: lib/features/booking/presentation/widgets/date_picker.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng booking.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/business_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/barber_profile_model.dart';
import '../../data/slot_service.dart';

/// Widget chọn ngày hẹn (trong phạm vi 30 ngày)
class BookingDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final BarberProfileModel barber;
  final ValueChanged<DateTime> onDateSelected;

  const BookingDatePicker({
    super.key,
    required this.selectedDate,
    required this.barber,
    required this.onDateSelected,
  });

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  bool _isDayClosed(DateTime date) {
    final dateStr = DateFormatter.toIsoDateString(date);

    // Kiểm tra ngày nghỉ ngoại lệ
    final hasException = barber.exceptions.any(
      (e) => e.date == dateStr && e.closed,
    );
    if (hasException) return true;

    // Kiểm tra ngày nghỉ định kỳ trong tuần
    final dayKey = SlotService.weekdayToKey(date.weekday);
    final dayConfig = barber.workingHours[dayKey];
    return dayConfig == null || dayConfig.closed;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(
      BusinessConstants.maxBookingDaysAhead,
      (index) => today.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('2. Chọn ngày hẹn', style: AppTextStyles.h4),
            Text(
              DateFormatter.formatFullDate(selectedDate),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimensions.sm),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected =
                  selectedDate.year == date.year &&
                  selectedDate.month == date.month &&
                  selectedDate.day == date.day;
              final isClosed = _isDayClosed(date);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return InkWell(
                onTap: isClosed ? null : () => onDateSelected(date),
                borderRadius: AppDimensions.borderRadiusMd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 64,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: AppDimensions.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isClosed
                              ? AppColors.background.withValues(alpha: 0.6)
                              : AppColors.surface),
                    borderRadius: AppDimensions.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isClosed
                                ? AppColors.divider.withValues(alpha: 0.5)
                                : AppColors.divider),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? 'Hôm nay' : _getWeekdayShort(date.weekday),
                        style: TextStyle(
                          fontSize: isToday ? 10 : 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? (isToday ? AppColors.accent : Colors.white70)
                              : (isClosed
                                    ? AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isClosed
                                    ? AppColors.textSecondary.withValues(
                                        alpha: 0.4,
                                      )
                                    : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isClosed ? 'Nghỉ' : 'Th.${date.month}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : (isClosed
                                    ? AppColors.error.withValues(alpha: 0.7)
                                    : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
