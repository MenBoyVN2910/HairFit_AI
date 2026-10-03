// ============================================================================
// File: lib/features/profile/presentation/profile_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng profile.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Màn hình thông tin cá nhân và cài đặt tài khoản (Task 6.4)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _handlePasswordReset(String email) async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        title: const Text('Đặt lại mật khẩu?', style: AppTextStyles.h4),
        content: Text(
          'Hệ thống sẽ gửi một email chứa liên kết đặt lại mật khẩu đến địa chỉ:\n\n$email',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );

    if (shouldSend != true || !mounted) return;

    try {
      await ref.read(authStateProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Liên kết đặt lại mật khẩu đã được gửi đến email của bạn!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        title: const Text('Đăng xuất?', style: AppTextStyles.h4),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản HairFit AI?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    final currentUser = userAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ Của Tôi', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(authStateProvider.notifier).refreshUser(),
          ),
        ],
      ),
      bottomNavigationBar: currentUser == null ? null : _buildBottomNav(context, currentUser),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin',
            message: err.toString(),
            actionText: 'Thử lại',
            onAction: () => ref.read(authStateProvider.notifier).refreshUser(),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Chưa đăng nhập',
                message: 'Vui lòng đăng nhập để xem thông tin hồ sơ cá nhân.',
                actionText: 'Đăng nhập',
                onAction: () => context.go('/login'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                _buildUserHeader(user),
                const SizedBox(height: AppDimensions.xl),
                _buildActionGroup(
                  title: 'Quản lý tài khoản',
                  items: [
                    _ActionItem(
                      icon: Icons.edit_outlined,
                      title: 'Chỉnh sửa thông tin',
                      subtitle: 'Tên hiển thị, ảnh đại diện',
                      onTap: () => context.push(
                        user.isBarber
                            ? '/barber/profile-edit-user'
                            : '/customer/profile-edit',
                      ),
                    ),
                    _ActionItem(
                      icon: Icons.lock_reset_rounded,
                      title: 'Đổi mật khẩu',
                      subtitle: 'Gửi email đặt lại mật khẩu bảo mật',
                      onTap: () => _handlePasswordReset(user.email),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildActionGroup(
                  title: 'Dịch vụ & Tính năng',
                  items: [
                    if (user.isCustomer) ...[
                      _ActionItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Lịch hẹn của tôi',
                        subtitle: 'Xem lịch sắp tới và lịch sử cắt tóc',
                        onTap: () => context.push('/customer/appointments'),
                      ),
                      _ActionItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Tin nhắn & Trò chuyện',
                        subtitle: 'Trao đổi trực tiếp với thợ cắt tóc',
                        onTap: () => context.push('/conversations'),
                      ),
                      _ActionItem(
                        icon: Icons.face_retouching_natural_rounded,
                        title: 'Tư vấn kiểu tóc AI',
                        subtitle: 'Phân tích dáng mặt 100% On-Device',
                        onTap: () {
                          try {
                            context.push('/customer/ai-consult');
                          } catch (_) {
                            context.go('/customer/ai-consult');
                          }
                        },
                      ),
                      _ActionItem(
                        icon: Icons.map_outlined,
                        title: 'Khám Phá Tiệm Xung Quanh',
                        subtitle: 'Tìm thợ cắt tóc trên bản đồ',
                        onTap: () => context.push('/customer/search'),
                      ),
                    ],
                    if (user.isBarber) ...[
                      _ActionItem(
                        icon: Icons.content_cut_rounded,
                        title: 'Quản lý lịch hẹn',
                        subtitle: 'Xem và phê duyệt các cuộc hẹn',
                        onTap: () => context.push('/barber/appointments'),
                      ),
                      _ActionItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Tin nhắn & Trò chuyện',
                        subtitle: 'Trao đổi với khách hàng',
                        onTap: () => context.push('/conversations'),
                      ),
                      _ActionItem(
                        icon: Icons.storefront_outlined,
                        title: 'Quản lý hồ sơ tiệm tóc',
                        subtitle: 'Cập nhật dịch vụ, giá tiền, giờ làm việc',
                        onTap: () => context.push('/barber/profile-edit'),
                      ),
                      _ActionItem(
                        icon: Icons.visibility_outlined,
                        title: 'Xem trang tiệm công khai',
                        subtitle: 'Xem giao diện tiệm như khách hàng nhìn thấy',
                        onTap: () => context.push('/customer/barber/${user.uid}'),
                      ),
                    ],
                    if (user.isAdmin) ...[
                      _ActionItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Phê duyệt thợ cắt tóc',
                        subtitle: 'Xét duyệt hồ sơ salon đăng ký mới',
                        onTap: () => context.push('/admin/approve-barbers'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildActionGroup(
                  title: 'Hệ thống HairFit AI',
                  items: [
                    _ActionItem(
                      icon: Icons.science_outlined,
                      title: 'Kiểm thử AI & Dữ liệu mẫu',
                      subtitle: 'Công cụ test On-Device AI và nạp dữ liệu mẫu',
                      onTap: () => context.push('/spike-test'),
                    ),
                    _ActionItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản 0.6 beta — Cre by: MenBoyBMN',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'HairFit AI',
                          applicationVersion: '0.6 beta',
                          applicationLegalese: 'Cre by: MenBoyBMN',
                          applicationIcon: Container(
                            padding: const EdgeInsets.all(AppDimensions.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppDimensions.borderRadiusSm,
                            ),
                            child: const Icon(
                              Icons.content_cut_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          children: const [
                            SizedBox(height: AppDimensions.sm),
                            Text(
                              'Cre by: MenBoyBMN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                            SizedBox(height: AppDimensions.xs),
                            Text(
                              'Ứng dụng tư vấn kiểu tóc bằng AI nhân trắc học 100% On-Device, bản đồ tìm thợ OpenStreetMap và hệ thống đặt lịch chống trùng slot nguyên tử.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                AppButton(
                  text: 'Đăng Xuất',
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  variant: AppButtonVariant.outline,
                  onPressed: _handleLogout,
                ),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String avatarUrl) {
    final url = avatarUrl.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Widget _buildUserHeader(UserModel user) {
    final avatarProvider = _getAvatarProvider(user.avatarUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            user.displayName.isNotEmpty ? user.displayName : 'Người dùng',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            user.email,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          _buildRoleBadge(user.role),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final String label;
    final Color bgColor;
    final Color textColor;

    switch (role) {
      case UserRole.admin:
        label = 'Quản trị viên (Admin)';
        bgColor = AppColors.accent.withValues(alpha: 0.1);
        textColor = AppColors.accent;
        break;
      case UserRole.barber:
        label = 'Thợ cắt tóc (Barber)';
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        break;
      case UserRole.customer:
        label = 'Khách hàng (Customer)';
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionGroup({
    required String title,
    required List<_ActionItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.xs,
            bottom: AppDimensions.sm,
          ),
          child: Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppDimensions.borderRadiusSm,
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 20),
                ),
                title: Text(item.title, style: AppTextStyles.bodyLarge),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: item.onTap,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomNav(BuildContext context, UserModel user) {
    if (user.isBarber) {
      return BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          if (index == 0) {
            context.go('/barber/appointments');
          } else if (index == 1) {
            context.push('/barber/profile-edit');
          } else if (index == 2) {
            context.push('/conversations');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Cửa tiệm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat_rounded),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      );
    }

    if (user.isCustomer) {
      return BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          if (index == 0) {
            context.go('/customer/home');
          } else if (index == 1) {
            context.push('/customer/search');
          } else if (index == 2) {
            context.push('/customer/appointments');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      );
    }

    return null;
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
