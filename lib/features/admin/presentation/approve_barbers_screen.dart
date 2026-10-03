// ============================================================================
// File: lib/features/admin/presentation/approve_barbers_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng admin.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/services/seed_data_service.dart';
import '../../../../models/barber_profile_model.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/auth_provider.dart';

class ApproveBarbersScreen extends ConsumerWidget {
  const ApproveBarbersScreen({super.key});

  static const Map<String, String> _dayLabels = {
    'mon': 'Thứ Hai',
    'tue': 'Thứ Ba',
    'wed': 'Thứ Tư',
    'thu': 'Thứ Năm',
    'fri': 'Thứ Sáu',
    'sat': 'Thứ Bảy',
    'sun': 'Chủ Nhật',
  };

  static String _getHairstyleName(String id) {
    for (final h in SeedDataService.sampleHairstyles) {
      if (h.id == id) return h.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBarbers = ref.watch(pendingBarbersProvider);
    final adminState = ref.watch(adminControllerProvider);

    ref.listen<AsyncValue<void>>(adminControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, st) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $err'),
            backgroundColor: AppColors.error,
          ),
        ),
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật trạng thái hồ sơ thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Duyệt hồ sơ thợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: () => ref.invalidate(pendingBarbersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingBarbers.when(
              data: (barbers) {
                if (barbers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không có hồ sơ nào cần duyệt.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    final currencyFormatter = NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === Header Card ===
                            Row(
                              children: [
                                AppAvatar(
                                  shape: BoxShape.circle,
                                  size: 48,
                                  imageUrl: barber.avatarUrl,
                                  fallbackUrl: barber.coverUrl,
                                  name: barber.displayName,
                                  fallbackIcon: Icons.storefront_rounded,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        barber.displayName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              barber.address.isEmpty
                                                  ? 'Chưa có địa chỉ'
                                                  : barber.address,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Chờ duyệt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // === Tóm tắt thông tin nhanh ===
                            if (barber.bio.isNotEmpty) ...[
                              _buildInfoRow(
                                Icons.info_outline,
                                'Giới thiệu',
                                barber.bio,
                              ),
                              const SizedBox(height: 8),
                            ],
                            _buildInfoRow(
                              Icons.payments_outlined,
                              'Khoảng giá',
                              '${currencyFormatter.format(barber.priceMin)} - ${currencyFormatter.format(barber.priceMax)}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.design_services_outlined,
                              'Dịch vụ',
                              '${barber.services.length} dịch vụ đăng ký',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.content_cut_rounded,
                              'Kiểu tóc',
                              '${barber.hairstyleIds.length} kiểu tóc hỗ trợ',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.schedule_rounded,
                              'Giờ làm việc',
                              '${barber.workingHours.length} ngày trong tuần',
                            ),

                            const SizedBox(height: 14),

                            // === Nút xem chi tiết toàn bộ hồ sơ ===
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showBarberDetailsModal(
                                  context,
                                  ref,
                                  barber,
                                ),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('Xem chi tiết hồ sơ đầy đủ'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // === Nút duyệt / từ chối nhanh ===
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showRejectConfirm(
                                      context,
                                      ref,
                                      barber.uid,
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Từ chối'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                        color: AppColors.error,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => ref
                                        .read(adminControllerProvider.notifier)
                                        .approveBarber(barber.uid),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Duyệt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
              },
              loading: () => ListView.builder(
                itemCount: 4,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) => LoadingShimmer.listTile(),
              ),
              error: (err, stack) =>
                  Center(child: Text('Lỗi tải danh sách: $err')),
            ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Hiển thị Modal Bottom Sheet xem chi tiết toàn diện hồ sơ thợ
  void _showBarberDetailsModal(
    BuildContext context,
    WidgetRef ref,
    BarberProfileModel barber,
  ) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Thanh header kéo modal
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title bar modal
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chi tiết hồ sơ thợ cắt tóc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Nội dung chi tiết cuộn được
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Thẻ định danh
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              shape: BoxShape.circle,
                              size: 60,
                              imageUrl: barber.avatarUrl,
                              fallbackUrl: barber.coverUrl,
                              name: barber.displayName,
                              fallbackIcon: Icons.storefront_rounded,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barber.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'UID: ${barber.uid}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Trạng thái: Đang chờ duyệt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Giới thiệu
                      _buildSectionTitle(
                        Icons.info_outline,
                        'Giới thiệu tiệm / thợ',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          barber.bio.isNotEmpty
                              ? barber.bio
                              : 'Chưa có thông tin giới thiệu.',
                          style: TextStyle(
                            fontSize: 14,
                            color: barber.bio.isNotEmpty
                                ? Colors.black87
                                : Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Địa chỉ & Toạ độ định vị
                      _buildSectionTitle(
                        Icons.location_on_outlined,
                        'Địa chỉ & Vị trí toạ độ',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Địa chỉ: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    barber.address.isNotEmpty
                                        ? barber.address
                                        : 'Chưa cung cấp',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Toạ độ GPS: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${barber.location.latitude.toStringAsFixed(5)}, ${barber.location.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Bảng danh sách dịch vụ chi tiết
                      _buildSectionTitle(
                        Icons.design_services_outlined,
                        'Dịch vụ & Bảng giá (${barber.services.length} dịch vụ)',
                      ),
                      const SizedBox(height: 6),
                      if (barber.services.isEmpty)
                        const Text(
                          'Chưa thiết lập dịch vụ nào.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Column(
                          children: barber.services.map((svc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          svc.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.timer_outlined,
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${svc.durationMinutes} phút',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(svc.price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // 5. Kiểu tóc hỗ trợ
                      _buildSectionTitle(
                        Icons.content_cut_rounded,
                        'Kiểu tóc chuyên gia hỗ trợ (${barber.hairstyleIds.length} kiểu)',
                      ),
                      const SizedBox(height: 6),
                      if (barber.hairstyleIds.isEmpty)
                        const Text(
                          'Chưa chọn kiểu tóc nào.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: barber.hairstyleIds.map((id) {
                            final name = _getHairstyleName(id);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // 6. Lịch làm việc chi tiết từng ngày
                      _buildSectionTitle(
                        Icons.calendar_today_outlined,
                        'Giờ làm việc chi tiết trong tuần',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children:
                              [
                                'mon',
                                'tue',
                                'wed',
                                'thu',
                                'fri',
                                'sat',
                                'sun',
                              ].map((dayKey) {
                                final label = _dayLabels[dayKey] ?? dayKey;
                                final dayInfo = barber.workingHours[dayKey];
                                final isClosed =
                                    dayInfo == null || dayInfo.closed;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isClosed)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Đóng cửa / Nghỉ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${dayInfo.open} - ${dayInfo.close}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Thanh thao tác dưới cùng modal
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _showRejectConfirm(context, ref, barber.uid);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Từ chối'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            ref
                                .read(adminControllerProvider.notifier)
                                .approveBarber(barber.uid);
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Duyệt hồ sơ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  void _showRejectConfirm(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: const Text('Bạn có chắc chắn muốn từ chối hồ sơ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminControllerProvider.notifier).rejectBarber(uid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
