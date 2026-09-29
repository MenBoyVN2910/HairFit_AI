import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

/// Widget hiển thị lỗi kèm nút "Thử lại" thân thiện
class ErrorRetry extends StatelessWidget {
  final String message;
  final String? hint;
  final VoidCallback onRetry;
  final String retryText;
  final IconData icon;

  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.hint,
    this.retryText = 'Thử lại',
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 52.0,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              message,
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: AppDimensions.xs),
              Text(
                hint!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppDimensions.xl),
            AppButton(
              text: retryText,
              onPressed: onRetry,
              width: 180,
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
