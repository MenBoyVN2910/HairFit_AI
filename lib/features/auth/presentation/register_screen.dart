// ============================================================================
// File: lib/features/auth/presentation/register_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng auth.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Màn hình đăng ký tài khoản (UC-01)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            role: _selectedRole,
          );
      if (!mounted) return;
      // context.go('/customer/home'); // GoRouter sẽ tự động redirect
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppDimensions.paddingScreen,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tạo Tài Khoản Mới', style: AppTextStyles.h1),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Đăng ký để khám phá các kiểu tóc phù hợp nhất với bạn',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: AppDimensions.borderRadiusMd,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                  ],

                  // Chọn vai trò: Khách hàng hoặc Thợ cắt tóc
                  const Text(
                    'Bạn tham gia với vai trò:',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Khách hàng',
                          subtitle: 'Tìm thợ & Đặt lịch',
                          icon: Icons.person_outline_rounded,
                          isSelected: _selectedRole == UserRole.customer,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.customer),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: _RoleCard(
                          title: 'Thợ cắt tóc',
                          subtitle: 'Quản lý tiệm & Nhận lịch',
                          icon: Icons.content_cut_rounded,
                          isSelected: _selectedRole == UserRole.barber,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.barber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  AppTextField(
                    label: 'Họ và tên',
                    hintText: 'Nhập họ tên đầy đủ',
                    controller: _nameController,
                    validator: (v) => Validators.required(v, 'họ và tên'),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  AppTextField(
                    label: 'Email',
                    hintText: 'Nhập địa chỉ email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  AppTextField(
                    label: 'Mật khẩu',
                    hintText: 'Tối thiểu 6 ký tự',
                    controller: _passwordController,
                    isPassword: true,
                    validator: Validators.password,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  AppTextField(
                    label: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu trên',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    validator: (v) =>
                        Validators.confirmPassword(v, _passwordController.text),
                    prefixIcon: const Icon(
                      Icons.lock_reset_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  AppButton(
                    text: 'Tạo tài khoản',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Đăng nhập ngay',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
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
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: AppDimensions.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.xxs),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
