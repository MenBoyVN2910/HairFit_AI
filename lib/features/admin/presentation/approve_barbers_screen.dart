import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ApproveBarbersScreen extends ConsumerWidget {
  const ApproveBarbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBarbers = ref.watch(pendingBarbersProvider);
    final adminState = ref.watch(adminControllerProvider);

    ref.listen<AsyncValue<void>>(adminControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, st) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $err'))),
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái')));
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Duyệt hồ sơ thợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          )
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
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Không có hồ sơ nào cần duyệt.', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === Header ===
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                                  child: Text(
                                    barber.displayName.isNotEmpty ? barber.displayName[0].toUpperCase() : '?',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(barber.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Expanded(child: Text(barber.address.isEmpty ? 'Chưa có địa chỉ' : barber.address, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Chờ duyệt', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // === Chi tiết ===
                            if (barber.bio.isNotEmpty) ...[
                              _buildInfoRow(Icons.info_outline, 'Giới thiệu', barber.bio),
                              const SizedBox(height: 8),
                            ],
                            _buildInfoRow(Icons.design_services, 'Số dịch vụ', '${barber.services.length} dịch vụ'),
                            const SizedBox(height: 8),

                            // Liệt kê dịch vụ
                            if (barber.services.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: barber.services.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('${s.name} (${currencyFormatter.format(s.price)})', style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            _buildInfoRow(Icons.content_cut, 'Kiểu tóc hỗ trợ', '${barber.hairstyleIds.length} kiểu'),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.schedule, 'Giờ làm việc', '${barber.workingHours.length} ngày/tuần'),
                            
                            const SizedBox(height: 20),

                            // === Nút duyệt / từ chối ===
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showRejectConfirm(context, ref, barber.uid),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Từ chối'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => ref.read(adminControllerProvider.notifier).approveBarber(barber.uid),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Duyệt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi tải danh sách: $err')),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminControllerProvider.notifier).rejectBarber(uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
