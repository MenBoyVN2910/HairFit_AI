// ============================================================================
// File: lib/features/appointments/presentation/customer_appointments_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng appointments.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../models/appointment_model.dart';
import '../../../models/chat_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/appointment_provider.dart';
import 'widgets/appointment_card.dart';

/// Màn hình danh sách lịch hẹn của Khách hàng (Task 4.12)
///
/// Phân loại 2 tab:
/// - "Sắp tới": Lịch đang chờ thợ duyệt (pending) hoặc đã được xác nhận (confirmed)
/// - "Lịch sử": Lịch đã hoàn tất (completed), đã hủy (cancelled) hoặc bị từ chối (rejected)
class CustomerAppointmentsScreen extends ConsumerStatefulWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  ConsumerState<CustomerAppointmentsScreen> createState() =>
      _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState
    extends ConsumerState<CustomerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndCancel(AppointmentModel appointment) async {
    final customer = ref.read(currentUserModelProvider).value;
    if (customer == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        title: const Text('Xác nhận hủy lịch hẹn?', style: AppTextStyles.h4),
        content: Text(
          'Bạn có chắc muốn hủy lịch hẹn với "${appointment.barberName}" lúc ${appointment.startTime}, ngày ${DateFormatter.formatShortDate(appointment.startTimestamp)}?\n\nKhung giờ này sẽ được giải phóng cho khách khác.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Giữ lại',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy Lịch'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    final success = await ref
        .read(appointmentActionProvider.notifier)
        .cancelAppointment(
          appointmentId: appointment.id,
          customerId: customer.uid,
        );

    if (!mounted) return;

    final actionState = ref.read(appointmentActionProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actionState.successMessage ?? 'Đã hủy lịch hẹn thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actionState.errorMessage ?? 'Không thể hủy lịch hẹn!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showRatingDialog(AppointmentModel appointment) async {
    int selectedStars = 5;
    final commentController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          title: const Text('Đánh giá dịch vụ', style: AppTextStyles.h4),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Bạn cảm thấy dịch vụ của thợ "${appointment.barberName}" như thế nào?',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return IconButton(
                      iconSize: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      icon: Icon(
                        starNum <= selectedStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedStars = starNum;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: AppDimensions.md),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét của bạn (không bắt buộc)',
                    hintText: 'Cắt rất khéo, tạo kiểu ưng ý...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Đóng',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Gửi Đánh Giá'),
            ),
          ],
        ),
      ),
    );

    if (shouldSubmit != true || !mounted) return;

    final success = await ref
        .read(appointmentActionProvider.notifier)
        .rateAppointment(
          appointmentId: appointment.id,
          barberId: appointment.barberId,
          rating: selectedStars,
          customerId: appointment.customerId,
          customerName: appointment.customerName,
          comment: commentController.text.trim(),
        );

    if (!mounted) return;

    final actionState = ref.read(appointmentActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (actionState.successMessage ?? 'Đã gửi đánh giá thành công!')
              : (actionState.errorMessage ?? 'Không thể gửi đánh giá!'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  void _openChat(AppointmentModel appointment) {
    final chatId = ChatConversation.buildChatId(
      appointment.customerId,
      appointment.barberId,
    );
    context.push(
      '/chat/$chatId'
      '?otherUserId=${appointment.barberId}'
      '&otherUserName=${Uri.encodeComponent(appointment.barberName)}'
      '&customerId=${appointment.customerId}'
      '&customerName=${Uri.encodeComponent(appointment.customerName)}'
      '&barberId=${appointment.barberId}'
      '&barberName=${Uri.encodeComponent(appointment.barberName)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(customerAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Hẹn Của Tôi', style: AppTextStyles.h3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: () => ref.refresh(customerAppointmentsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: AppColors.accent),
            tooltip: 'Tin nhắn',
            onPressed: () => context.push('/conversations'),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () => context.go('/customer/home'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => ListView.builder(
          itemCount: 4,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          itemBuilder: (context, index) => LoadingShimmer.listTile(),
        ),
        error: (err, _) => Center(
          child: ErrorRetry(
            errorMessage: 'Lỗi tải danh sách lịch hẹn: $err',
            onRetry: () => ref.refresh(customerAppointmentsProvider),
          ),
        ),
        data: (appointments) {
          final upcoming = appointments
              .where((a) => a.isPending || a.isConfirmed)
              .toList();
          final history = appointments
              .where((a) => a.isCompleted || a.isCancelled || a.isRejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(
                appointments: upcoming,
                isHistory: false,
                emptyTitle: 'Chưa có lịch hẹn nào sắp tới',
                emptySubtitle:
                    'Hãy tìm kiếm thợ cắt tóc ưng ý và đặt lịch ngay!',
              ),
              _buildAppointmentList(
                appointments: history,
                isHistory: true,
                emptyTitle: 'Chưa có lịch sử lịch hẹn',
                emptySubtitle:
                    'Các lịch hẹn đã hoàn tất hoặc đã hủy sẽ hiển thị ở đây.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentList({
    required List<AppointmentModel> appointments,
    required bool isHistory,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(customerAppointmentsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 350,
              child: Center(
                child: EmptyState(
                  icon: Icons.event_note_rounded,
                  title: emptyTitle,
                  message: emptySubtitle,
                  actionText: !isHistory ? 'Tìm Thợ Cắt Tóc' : null,
                  onAction:
                      !isHistory ? () => context.push('/customer/search') : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(customerAppointmentsProvider),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.lg),
            itemCount: appointments.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.md),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AppointmentCard(
                appointment: appointment,
                isBarberView: false,
                onCancel: () => _confirmAndCancel(appointment),
                onRate: () => _showRatingDialog(appointment),
                onChat: () => _openChat(appointment),
              );
            },
          ),
        ),
      ),
    );
  }
}
