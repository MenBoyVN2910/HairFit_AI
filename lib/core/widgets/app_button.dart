// ============================================================================
// File: lib/core/widgets/app_button.dart
// Mục đích: Thành phần giao diện (Widget) dùng chung.
// Kết cấu:
//  - Widget tái sử dụng (Reusable Widget) nhận tham số qua constructor và không chứa logic nghiệp vụ phức tạp.
// ============================================================================

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, text }

/// Nút bấm chuẩn của ứng dụng HairFit AI với đầy đủ hiệu ứng và trạng thái loading
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? customBackgroundColor;
  final Color? customTextColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimensions.buttonHeightMd,
    this.customBackgroundColor,
    this.customTextColor,
  });

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimensions.buttonHeightMd,
    this.customBackgroundColor,
    this.customTextColor,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimensions.buttonHeightMd,
    this.customBackgroundColor,
    this.customTextColor,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeightSm,
    this.customBackgroundColor,
    this.customTextColor,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent;
    if (isLoading) {
      final spinnerColor =
          (variant == AppButtonVariant.outline ||
              variant == AppButtonVariant.text)
          ? (customTextColor ?? AppColors.primary)
          : Colors.white;

      childContent = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else {
      final textColor = _getTextColor();
      final textWidget = Text(
        text,
        style: AppTextStyles.buttonMedium.copyWith(color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      if (icon != null) {
        childContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            const SizedBox(width: AppDimensions.sm),
            Flexible(child: textWidget),
          ],
        );
      } else {
        childContent = textWidget;
      }
    }

    final container = SizedBox(
      width: width,
      height: height,
      child: _buildButtonByVariant(effectiveOnPressed, childContent),
    );

    return container;
  }

  Widget _buildButtonByVariant(VoidCallback? handler, Widget child) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: handler,
          style: ElevatedButton.styleFrom(
            backgroundColor: customBackgroundColor ?? AppColors.accent,
            foregroundColor: customTextColor ?? Colors.white,
            disabledBackgroundColor: AppColors.textSecondary.withValues(
              alpha: 0.3,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusMd,
            ),
          ),
          child: child,
        );

      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: handler,
          style: ElevatedButton.styleFrom(
            backgroundColor: customBackgroundColor ?? AppColors.primary,
            foregroundColor: customTextColor ?? Colors.white,
            disabledBackgroundColor: AppColors.textSecondary.withValues(
              alpha: 0.3,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusMd,
            ),
          ),
          child: child,
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: handler,
          style: OutlinedButton.styleFrom(
            backgroundColor: customBackgroundColor ?? Colors.transparent,
            foregroundColor: customTextColor ?? AppColors.primary,
            side: BorderSide(
              color: handler == null
                  ? AppColors.border
                  : (customTextColor ?? AppColors.primary),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusMd,
            ),
          ),
          child: child,
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: handler,
          style: TextButton.styleFrom(
            foregroundColor: customTextColor ?? AppColors.accent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
          ),
          child: child,
        );
    }
  }

  Color _getTextColor() {
    if (customTextColor != null) return customTextColor!;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return Colors.white;
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.text:
        return AppColors.accent;
    }
  }
}
