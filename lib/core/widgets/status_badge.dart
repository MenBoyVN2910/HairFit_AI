import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Huy hiệu (Badge) hiển thị trạng thái lịch hẹn hoặc trạng thái duyệt thợ
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isApproval; // true: approvalStatus, false: appointmentStatus

  const StatusBadge({
    super.key,
    required this.status,
    this.isApproval = false,
  });

  const StatusBadge.appointment({
    super.key,
    required this.status,
  }) : isApproval = false;

  const StatusBadge.approval({
    super.key,
    required this.status,
  }) : isApproval = true;

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(status.toLowerCase().trim());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xxs,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Text(
            config.label,
            style: AppTextStyles.badgeText.copyWith(color: config.textColor),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(String normalizedStatus) {
    if (isApproval) {
      switch (normalizedStatus) {
        case 'approved':
          return const _BadgeConfig(
            label: 'Đã duyệt',
            textColor: AppColors.success,
            backgroundColor: AppColors.successLight,
            borderColor: Color(0xFFC7EBD1),
          );
        case 'rejected':
          return const _BadgeConfig(
            label: 'Từ chối',
            textColor: AppColors.error,
            backgroundColor: AppColors.errorLight,
            borderColor: Color(0xFFFFD1CF),
          );
        case 'pending':
        default:
          return const _BadgeConfig(
            label: 'Chờ duyệt',
            textColor: AppColors.warning,
            backgroundColor: AppColors.warningLight,
            borderColor: Color(0xFFFFE0B2),
          );
      }
    } else {
      switch (normalizedStatus) {
        case 'confirmed':
          return const _BadgeConfig(
            label: 'Đã xác nhận',
            textColor: AppColors.success,
            backgroundColor: AppColors.successLight,
            borderColor: Color(0xFFC7EBD1),
          );
        case 'completed':
          return const _BadgeConfig(
            label: 'Hoàn tất',
            textColor: AppColors.tertiary,
            backgroundColor: Color(0xFFE8EEF8),
            borderColor: Color(0xFFC4D5F0),
          );
        case 'cancelled':
          return const _BadgeConfig(
            label: 'Đã hủy',
            textColor: AppColors.textSecondary,
            backgroundColor: Color(0xFFF0F0F2),
            borderColor: AppColors.divider,
          );
        case 'rejected':
          return const _BadgeConfig(
            label: 'Đã từ chối',
            textColor: AppColors.error,
            backgroundColor: AppColors.errorLight,
            borderColor: Color(0xFFFFD1CF),
          );
        case 'pending':
        default:
          return const _BadgeConfig(
            label: 'Chờ thợ duyệt',
            textColor: AppColors.warning,
            backgroundColor: AppColors.warningLight,
            borderColor: Color(0xFFFFE0B2),
          );
      }
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _BadgeConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
