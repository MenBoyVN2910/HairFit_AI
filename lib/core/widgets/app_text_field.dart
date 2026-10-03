// ============================================================================
// File: lib/core/widgets/app_text_field.dart
// Mục đích: Thành phần giao diện (Widget) dùng chung.
// Kết cấu:
//  - Widget tái sử dụng (Reusable Widget) nhận tham số qua constructor và không chứa logic nghiệp vụ phức tạp.
// ============================================================================

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Ô nhập liệu chuẩn của ứng dụng với hỗ trợ ẩn/hiện mật khẩu, icon, validation
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;

    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.xs),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          style: AppTextStyles.bodyMedium,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: effectiveSuffixIcon,
          ),
        ),
      ],
    );
  }
}
