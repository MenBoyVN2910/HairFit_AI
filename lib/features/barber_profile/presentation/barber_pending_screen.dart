// ============================================================================
// File: lib/features/barber_profile/presentation/barber_pending_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng barber_profile.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/auth_provider.dart';
import '../data/barber_profile_repository.dart';

class BarberPendingScreen extends ConsumerWidget {
  const BarberPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    // Nếu chưa có user thì hiển thị màn hình trống
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(barberProfileProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới trạng thái',
            onPressed: () {
              ref.invalidate(barberProfileProvider(user.uid));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(barberProfileProvider(user.uid));
          await ref.read(barberProfileProvider(user.uid).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  // Chưa có profile -> Hiển thị thông báo và nút tạo
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assignment_ind_outlined,
                              size: 64,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Chưa có hồ sơ thợ cắt tóc',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bạn cần tạo hồ sơ tiệm tóc (dịch vụ, giờ làm việc, địa chỉ) để gửi quản trị viên phê duyệt trước khi nhận lịch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.go('/barber/profile-setup'),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Tạo hồ sơ ngay'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (profile.isApproved) {
                  // Đã duyệt -> Vào màn hình chính của thợ
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.go('/barber/appointments');
                    }
                  });
                  return const Center(child: CircularProgressIndicator());
                }

                if (profile.isRejected) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cancel_outlined,
                              size: 64,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Hồ sơ của bạn đã bị từ chối',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Quản trị viên đã từ chối hồ sơ này. Vui lòng kiểm tra lại thông tin và gửi lại hồ sơ.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.go('/barber/profile-setup'),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Chỉnh sửa & Gửi lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Trường hợp isPending: Hiển thị giao diện chờ duyệt
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.hourglass_top_rounded,
                            size: 64,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Hồ sơ của bạn đang được xét duyệt',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Quản trị viên đang kiểm tra thông tin đăng ký của bạn. Bạn sẽ có thể bắt đầu nhận lịch sau khi hồ sơ được duyệt.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/barber/profile-edit'),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Xem & Cập nhật thông tin tiệm'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '(Bạn có thể cập nhật lại thông tin trong Trang Thợ)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
