// ============================================================================
// File: lib/features/search_map/presentation/widgets/barber_list_view.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng search_map.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../providers/search_provider.dart';
import 'barber_card.dart';

/// Widget danh sách thợ cắt tóc với sắp xếp khoảng cách và filter kiểu tóc (Task 3.7)
class BarberListView extends StatelessWidget {
  final SearchMapState searchState;
  final Future<void> Function() onRefresh;
  final VoidCallback? onClearFilter;

  const BarberListView({
    super.key,
    required this.searchState,
    required this.onRefresh,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final barbers = searchState.displayBarbers;

    if (barbers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Không tìm thấy thợ phù hợp',
            message: searchState.searchQuery.isNotEmpty
                ? 'Không có tiệm cắt tóc nào khớp với từ khoá "${searchState.searchQuery}". Vui lòng thử từ khoá khác.'
                : 'Hiện tại chưa có thợ cắt tóc nào hoạt động tại khu vực này.',
            actionText: 'Xoá bộ lọc & Thử lại',
            onAction: onClearFilter ?? () {},
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppDimensions.sm,
          bottom: AppDimensions.xxxl,
        ),
        itemCount: barbers.length + 1, // +1 cho header thông tin
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context);
          }

          final item = barbers[index - 1];
          return BarberCard(
            item: item,
            onTap: () {
              context.push('/customer/barber/${item.barber.uid}');
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông báo nếu kiểu tóc chọn không có thợ nào hỗ trợ
          if (searchState.hasNoMatchingForHairstyle) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppDimensions.borderRadiusSm,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  const Expanded(
                    child: Text(
                      'Chưa có thợ nào đăng ký kiểu tóc này gần bạn. Đang hiển thị tất cả các thợ uy tín gần nhất.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tìm thấy ${searchState.displayBarbers.length} tiệm cắt tóc',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (searchState.matchingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${searchState.matchingCount} thợ phù hợp',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
        ],
      ),
    );
  }
}
