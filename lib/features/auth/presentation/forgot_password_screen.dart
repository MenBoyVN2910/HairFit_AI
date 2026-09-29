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

/// Màn hình quên mật khẩu (UC-01)
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).sendPasswordReset(_emailController.text.trim());
      setState(() {
        _isSent = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
        child: SingleChildScrollView(
          padding: AppDimensions.paddingScreen,
          child: _isSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.lg),
          const Text('Quên Mật Khẩu?', style: AppTextStyles.h1),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Nhập địa chỉ email tài khoản của bạn để nhận liên kết đặt lại mật khẩu an toàn.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.xxl),

          AppTextField(
            label: 'Email',
            hintText: 'Nhập địa chỉ email đã đăng ký',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.xl),

          AppButton(
            text: 'Gửi liên kết đặt lại',
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.success),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        const Text(
          'Kiểm Tra Email Của Bạn',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Chúng tôi đã gửi liên kết đặt lại mật khẩu đến:',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          _emailController.text,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xl),

        // Hướng dẫn từng bước
        Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hướng dẫn đặt lại mật khẩu:',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppDimensions.md),
              _buildStep('1', 'Mở ứng dụng Gmail hoặc hộp thư email của bạn.'),
              const SizedBox(height: AppDimensions.sm),
              _buildStep('2', 'Tìm email từ "noreply@..." với tiêu đề đặt lại mật khẩu.'),
              const SizedBox(height: AppDimensions.sm),
              _buildStep('3', 'Nhấn vào liên kết trong email để mở trang đặt lại mật khẩu.'),
              const SizedBox(height: AppDimensions.sm),
              _buildStep('4', 'Nhập mật khẩu mới trên trình duyệt và xác nhận.'),
              const SizedBox(height: AppDimensions.sm),
              _buildStep('5', 'Quay lại HairFit AI và đăng nhập với mật khẩu mới!'),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),

        // Lưu ý
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Nếu không thấy email, hãy kiểm tra mục Spam/Thư rác. Liên kết có hiệu lực trong vòng 1 giờ.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xl),

        AppButton(
          text: 'Quay lại đăng nhập',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppDimensions.md),

        // Gửi lại email
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                await ref.read(authStateProvider.notifier).sendPasswordReset(_emailController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi lại email đặt lại mật khẩu!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(
              'Không nhận được email? Gửi lại',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ),
      ],
    );
  }
}
