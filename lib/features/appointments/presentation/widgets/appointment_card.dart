import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/appointment_model.dart';

/// Card hiển thị thông tin lịch hẹn cắt tóc (Task 4.14)
///
/// Hỗ trợ cả 2 chế độ hiển thị:
/// - Khách hàng (isBarberView = false): Hiển thị tên thợ, cho phép hủy lịch trước 30 phút
/// - Thợ cắt tóc (isBarberView = true): Hiển thị tên khách, nút Tiếp nhận, Từ chối, Hoàn tất
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isBarberView;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isBarberView = false,
    this.onCancel,
    this.onConfirm,
    this.onReject,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Thời gian & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusMd),
                topRight: Radius.circular(AppDimensions.radiusMd),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Text(
                      '${appointment.startTime} - ${appointment.endTime}, ${DateFormatter.formatShortDate(appointment.startTimestamp)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                StatusBadge.appointment(status: appointment.status.toStatusString()),
              ],
            ),
          ),

          // Body: Thông tin đối tác, dịch vụ và giá
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBarberView
                            ? Icons.person_outline_rounded
                            : Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBarberView
                                ? 'Khách hàng: ${appointment.customerName}'
                                : appointment.barberName,
                            style: AppTextStyles.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dịch vụ: ${appointment.serviceName} (${appointment.durationMinutes} phút)',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.formatCurrency(appointment.price),
                      style: AppTextStyles.h4.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),

                // Ghi chú nếu có
                if (appointment.note.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppDimensions.borderRadiusSm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ghi chú: ${appointment.note}',
                            style: AppTextStyles.caption.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons cho Customer hoặc Barber
                const SizedBox(height: AppDimensions.sm),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (!isBarberView) {
      // Giao diện Khách hàng: Có thể hủy nếu status là pending/confirmed và >= 30m trước giờ hẹn
      if (appointment.isPending || appointment.isConfirmed) {
        final canCancel = appointment.canCustomerCancel();
        return Align(
          alignment: Alignment.centerRight,
          child: canCancel
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadiusSm,
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Hủy lịch hẹn', style: TextStyle(fontSize: 13)),
                  onPressed: onCancel,
                )
              : const Text(
                  'Không thể hủy (quá sát giờ hẹn < 30 phút)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        );
      }
      return const SizedBox.shrink();
    }

    // Giao diện Thợ cắt tóc
    if (appointment.isPending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.borderRadiusSm,
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Từ chối', style: TextStyle(fontSize: 13)),
            onPressed: onReject,
          ),
          const SizedBox(width: AppDimensions.sm),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.borderRadiusSm,
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Tiếp nhận', style: TextStyle(fontSize: 13)),
            onPressed: onConfirm,
          ),
        ],
      );
    } else if (appointment.isConfirmed) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusSm,
            ),
          ),
          icon: const Icon(Icons.task_alt_rounded, size: 16),
          label: const Text('Hoàn tất dịch vụ', style: TextStyle(fontSize: 13)),
          onPressed: onComplete,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
