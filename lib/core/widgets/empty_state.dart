// ============================================================================
// File: lib/core/widgets/empty_state.dart
// Mục đích: Thành phần giao diện (Widget) dùng chung.
// Kết cấu:
//  - Widget tái sử dụng (Reusable Widget) nhận tham số qua constructor và không chứa logic nghiệp vụ phức tạp.
// ============================================================================

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

/// Widget hiển thị trạng thái danh sách hoặc dữ liệu trống (Empty State)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customIllustration;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            customIllustration ??
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppDimensions.iconXl,
                    color: AppColors.textSecondary,
                  ),
                ),
            const SizedBox(height: AppDimensions.lg),
            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.xs),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.xl),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
