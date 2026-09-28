import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Các widget hiển thị hiệu ứng skeleton loading mượt mà
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const LoadingShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle 
              ? null 
              : (borderRadius ?? AppDimensions.borderRadiusSm),
        ),
      ),
    );
  }

  /// Shimmer hiển thị card thợ hoặc kiểu tóc
  static Widget card({double height = 180}) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDimensions.borderRadiusMd,
        ),
      ),
    );
  }

  /// Shimmer hiển thị danh sách dòng
  static Widget listTile() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppDimensions.borderRadiusXs,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Container(
                    width: 140,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppDimensions.borderRadiusXs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
