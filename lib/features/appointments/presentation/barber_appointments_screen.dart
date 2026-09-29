import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import 'widgets/appointment_card.dart';

/// Màn hình quản lý lịch hẹn dành riêng cho thợ cắt tóc (Task 4.13)
///
/// Phân chia 3 tab chuyên biệt:
/// 1. "Chờ tiếp nhận": Lịch hẹn khách mới đặt (pending), thợ có thể Tiếp nhận hoặc Từ chối
/// 2. "Đã tiếp nhận": Lịch hẹn đã xác nhận (confirmed), chuẩn bị đón khách hoặc Hoàn tất dịch vụ
/// 3. "Lịch sử": Lịch đã hoàn thành, khách hủy, hoặc thợ từ chối
class BarberAppointmentsScreen extends ConsumerStatefulWidget {
  const BarberAppointmentsScreen({super.key});

  @override
  ConsumerState<BarberAppointmentsScreen> createState() =>
      _BarberAppointmentsScreenState();
}

class _BarberAppointmentsScreenState
    extends ConsumerState<BarberAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm(AppointmentModel appointment) async {
    final success = await ref
        .read(appointmentActionProvider.notifier)
        .confirmAppointment(appointment.id);

    if (!mounted) return;

    final actionState = ref.read(appointmentActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (actionState.successMessage ?? 'Đã tiếp nhận lịch hẹn!')
              : (actionState.errorMessage ?? 'Không thể tiếp nhận lịch hẹn!'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _handleReject(AppointmentModel appointment) async {
    final reasonController = TextEditingController();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        title: const Text('Từ chối lịch hẹn?', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn từ chối lịch hẹn của khách "${appointment.customerName}" lúc ${appointment.startTime}, ngày ${DateFormatter.formatShortDate(appointment.startTimestamp)} không?\n\nKhung giờ này sẽ được mở lại tự động.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (không bắt buộc)',
                hintText: 'Ví dụ: Kẹt việc đột xuất, trùng lịch cá nhân...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Từ Chối Lịch'),
          ),
        ],
      ),
    );

    if (shouldReject != true || !mounted) return;

    final success = await ref
        .read(appointmentActionProvider.notifier)
        .rejectAppointment(
          appointment.id,
          reason: reasonController.text.trim(),
        );

    if (!mounted) return;

    final actionState = ref.read(appointmentActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (actionState.successMessage ?? 'Đã từ chối lịch hẹn và giải phóng slot!')
              : (actionState.errorMessage ?? 'Không thể từ chối lịch hẹn!'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _handleComplete(AppointmentModel appointment) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        title: const Text('Hoàn tất dịch vụ?', style: AppTextStyles.h4),
        content: Text(
          'Xác nhận đã hoàn thành phục vụ khách hàng "${appointment.customerName}" với dịch vụ "${appointment.serviceName}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Chưa xong', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hoàn Tất'),
          ),
        ],
      ),
    );

    if (shouldComplete != true || !mounted) return;

    final success = await ref
        .read(appointmentActionProvider.notifier)
        .completeAppointment(appointment.id);

    if (!mounted) return;

    final actionState = ref.read(appointmentActionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (actionState.successMessage ?? 'Đã hoàn tất lịch hẹn!')
              : (actionState.errorMessage ?? 'Không thể hoàn tất lịch hẹn!'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(barberAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản Lý Lịch Hẹn', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã nhận'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: ErrorRetry(
            errorMessage: 'Lỗi tải danh sách lịch hẹn: $err',
            onRetry: () => ref.refresh(barberAppointmentsProvider),
          ),
        ),
        data: (appointments) {
          final pendingList = appointments.where((a) => a.isPending).toList();
          final confirmedList =
              appointments.where((a) => a.isConfirmed).toList();
          final historyList = appointments
              .where((a) => a.isCompleted || a.isCancelled || a.isRejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                appointments: pendingList,
                emptyTitle: 'Không có yêu cầu đặt lịch nào đang chờ',
                emptySubtitle: 'Khách hàng đặt lịch mới sẽ hiển thị tại đây.',
              ),
              _buildList(
                appointments: confirmedList,
                emptyTitle: 'Chưa có lịch hẹn nào đã nhận',
                emptySubtitle: 'Lịch hẹn được tiếp nhận sẽ hiển thị tại đây.',
              ),
              _buildList(
                appointments: historyList,
                emptyTitle: 'Chưa có lịch sử lịch hẹn',
                emptySubtitle: 'Các lịch hẹn hoàn thành hoặc đã hủy sẽ hiển thị ở đây.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList({
    required List<AppointmentModel> appointments,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: emptyTitle,
          message: emptySubtitle,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.lg),
      itemCount: appointments.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.md),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment,
          isBarberView: true,
          onConfirm: () => _handleConfirm(appointment),
          onReject: () => _handleReject(appointment),
          onComplete: () => _handleComplete(appointment),
        );
      },
    );
  }
}
