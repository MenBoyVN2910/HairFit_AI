// ============================================================================
// File: lib/features/auth/presentation/login_screen.dart
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
import '../../../providers/auth_provider.dart';

/// Màn hình đăng nhập tài khoản HairFit AI (UC-01)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      // context.go('/customer/home'); // GoRouter sẽ tự động redirect khi đăng nhập thành công
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppDimensions.borderRadiusLg,
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Text(
                    'Chào Mừng Trở Lại',
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Đăng nhập để đặt lịch và trải nghiệm tư vấn kiểu tóc AI',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.xxl),

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

                  AppTextField(
                    label: 'Email',
                    hintText: 'Nhập địa chỉ email của bạn',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  AppTextField(
                    label: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                    controller: _passwordController,
                    isPassword: true,
                    validator: Validators.password,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  AppButton(
                    text: 'Đăng nhập',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          'Đăng ký ngay',
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
