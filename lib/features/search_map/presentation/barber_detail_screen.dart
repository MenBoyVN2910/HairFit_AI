// ============================================================================
// File: lib/features/search_map/presentation/barber_detail_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng search_map.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/distance_helper.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../ai_consult/data/hairstyle_repository.dart';
import '../../../../models/barber_profile_model.dart';
import '../../../../models/chat_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/search_provider.dart';
import '../data/barber_repository.dart';

/// Màn hình Chi tiết thợ cắt tóc (Task 3.10)
class BarberDetailScreen extends ConsumerStatefulWidget {
  final String barberId;

  const BarberDetailScreen({super.key, required this.barberId});

  @override
  ConsumerState<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends ConsumerState<BarberDetailScreen> {
  bool _isWorkingHoursExpanded = false;

  @override
  Widget build(BuildContext context) {
    final barberAsync = ref.watch(barberDetailProvider(widget.barberId));
    final searchState = ref.watch(searchNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: barberAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Chi tiết thợ')),
          body: Center(
            child: ErrorRetry(
              errorMessage: 'Không thể tải thông tin thợ: $error',
              onRetry: () => ref.refresh(barberDetailProvider(widget.barberId)),
            ),
          ),
        ),
        data: (barber) {
          if (barber == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết thợ')),
              body: Center(
                child: EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Không tìm thấy thợ',
                  message:
                      'Hồ sơ thợ này không tồn tại hoặc đã ngừng hoạt động.',
                  actionText: 'Quay lại',
                  onAction: () => context.pop(),
                ),
              ),
            );
          }

          // Tính khoảng cách từ vị trí người dùng (nếu có)
          String? distanceFormatted;
          if (searchState != null) {
            final d = DistanceHelper.calculateDistanceMeters(
              lat1: searchState.referenceLocation.latitude,
              lon1: searchState.referenceLocation.longitude,
              lat2: barber.location.latitude,
              lon2: barber.location.longitude,
            );
            distanceFormatted = DistanceHelper.formatDistance(d);
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(barber),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card: Tên, Đánh giá, Khoảng cách, Địa chỉ
                          _buildHeaderCard(barber, distanceFormatted),
                          const SizedBox(height: AppDimensions.md),

                          // Giờ làm việc & trạng thái hôm nay
                          _buildWorkingHoursCard(barber),
                          const SizedBox(height: AppDimensions.md),

                          // Bảng giá dịch vụ
                          _buildServicesCard(barber),
                          const SizedBox(height: AppDimensions.md),

                          // Kiểu tóc tiệm hỗ trợ
                          _buildSupportedHairstylesCard(barber),
                          const SizedBox(height: AppDimensions.md),

                          // Đánh giá từ khách hàng
                          _buildReviewsCard(barber),
                          const SizedBox(height: AppDimensions.xxxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: barberAsync.valueOrNull != null
          ? _buildStickyBottomBar(barberAsync.valueOrNull!)
          : null,
    );
  }

  /// Sliver AppBar với ảnh bìa tiệm (cover) hoặc avatar
  Widget _buildSliverAppBar(BarberProfileModel barber) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          tooltip: 'Nhắn tin với thợ',
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
          ),
          onPressed: () => _openChat(barber),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildCoverImageWidget(barber),
            // Gradient tối để chữ và các nút rõ ràng
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị ảnh bìa tiệm tóc (ưu tiên coverUrl, fallback avatarUrl, fallback placeholder)
  Widget _buildCoverImageWidget(BarberProfileModel barber) {
    final imageTarget = barber.coverUrl.trim().isNotEmpty
        ? barber.coverUrl.trim()
        : barber.avatarUrl.trim();

    if (imageTarget.isEmpty) {
      return Container(
        color: AppColors.secondary,
        child: const Icon(
          Icons.storefront_rounded,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    if (imageTarget.startsWith('data:image')) {
      try {
        final commaIdx = imageTarget.indexOf(',');
        final base64Str = commaIdx != -1
            ? imageTarget.substring(commaIdx + 1)
            : imageTarget;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.secondary,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        );
      } catch (_) {
        return Container(
          color: AppColors.secondary,
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white54,
            size: 64,
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: imageTarget,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.secondary),
      errorWidget: (_, _, _) => Container(
        color: AppColors.secondary,
        child: const Icon(
          Icons.storefront_rounded,
          color: Colors.white54,
          size: 64,
        ),
      ),
    );
  }

  /// Card thông tin cơ bản: Tên, Rating, Khoảng cách, Địa chỉ, Bio
  Widget _buildHeaderCard(
    BarberProfileModel barber,
    String? distanceFormatted,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                shape: BoxShape.circle,
                size: 56,
                imageUrl: barber.avatarUrl,
                fallbackUrl: barber.coverUrl,
                name: barber.displayName,
                fallbackIcon: Icons.storefront_rounded,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(barber.displayName, style: AppTextStyles.h2),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),

          // Rating và khoảng cách
          Row(
            children: [
              RatingStars(
                rating: barber.ratingAvg,
                starSize: 16,
                showRatingNumber: false,
              ),
              const SizedBox(width: 6),
              Text(
                barber.ratingAvg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' (${barber.ratingCount} đánh giá)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (distanceFormatted != null) ...[
                const SizedBox(width: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppDimensions.xs),

          // Địa chỉ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(barber.address, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),

          // Bio giới thiệu nếu có
          if (barber.bio.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              barber.bio,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Card giờ làm việc (Hiển thị hôm nay + nút mở rộng xem cả tuần)
  Widget _buildWorkingHoursCard(BarberProfileModel barber) {
    final now = DateTime.now();
    // Chuyển thứ trong tuần thành key: mon, tue, wed, thu, fri, sat, sun
    final weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final currentDayKey = weekdayKeys[now.weekday - 1];
    final todayHours = barber.workingHours[currentDayKey];

    final isTodayClosed = todayHours == null || todayHours.closed;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Giờ hoạt động', style: AppTextStyles.h4),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isWorkingHoursExpanded = !_isWorkingHoursExpanded;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      _isWorkingHoursExpanded ? 'Thu gọn' : 'Xem cả tuần',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isWorkingHoursExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Trạng thái hôm nay
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTodayClosed ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isTodayClosed
                    ? 'Hôm nay: Nghỉ'
                    : 'Hôm nay: Mở cửa (${todayHours.open} - ${todayHours.close})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isTodayClosed ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),

          // Lịch chi tiết 7 ngày nếu mở rộng
          if (_isWorkingHoursExpanded) ...[
            const SizedBox(height: AppDimensions.sm),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.xs),
            ..._buildFullWeekSchedule(barber.workingHours, currentDayKey),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFullWeekSchedule(
    Map<String, DayWorkingHours> hoursMap,
    String currentDayKey,
  ) {
    final dayNames = {
      'mon': 'Thứ Hai',
      'tue': 'Thứ Ba',
      'wed': 'Thứ Tư',
      'thu': 'Thứ Năm',
      'fri': 'Thứ Sáu',
      'sat': 'Thứ Bảy',
      'sun': 'Chủ Nhật',
    };

    return dayNames.entries.map((entry) {
      final key = entry.key;
      final name = entry.value;
      final hours = hoursMap[key];
      final isCurrent = key == currentDayKey;

      String statusText = 'Nghỉ';
      if (hours != null && !hours.closed) {
        statusText = '${hours.open} - ${hours.close}';
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name + (isCurrent ? ' (Hôm nay)' : ''),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: statusText == 'Nghỉ'
                    ? AppColors.textSecondary
                    : (isCurrent ? AppColors.accent : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Card danh sách dịch vụ kèm giá và thời lượng
  Widget _buildServicesCard(BarberProfileModel barber) {
    final services = barber.services.where((s) => s.active).toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.content_cut_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Bảng giá dịch vụ', style: AppTextStyles.h4),
                ],
              ),
              Text(
                '${services.length} dịch vụ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(color: AppColors.divider),

          if (services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Text(
                'Tiệm chưa cập nhật danh sách dịch vụ.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.divider, height: 16),
              itemBuilder: (context, index) {
                final s = services[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${s.durationMinutes} phút',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.formatCurrency(s.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /// Card kiểu tóc tiệm hỗ trợ cắt
  Widget _buildSupportedHairstylesCard(BarberProfileModel barber) {
    final hairstylesAsync = ref.watch(hairstylesProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Kiểu tóc chuyên tạo mẫu', style: AppTextStyles.h4),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppDimensions.xs),

          hairstylesAsync.when(
            data: (allStyles) {
              final supported = allStyles
                  .where((h) => barber.hairstyleIds.contains(h.id))
                  .toList();

              if (supported.isEmpty) {
                return const Text(
                  'Tiệm hỗ trợ tất cả các kiểu tóc nam phổ biến.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: supported.map((style) {
                  return Chip(
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    avatar: const Icon(
                      Icons.content_cut,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      style.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Card hiển thị danh sách đánh giá từ khách hàng
  Widget _buildReviewsCard(BarberProfileModel barber) {
    final reviewsAsync = ref.watch(barberReviewsStreamProvider(barber.uid));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Đánh giá từ khách hàng', style: AppTextStyles.h4),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    barber.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' (${barber.ratingCount})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppDimensions.xs),
          reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa có nhận xét nào. Hãy đặt lịch và là người đầu tiên trải nghiệm để lại đánh giá!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 16, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final rev = reviews[index];
                  final customerName =
                      rev['customerName'] as String? ?? 'Khách hàng';
                  final rating = (rev['rating'] as num?)?.toInt() ?? 5;
                  final comment = rev['reviewComment'] as String? ?? '';
                  final createdAt = rev['createdAt'];
                  DateTime? reviewDate;
                  if (createdAt is Timestamp) {
                    reviewDate = createdAt.toDate();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  customerName.isNotEmpty
                                      ? customerName[0].toUpperCase()
                                      : 'K',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          RatingStars(
                            rating: rating.toDouble(),
                            starSize: 13,
                            showRatingNumber: false,
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          comment,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                      if (reviewDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatShortDate(reviewDate),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Text(
              'Không thể tải đánh giá: $err',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh đặt lịch dính ở dưới đáy màn hình
  Widget _buildStickyBottomBar(BarberProfileModel barber) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwnShop = currentUser != null && currentUser.uid == barber.uid;

    if (isOwnShop) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tiệm của bạn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: AppButton(
                      text: 'Chỉnh Sửa Hồ Sơ Tiệm',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () {
                        context.push('/barber/profile-edit');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mức giá dịch vụ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormatter.formatPriceRange(
                        barber.priceMin,
                        barber.priceMax,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDimensions.md),
                IconButton(
                  tooltip: 'Nhắn tin với thợ',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _openChat(barber),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: AppButton(
                    text: 'Đặt Lịch Hẹn',
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    onPressed: () {
                      context.push('/customer/booking/${barber.uid}');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(BarberProfileModel barber) {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để nhắn tin!')),
      );
      return;
    }
    if (currentUser.uid == barber.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là hồ sơ tiệm của chính bạn.')),
      );
      return;
    }
    final customerId = currentUser.uid;
    final customerName = currentUser.displayName.isNotEmpty
        ? currentUser.displayName
        : 'Khách hàng';
    final chatId = ChatConversation.buildChatId(customerId, barber.uid);
    context.push(
      '/chat/$chatId'
      '?otherUserId=${barber.uid}'
      '&otherUserName=${Uri.encodeComponent(barber.displayName)}'
      '&customerId=$customerId'
      '&customerName=${Uri.encodeComponent(customerName)}'
      '&barberId=${barber.uid}'
      '&barberName=${Uri.encodeComponent(barber.displayName)}',
    );
  }
}
