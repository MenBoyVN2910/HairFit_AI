// ============================================================================
// File: lib/features/profile/presentation/edit_profile_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng profile.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../barber_profile/data/barber_profile_repository.dart';
import '../../search_map/data/barber_repository.dart';

/// Màn hình chỉnh sửa thông tin người dùng với chức năng upload ảnh từ máy (Task 6.4 & User Request Task 9)
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  String? _currentAvatarUrl;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _currentAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ImageProvider? _getAvatarProvider() {
    if (_pickedImageBytes != null) {
      return MemoryImage(_pickedImageBytes!);
    }
    final url = _currentAvatarUrl?.trim() ?? '';
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _pickedImageBytes = bytes;
          _currentAvatarUrl = base64String;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              const Text('Chọn ảnh đại diện', style: AppTextStyles.h4),
              const SizedBox(height: AppDimensions.sm),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text(
                  'Chọn ảnh từ thư viện máy',
                  style: AppTextStyles.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text(
                  'Chụp ảnh mới',
                  style: AppTextStyles.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedImageBytes != null ||
                  (_currentAvatarUrl?.isNotEmpty ?? false))
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    'Xóa ảnh đại diện',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pickedImageBytes = null;
                      _currentAvatarUrl = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text.trim();
      final newAvatar = _currentAvatarUrl ?? '';

      await ref
          .read(authStateProvider.notifier)
          .updateProfile(displayName: newName, avatarUrl: newAvatar);

      final currentUser = ref.read(authStateProvider).value;
      if (currentUser != null) {
        ref.invalidate(barberProfileProvider(currentUser.uid));
      }
      ref.invalidate(approvedBarbersStreamProvider);
      ref.invalidate(approvedBarbersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _getAvatarProvider();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Hồ Sơ', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.md),

              // Avatar & Nút upload ảnh từ máy
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceModal,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.surface,
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? const Icon(
                                  Icons.person,
                                  size: 54,
                                  color: AppColors.textSecondary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceModal,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.xs + 2),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              TextButton.icon(
                onPressed: _showImageSourceModal,
                icon: const Icon(
                  Icons.upload_file_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                label: const Text(
                  'Tải ảnh từ máy',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Tên hiển thị
              AppTextField(
                controller: _nameController,
                label: 'Tên hiển thị',
                hintText: 'Nhập họ và tên hoặc nghệ danh',
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên hiển thị';
                  }
                  if (val.trim().length < 2) {
                    return 'Tên hiển thị phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.xxl),

              // Nút Lưu
              AppButton(
                text: 'Lưu Thay Đổi',
                icon: const Icon(Icons.save_outlined, size: 18),
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: AppDimensions.md),
              AppButton(
                text: 'Hủy Bỏ',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
