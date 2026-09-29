import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/seed_data_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/distance_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/status_badge.dart';

class HomeTab extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;
  const HomeTab({super.key, required this.onNavigateTab});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Fade', 'Undercut', 'Modern Quiff', 'Side Part', 'Buzz Cut', 'Layer'];

  @override
  Widget build(BuildContext context) {
    final hairstyles = SeedDataService.sampleHairstyles;
    final barbers = SeedDataService.sampleBarbers;

    final filteredHairstyles = _selectedCategory == 'Tất cả'
        ? hairstyles
        : hairstyles.where((h) => h.tags.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()))).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderWelcome(),
          _buildAIBanner(context),
          const SizedBox(height: AppDimensions.lg),
          _buildQuickActionGrid(),
          const SizedBox(height: AppDimensions.xl),
          _buildCategorySelector(),
          const SizedBox(height: AppDimensions.lg),
          _buildHairstyleSection(filteredHairstyles),
          const SizedBox(height: AppDimensions.xl),
          _buildFeaturedBarbersSection(barbers),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, Khách hàng! 👋',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tìm kiểu tóc & Thợ đỉnh',
                style: AppTextStyles.h2,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.borderRadiusMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không có thông báo mới')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context) {
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
                      'AI TƯ VẤN THÔNG MINH',
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
            'Phân tích khuôn mặt & Gợi ý kiểu tóc chuẩn xác',
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
            'Sử dụng công nghệ AI On-Device nhận diện khung xương mặt và tỉ lệ vàng để chọn kiểu tóc hoàn hảo.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              AppButton(
                text: 'Thử AI Camera',
                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                width: 155,
                height: 40,
                onPressed: () => context.push('/spike-test'),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
                    ),
                    onPressed: () => widget.onNavigateTab(3), // Chuyển sang Tab AI Chat
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Hỏi AI Chat', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'Bản Đồ Thợ',
              subtitle: 'Đà Nẵng (5 tiệm)',
              icon: Icons.map_outlined,
              iconColor: AppColors.accent,
              onTap: () => widget.onNavigateTab(1),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: _ActionCard(
              title: 'Tìm Kiếm',
              subtitle: 'Kiểu tóc & Barber',
              icon: Icons.search_rounded,
              iconColor: AppColors.tertiary,
              onTap: () => widget.onNavigateTab(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: AppTextStyles.fontFamily,
            ),
            backgroundColor: AppColors.surface,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildHairstyleSection(List hairstyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kiểu Tóc Thịnh Hành', style: AppTextStyles.h3),
              Text(
                '${hairstyles.length} kiểu',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 205,
          child: hairstyles.isEmpty
              ? const Center(child: Text('Không tìm thấy kiểu tóc phù hợp', style: AppTextStyles.bodyMedium))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: hairstyles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
                  itemBuilder: (context, index) {
                    final item = hairstyles[index];
                    return Container(
                      width: 150,
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
                              height: 110,
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 110,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBarbersSection(List barbers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Barber Shop & Thợ Nổi Bật', style: AppTextStyles.h3),
              TextButton(
                onPressed: () => widget.onNavigateTab(1),
                child: Text('Xem bản đồ', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: barbers.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.md),
            itemBuilder: (context, index) {
              final barber = barbers[index];
              // Giả lập khoảng cách từ vị trí hiện tại (Đà Nẵng center)
              final distanceKm = 1.2 + (index * 0.8);

              return Container(
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
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 76,
                          height: 76,
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${barber.address} (${DistanceHelper.formatDistance(distanceKm)})',
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
