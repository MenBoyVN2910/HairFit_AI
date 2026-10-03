// ============================================================================
// File: lib/features/barber_profile/presentation/barber_registration_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng barber_profile.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';

import '../../../../models/barber_profile_model.dart';
import '../../../../models/service_model.dart';
import '../../../../providers/auth_provider.dart';
import '../data/barber_profile_repository.dart';
import 'widgets/hairstyle_picker.dart';
import 'widgets/location_picker.dart';
import 'widgets/service_editor.dart';
import 'widgets/working_hours_editor.dart';

class BarberRegistrationScreen extends ConsumerStatefulWidget {
  const BarberRegistrationScreen({super.key});

  @override
  ConsumerState<BarberRegistrationScreen> createState() =>
      _BarberRegistrationScreenState();
}

class _BarberRegistrationScreenState
    extends ConsumerState<BarberRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form keys per step
  final _step0FormKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Avatar
  String _avatarUrl = '';
  Uint8List? _pickedAvatarBytes;
  final ImagePicker _imagePicker = ImagePicker();

  // Data
  String _address = '';
  GeoLocation _location = const GeoLocation(latitude: 0, longitude: 0);
  List<ServiceModel> _services = [];
  List<String> _hairstyleIds = [];
  Map<String, DayWorkingHours> _workingHours = {};

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _nameCtrl.text = user.displayName;
      _avatarUrl = user.avatarUrl;
    }
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _pickedAvatarBytes = bytes;
          _avatarUrl = base64String;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh đại diện: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAvatarImageSourceModal() {
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
                const Text(
                  'Chọn ảnh đại diện tiệm / thợ',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: AppDimensions.sm),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text(
                    'Chụp ảnh từ máy ảnh',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAvatarImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text(
                    'Chọn ảnh từ thư viện',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAvatarImage(ImageSource.gallery);
                  },
                ),
                if (_avatarUrl.isNotEmpty || _pickedAvatarBytes != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Xóa ảnh đại diện',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _avatarUrl = '';
                        _pickedAvatarBytes = null;
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    if (_address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ (Bước 2)')),
      );
      setState(() => _currentStep = 1);
      return;
    }
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 dịch vụ (Bước 3)'),
        ),
      );
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(barberProfileRepositoryProvider);

      final effectiveAvatar = _avatarUrl.trim().isNotEmpty
          ? _avatarUrl.trim()
          : user.avatarUrl;

      final profile = BarberProfileModel(
        uid: user.uid,
        displayName: _nameCtrl.text.trim(),
        avatarUrl: effectiveAvatar,
        bio: _bioCtrl.text.trim(),
        address: _address,
        location: _location,
        services: _services,
        hairstyleIds: _hairstyleIds,
        workingHours: _workingHours,
        approvalStatus: 'pending',
      );

      await repo.createOrUpdateProfile(profile);

      // Cập nhật tài khoản người dùng nếu avatar hoặc tên có thay đổi
      final nameChanged = _nameCtrl.text.trim() != user.displayName;
      final avatarChanged =
          effectiveAvatar.isNotEmpty && effectiveAvatar != user.avatarUrl;
      if (nameChanged || avatarChanged) {
        await ref.read(authStateProvider.notifier).updateProfile(
              displayName: _nameCtrl.text.trim(),
              avatarUrl: effectiveAvatar,
            );
      }

      if (mounted) {
        // Invalidate và đợi nạp xong dữ liệu mới trước khi chuyển trang
        ref.invalidate(barberProfileProvider(user.uid));
        await ref.read(barberProfileProvider(user.uid).future);
        if (mounted) {
          context.go('/barber/pending');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo hồ sơ Thợ cắt tóc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Stepper(
                  type: StepperType.vertical,
                  physics: const ClampingScrollPhysics(),
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (!_step0FormKey.currentState!.validate()) return;
                }

                if (_currentStep < 3) {
                  setState(() => _currentStep += 1);
                } else {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              onStepTapped: (step) {
                setState(() => _currentStep = step);
              },
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 3;
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            isLastStep ? 'Hoàn tất & Gửi duyệt' : 'Tiếp tục',
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Quay lại'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // ===== STEP 1: Thông tin cơ bản =====
                Step(
                  title: const Text('Thông tin cơ bản'),
                  content: Form(
                    key: _step0FormKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Avatar picker
                        Center(
                          child: GestureDetector(
                            onTap: _showAvatarImageSourceModal,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (_pickedAvatarBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Image.memory(
                                      _pickedAvatarBytes!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  AppAvatar(
                                    imageUrl: _avatarUrl,
                                    name: _nameCtrl.text.isNotEmpty
                                        ? _nameCtrl.text
                                        : 'Thợ',
                                    shape: BoxShape.circle,
                                    size: 80,
                                    fallbackIcon: Icons.camera_alt_outlined,
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _showAvatarImageSourceModal,
                          child: Text(
                            _avatarUrl.isNotEmpty || _pickedAvatarBytes != null
                                ? 'Đổi ảnh đại diện'
                                : 'Chọn ảnh đại diện tiệm / thợ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tên hiển thị',
                            hintText: 'VD: Tiệm tóc Minh Nhật',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Không được để trống'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Giới thiệu ngắn',
                            hintText: 'VD: 5 năm kinh nghiệm, chuyên tóc nam Hàn Quốc',
                            prefixIcon: Icon(Icons.info_outline),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // ===== STEP 2: Vị trí bản đồ =====
                Step(
                  title: const Text('Vị trí & Địa chỉ'),
                  content: LocationPicker(
                    initialAddress: _address,
                    initialLocation: _location,
                    onChanged: (addr, loc) {
                      _address = addr;
                      _location = loc;
                    },
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // ===== STEP 3: Dịch vụ & Kiểu tóc =====
                Step(
                  title: const Text('Dịch vụ & Kiểu tóc'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ServiceEditor(
                        initialServices: _services,
                        onChanged: (services) => _services = services,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      HairstylePicker(
                        initialSelectedIds: _hairstyleIds,
                        onChanged: (ids) => _hairstyleIds = ids,
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // ===== STEP 4: Giờ làm việc =====
                Step(
                  title: const Text('Giờ làm việc'),
                  content: WorkingHoursEditor(
                    initialHours: _workingHours,
                    onChanged: (hours) => _workingHours = hours,
                  ),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
        ),
    );
  }
}
