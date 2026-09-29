import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

/// Widget hiển thị thông báo lỗi kèm nút "Thử lại" (Error & Retry)
class ErrorRetry extends StatelessWidget {
  final String? title;
  final String errorMessage;
  final VoidCallback onRetry;
  final String retryButtonText;
  final IconData icon;

  const ErrorRetry({
    super.key,
    this.title,
    required this.errorMessage,
    required this.onRetry,
    this.retryButtonText = 'Thử lại',
    this.icon = Icons.error_outline_rounded,
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconLg,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              title ?? 'Đã xảy ra sự cố',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              errorMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xl),
            AppButton(
              text: retryButtonText,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              onPressed: onRetry,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
