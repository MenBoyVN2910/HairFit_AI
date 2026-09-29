import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seed_data_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../search_map/data/barber_repository.dart';

/// Màn hình chính dành cho khách hàng (Customer Home)
class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: const Icon(
                Icons.content_cut_rounded,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            const Text('HairFit AI', style: AppTextStyles.h3),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch hẹn của tôi',
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.accent),
            onPressed: () => context.push('/customer/appointments'),
          ),
          IconButton(
            tooltip: 'Spike AI & Kiểm thử',
            icon: const Icon(Icons.science_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/spike-test'),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIBanner(),
            const SizedBox(height: AppDimensions.lg),
            _buildQuickActions(),
            const SizedBox(height: AppDimensions.xl),
            _buildHairstyleSection(),
            const SizedBox(height: AppDimensions.xl),
            _buildFeaturedBarbersSection(),
            const SizedBox(height: AppDimensions.xxxl),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 1) {
            context.push('/customer/search');
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildAIBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: AppColors.aiBannerGradient,
        borderRadius: AppDimensions.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.9),
                  borderRadius: AppDimensions.borderRadiusFull,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI TƯ VẤN KIỂU TÓC',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const Text(
            'Khuôn mặt bạn hợp kiểu tóc nào nhất?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Chỉ cần 1 bức ảnh chân dung, AI sẽ nhận diện dáng mặt và gợi ý kiểu tóc chuẩn xác nhất.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            text: 'Thử Ngay Với AI',
            icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
            width: 220,
            height: 42,
            onPressed: () => context.push('/spike-test'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'Spike AI Test',
              subtitle: 'On-Device AI',
              icon: Icons.science_outlined,
              iconColor: AppColors.accent,
              onTap: () => context.push('/spike-test'),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: _ActionCard(
              title: 'Tìm Thợ Quanh Đây',
              subtitle: 'Đà Nẵng & GPS',
              icon: Icons.place_outlined,
              iconColor: AppColors.tertiary,
              onTap: () => context.push('/customer/search'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHairstyleSection() {
    final hairstyles = SeedDataService.sampleHairstyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kiểu Tóc Phổ Biến', style: AppTextStyles.h3),
              Text(
                '${hairstyles.length} kiểu',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            scrollDirection: Axis.horizontal,
            itemCount: hairstyles.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, index) {
              final item = hairstyles[index];
              return InkWell(
                borderRadius: AppDimensions.borderRadiusMd,
                onTap: () => context.push('/customer/search?hairstyleId=${item.id}'),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusMd,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusMd),
                        ),
                        child: Image.network(
                          item.imageUrl,
                          height: 100,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100,
                            color: AppColors.inputBackground,
                            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.tags.take(2).join(', '),
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBarbersSection() {
    final barbersAsync = ref.watch(approvedBarbersProvider);
    final barbers = (barbersAsync.value != null && barbersAsync.value!.isNotEmpty)
        ? barbersAsync.value!
        : SeedDataService.sampleBarbers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thợ Cắt Tóc Nổi Bật', style: AppTextStyles.h3),
              InkWell(
                onTap: () => context.push('/customer/search'),
                child: Text(
                  'Xem tất cả',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: barbers.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.md),
            itemBuilder: (context, index) {
              final barber = barbers[index];
              return InkWell(
                borderRadius: AppDimensions.borderRadiusMd,
                onTap: () => context.push('/customer/barber/${barber.uid}'),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusMd,
                    border: Border.all(color: AppColors.divider),
                  ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppDimensions.borderRadiusSm,
                      child: Image.network(
                        barber.avatarUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.inputBackground,
                          child: const Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  barber.displayName,
                                  style: AppTextStyles.h4,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const StatusBadge.approval(status: 'approved'),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.xxs),
                          Text(
                            barber.address,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Row(
                            children: [
                              RatingStars(rating: barber.ratingAvg, reviewCount: barber.ratingCount),
                              const Spacer(),
                              Text(
                                DateFormatter.formatPriceRange(barber.priceMin, barber.priceMax),
                                style: AppTextStyles.badgeText.copyWith(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadiusMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
