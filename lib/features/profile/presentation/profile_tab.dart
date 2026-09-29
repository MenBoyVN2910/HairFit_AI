import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/app_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModelAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tài Khoản & Cài Đặt', style: AppTextStyles.h2),
              const SizedBox(height: AppDimensions.lg),

              // User Info Card
              userModelAsync.when(
                data: (user) => Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusLg,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'H',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Khách hàng HairFit',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'khachhang@hairfit.ai',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppDimensions.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: AppDimensions.borderRadiusFull,
                              ),
                              child: const Text(
                                '🌟 Thành viên VIP • On-Device AI',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusLg,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 30, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: AppDimensions.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Khách hàng HairFit AI', style: AppTextStyles.h3),
                          Text('user@hairfit.ai', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.xl),
              const Text('Quản Lý & Tiện Ích', style: AppTextStyles.h4),
              const SizedBox(height: AppDimensions.sm),

              // Menu Items
              _MenuItem(
                icon: Icons.calendar_month_outlined,
                title: 'Lịch Sử Đặt Lịch Cắt Tóc',
                subtitle: 'Xem các lịch hẹn đã đặt với Barber',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng Lịch sử đặt lịch đang cập nhật')));
                },
              ),
              const SizedBox(height: AppDimensions.sm),
              _MenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Kiểu Tóc & Barber Yêu Thích',
                subtitle: 'Danh sách các kiểu tóc đã lưu',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng Yêu thích đang cập nhật')));
                },
              ),
              const SizedBox(height: AppDimensions.sm),
              _MenuItem(
                icon: Icons.science_outlined,
                title: 'Kiểm Thử Spike AI & Camera',
                subtitle: 'Trải nghiệm AI quét khuôn mặt ML Kit',
                onTap: () => context.push('/spike-test'),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Cài Đặt Ứng Dụng',
                subtitle: 'Thông báo, ngôn ngữ, quyền riêng tư',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cài đặt ứng dụng HairFit AI v1.0.0')));
                },
              ),
              const SizedBox(height: AppDimensions.sm),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Trung Tâm Trợ Giúp & Hướng Dẫn',
                subtitle: 'Câu hỏi thường gặp và tài liệu hướng dẫn',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ứng dụng chạy 100% On-Device AI')));
                },
              ),

              const SizedBox(height: AppDimensions.xl),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(firebaseAuthProvider).signOut();
                    } catch (_) {}
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng Xuất Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
