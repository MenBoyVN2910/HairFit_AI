import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/distance_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../ai_consult/data/hairstyle_repository.dart';
import '../../../../models/barber_profile_model.dart';
import '../../../../providers/search_provider.dart';
import '../data/barber_repository.dart';

/// Màn hình Chi tiết thợ cắt tóc (Task 3.10)
class BarberDetailScreen extends ConsumerStatefulWidget {
  final String barberId;

  const BarberDetailScreen({
    super.key,
    required this.barberId,
  });

  @override
  ConsumerState<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends ConsumerState<BarberDetailScreen> {
  bool _isWorkingHoursExpanded = false;

  @override
  Widget build(BuildContext context) {
    final barberAsync = ref.watch(barberDetailProvider(widget.barberId));
    final searchState = ref.watch(searchNotifierProvider).value;

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
                  message: 'Hồ sơ thợ này không tồn tại hoặc đã ngừng hoạt động.',
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
                      const SizedBox(height: AppDimensions.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: barberAsync.value != null
          ? _buildStickyBottomBar(barberAsync.value!)
          : null,
    );
  }

  /// Sliver AppBar với ảnh đại diện / cover
  Widget _buildSliverAppBar(BarberProfileModel barber) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            barber.avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: barber.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.secondary,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.secondary,
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
            // Gradient tối để chữ rõ ràng
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

  /// Card thông tin cơ bản: Tên, Rating, Khoảng cách, Địa chỉ, Bio
  Widget _buildHeaderCard(BarberProfileModel barber, String? distanceFormatted) {
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
              Expanded(
                child: Text(
                  barber.displayName,
                  style: AppTextStyles.h2,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_outlined,
                          size: 13, color: AppColors.primary),
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
                child: Text(
                  barber.address,
                  style: AppTextStyles.bodyMedium,
                ),
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
                  const Icon(Icons.schedule_rounded,
                      size: 20, color: AppColors.primary),
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
                  const Icon(Icons.content_cut_rounded,
                      size: 20, color: AppColors.primary),
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
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

  /// Thanh đặt lịch dính ở dưới đáy màn hình
  Widget _buildStickyBottomBar(BarberProfileModel barber) {
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
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: AppButton(
                text: 'Đặt Lịch Hẹn',
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                onPressed: () {
                  // Điều hướng sang luồng booking (hoặc thông báo sang Tuần 4)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã chọn thợ "${barber.displayName}". Tính năng chọn khung giờ sẽ sẵn sàng trong Tuần 4!',
                      ),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
