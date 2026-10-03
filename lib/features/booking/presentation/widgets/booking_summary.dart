// ============================================================================
// File: lib/features/booking/presentation/widgets/booking_summary.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng booking.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/barber_profile_model.dart';
import '../../../../models/service_model.dart';
import '../../data/slot_service.dart';

/// Widget tóm tắt chi tiết lịch hẹn trước khi xác nhận (Task 4.7)
class BookingSummary extends StatelessWidget {
  final BarberProfileModel barber;
  final ServiceModel? service;
  final DateTime selectedDate;
  final AvailableSlot? selectedSlot;
  final String note;
  final ValueChanged<String> onNoteChanged;

  const BookingSummary({
    super.key,
    required this.barber,
    required this.service,
    required this.selectedDate,
    required this.selectedSlot,
    required this.note,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('4. Thông tin tóm tắt & ghi chú', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _buildRow(
                icon: Icons.storefront_rounded,
                label: 'Tiệm cắt tóc',
                value: barber.displayName,
              ),
              const Divider(height: 16),
              _buildRow(
                icon: Icons.content_cut_rounded,
                label: 'Dịch vụ',
                value: service != null
                    ? '${service!.name} (${service!.durationMinutes}p)'
                    : 'Chưa chọn',
              ),
              const Divider(height: 16),
              _buildRow(
                icon: Icons.calendar_today_rounded,
                label: 'Ngày hẹn',
                value: DateFormatter.formatFullDate(selectedDate),
              ),
              const Divider(height: 16),
              _buildRow(
                icon: Icons.access_time_rounded,
                label: 'Thời gian',
                value: selectedSlot != null
                    ? '${selectedSlot!.startTime} - ${selectedSlot!.endTime}'
                    : 'Chưa chọn khung giờ',
                highlightValue: selectedSlot != null,
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán (tại tiệm)',
                    style: AppTextStyles.labelMedium,
                  ),
                  Text(
                    service != null
                        ? DateFormatter.formatCurrency(service!.price)
                        : '0 đ',
                    style: AppTextStyles.h3.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        AppTextField(
          label: 'Ghi chú cho thợ (không bắt buộc)',
          hintText: 'Ví dụ: Cắt ngắn gọn gàng, sấy phồng chân tóc...',
          initialValue: note,
          maxLines: 2,
          onChanged: onNoteChanged,
        ),
      ],
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.sm),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              color: highlightValue ? AppColors.accent : AppColors.textPrimary,
              fontWeight: highlightValue ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
