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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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

  void _openChat(AppointmentModel appointment) {
    final chatId = ChatConversation.buildChatId(
      appointment.customerId,
      appointment.barberId,
    );
    context.push(
      '/chat/$chatId'
      '?otherUserId=${appointment.customerId}'
      '&otherUserName=${Uri.encodeComponent(appointment.customerName)}'
      '&customerId=${appointment.customerId}'
      '&customerName=${Uri.encodeComponent(appointment.customerName)}'
      '&barberId=${appointment.barberId}'
      '&barberName=${Uri.encodeComponent(appointment.barberName)}',
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
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(barberAppointmentsProvider),
          ),
          IconButton(
            tooltip: 'Tin nhắn',
            icon: const Icon(Icons.chat_outlined, color: AppColors.accent),
            onPressed: () => context.push('/conversations'),
          ),
          IconButton(
            tooltip: 'Quản lý tiệm tóc',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.push('/barber/profile-edit'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusMd,
            ),
            onSelected: (value) {
              switch (value) {
                case 'preview':
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    context.push('/customer/barber/${user.uid}');
                  }
                  break;
                case 'profile':
                  context.push('/barber/profile');
                  break;
                case 'store':
                  context.push('/barber/profile-edit');
                  break;
                case 'chat':
                  context.push('/conversations');
                  break;
                case 'logout':
                  ref.read(authStateProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 20, color: AppColors.accent),
                    SizedBox(width: AppDimensions.sm),
                    Text('Xem trang tiệm công khai', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: AppDimensions.sm),
                    Text('Hồ sơ thợ', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'store',
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: AppDimensions.sm),
                    Text('Trang cửa tiệm', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    Icon(Icons.chat_outlined, size: 20, color: AppColors.accent),
                    SizedBox(width: AppDimensions.sm),
                    Text('Tin nhắn khách hàng', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                    SizedBox(width: AppDimensions.sm),
                    Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _tabController.animateTo(index);
            if (mounted) setState(() {});
          },
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chờ duyệt'),
                  if (appointmentsAsync.valueOrNull != null && appointmentsAsync.valueOrNull!.where((a) => a.isPending).isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${appointmentsAsync.valueOrNull!.where((a) => a.isPending).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đã nhận'),
                  if (appointmentsAsync.valueOrNull != null && appointmentsAsync.valueOrNull!.where((a) => a.isConfirmed).isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${appointmentsAsync.valueOrNull!.where((a) => a.isConfirmed).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lịch sử'),
                  if (appointmentsAsync.valueOrNull != null && appointmentsAsync.valueOrNull!.where((a) => a.isCompleted || a.isCancelled || a.isRejected).isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${appointmentsAsync.valueOrNull!.where((a) => a.isCompleted || a.isCancelled || a.isRejected).length})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.lg),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.md),
          itemBuilder: (_, _) => LoadingShimmer.card(height: 140),
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

          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final activeIndex = _tabController.index;
              if (activeIndex == 1) {
                return _buildList(
                  appointments: confirmedList,
                  emptyTitle: 'Chưa có lịch hẹn nào đã nhận',
                  emptySubtitle: 'Lịch hẹn được tiếp nhận sẽ hiển thị tại đây.',
                );
              } else if (activeIndex == 2) {
                return _buildList(
                  appointments: historyList,
                  emptyTitle: 'Chưa có lịch sử lịch hẹn',
                  emptySubtitle: 'Các lịch hẹn hoàn thành hoặc đã hủy sẽ hiển thị ở đây.',
                );
              } else {
                return _buildList(
                  appointments: pendingList,
                  emptyTitle: 'Không có yêu cầu đặt lịch nào đang chờ',
                  emptySubtitle: 'Khách hàng đặt lịch mới sẽ hiển thị tại đây.',
                );
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          if (index == 1) {
            context.push('/barber/profile-edit');
          } else if (index == 2) {
            context.push('/conversations');
          } else if (index == 3) {
            context.push('/barber/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Cửa tiệm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat_rounded),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<AppointmentModel> appointments,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(barberAppointmentsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 350,
              child: Center(
                child: EmptyState(
                  icon: Icons.event_available_outlined,
                  title: emptyTitle,
                  message: emptySubtitle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(barberAppointmentsProvider),
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
                key: ValueKey(appointment.id),
                appointment: appointment,
                isBarberView: true,
                onConfirm: () => _handleConfirm(appointment),
                onReject: () => _handleReject(appointment),
                onComplete: () => _handleComplete(appointment),
                onChat: () => _openChat(appointment),
              );
            },
          ),
        ),
      ),
    );
  }
}
