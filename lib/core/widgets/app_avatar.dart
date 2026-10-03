// ============================================================================
// File: lib/core/widgets/app_avatar.dart
// Mục đích: Thành phần giao diện (Widget) hiển thị avatar/ảnh đại diện đa năng.
// Kết cấu:
//  - Hỗ trợ mạng (CachedNetworkImage), Base64 (Data URI & Raw), Asset,
//    fallback tên chữ cái đầu (initial letter) hoặc Icon dự phòng.
// ============================================================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Helper tạo ImageProvider từ chuỗi URL mạng hoặc Base64 data URI
ImageProvider? getAvatarImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();

  if (clean.startsWith('data:image')) {
    try {
      final commaIdx = clean.indexOf(',');
      final base64Str = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return CachedNetworkImageProvider(clean);
  }

  // Thử parse nếu là raw base64 hợp lệ
  if (clean.length > 50 && !clean.contains('/') && !clean.contains(':')) {
    try {
      return MemoryImage(base64Decode(clean));
    } catch (_) {
      return null;
    }
  }

  return null;
}

/// Widget hiển thị avatar thợ / người dùng chuẩn, tương thích với cả URL mạng và Base64
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackUrl;
  final String? name;
  final double? width;
  final double? height;
  final double? size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;
  final TextStyle? textStyle;
  final Border? border;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.fallbackUrl,
    this.name,
    this.width,
    this.height,
    this.size,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.textStyle,
    this.border,
  });

  /// Factory tiện lợi cho Avatar hình tròn
  const AppAvatar.circle({
    super.key,
    this.imageUrl,
    this.fallbackUrl,
    this.name,
    required double radius,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.textStyle,
    this.border,
  }) : shape = BoxShape.circle,
       size = radius * 2,
       width = radius * 2,
       height = radius * 2,
       borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = size ?? width ?? 48.0;
    final effectiveHeight = size ?? height ?? 48.0;

    final primaryUrl = imageUrl?.trim() ?? '';
    final secondaryUrl = fallbackUrl?.trim() ?? '';
    final targetUrl = primaryUrl.isNotEmpty ? primaryUrl : secondaryUrl;

    Widget content;
    if (targetUrl.isNotEmpty) {
      if (targetUrl.startsWith('data:image')) {
        content = _buildBase64Image(targetUrl, effectiveWidth, effectiveHeight);
      } else if (targetUrl.startsWith('http://') ||
          targetUrl.startsWith('https://')) {
        content = _buildNetworkImage(
          targetUrl,
          effectiveWidth,
          effectiveHeight,
        );
      } else if (targetUrl.startsWith('assets/')) {
        content = Image.asset(
          targetUrl,
          width: effectiveWidth,
          height: effectiveHeight,
          fit: fit,
          errorBuilder: (_, _, _) =>
              _buildFallback(effectiveWidth, effectiveHeight),
        );
      } else if (targetUrl.length > 50 &&
          !targetUrl.contains('/') &&
          !targetUrl.contains(':')) {
        content = _buildBase64Image(targetUrl, effectiveWidth, effectiveHeight);
      } else {
        content = _buildFallback(effectiveWidth, effectiveHeight);
      }
    } else {
      content = _buildFallback(effectiveWidth, effectiveHeight);
    }

    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? AppDimensions.borderRadiusSm);

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.inputBackground,
        shape: shape,
        borderRadius: effectiveRadius,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle
            ? BorderRadius.circular(effectiveWidth / 2)
            : (effectiveRadius ?? BorderRadius.zero),
        child: content,
      ),
    );
  }

  Widget _buildBase64Image(String rawData, double w, double h) {
    try {
      final commaIdx = rawData.indexOf(',');
      final base64String = commaIdx != -1
          ? rawData.substring(commaIdx + 1)
          : rawData;
      final Uint8List bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(w, h),
      );
    } catch (_) {
      return _buildFallback(w, h);
    }
  }

  Widget _buildNetworkImage(String url, double w, double h) {
    return CachedNetworkImage(
      imageUrl: url,
      width: w,
      height: h,
      fit: fit,
      placeholder: (context, url) => Container(
        width: w,
        height: h,
        color: AppColors.inputBackground,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(w, h),
    );
  }

  Widget _buildFallback(double w, double h) {
    final cleanName = name?.trim() ?? '';
    final minDim = min(w, h);

    if (cleanName.isNotEmpty) {
      final initial = cleanName[0].toUpperCase();
      return Container(
        width: w,
        height: h,
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Text(
          initial,
          style:
              textStyle ??
              AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontSize: minDim * 0.42,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      color: backgroundColor ?? AppColors.inputBackground,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: fallbackIconColor ?? AppColors.textSecondary,
        size: fallbackIconSize ?? (minDim * 0.5),
      ),
    );
  }
}
