import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../models/barber_profile_model.dart';
import '../../../models/service_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/booking_provider.dart';
import '../../search_map/data/barber_repository.dart';
import 'widgets/booking_summary.dart';
import 'widgets/date_picker.dart';
import 'widgets/service_selector.dart';
import 'widgets/time_slot_grid.dart';

/// Màn hình đặt lịch cắt tóc với thợ (Task 4.7)
///
/// Luồng chuẩn 4 bước:
/// 1. Chọn dịch vụ (xác định thời lượng & giá)
/// 2. Chọn ngày hẹn (trong 30 ngày tới)
/// 3. Chọn khung giờ khả dụng (lưới slot 30 phút chống trùng)
/// 4. Tóm tắt chi tiết, nhập ghi chú và bấm Xác nhận đặt lịch
class BookingScreen extends ConsumerStatefulWidget {
  final String barberId;
  final String? preselectedServiceId;
  final String? hairstyleId;

  const BookingScreen({
    super.key,
    required this.barberId,
    this.preselectedServiceId,
    this.hairstyleId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _isInitialized = false;

  void _initBookingState(BarberProfileModel barber) {
    if (_isInitialized) return;
    _isInitialized = true;

    ServiceModel? preselected;
    if (widget.preselectedServiceId != null) {
      final matches = barber.services.where((s) => s.id == widget.preselectedServiceId);
      if (matches.isNotEmpty) {
        preselected = matches.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider.notifier).initialize(
            barber: barber,
            preselectedService: preselected,
            hairstyleId: widget.hairstyleId,
          );
    });
  }

  Future<void> _handleConfirmBooking({
    required BarberProfileModel barber,
  }) async {
    final customer = ref.read(currentUserModelProvider).value;
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đặt lịch hẹn!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(bookingNotifierProvider.notifier)
        .submitBooking(customer: customer, barber: barber);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      final error = ref.read(bookingNotifierProvider).errorMessage ??
          'Không thể hoàn tất đặt lịch. Vui lòng thử lại!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              const Text(
                'Đặt Lịch Thành Công!',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              const Text(
                'Lịch hẹn của bạn đã được chuyển tới thợ cắt tóc để xác nhận. Bạn có thể theo dõi tiến độ trong mục Lịch hẹn.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            text: 'Xem Lịch Hẹn Của Tôi',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/customer/appointments');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barberAsync = ref.watch(barberDetailProvider(widget.barberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đặt Lịch Cắt Tóc', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: barberAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: ErrorRetry(
            errorMessage: 'Không thể tải thông tin thợ: $err',
            onRetry: () => ref.refresh(barberDetailProvider(widget.barberId)),
          ),
        ),
        data: (barber) {
          if (barber == null) {
            return const Center(
              child: Text(
                'Không tìm thấy thông tin thợ cắt tóc.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          _initBookingState(barber);
          final bookingState = ref.watch(bookingNotifierProvider);
          final bookingNotifier = ref.read(bookingNotifierProvider.notifier);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header tóm tắt thợ
                      _buildBarberHeader(barber),
                      const SizedBox(height: AppDimensions.lg),

                      // Bước 1: Chọn dịch vụ
                      ServiceSelector(
                        services: barber.services,
                        selectedService: bookingState.selectedService,
                        onServiceSelected: (service) =>
                            bookingNotifier.selectService(service, barber),
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      // Bước 2: Chọn ngày hẹn
                      BookingDatePicker(
                        selectedDate: bookingState.selectedDate,
                        barber: barber,
                        onDateSelected: (date) =>
                            bookingNotifier.selectDate(date, barber),
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      // Bước 3: Chọn khung giờ
                      TimeSlotGrid(
                        slots: bookingState.availableSlots,
                        selectedSlot: bookingState.selectedSlot,
                        isLoading: bookingState.isLoadingSlots,
                        onSlotSelected: bookingNotifier.selectSlot,
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      // Bước 4: Tóm tắt & ghi chú
                      BookingSummary(
                        barber: barber,
                        service: bookingState.selectedService,
                        selectedDate: bookingState.selectedDate,
                        selectedSlot: bookingState.selectedSlot,
                        note: bookingState.note,
                        onNoteChanged: bookingNotifier.setNote,
                      ),
                      const SizedBox(height: AppDimensions.xl),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              _buildBottomBar(barber, bookingState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarberHeader(BarberProfileModel barber) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.secondary,
            backgroundImage:
                barber.avatarUrl.isNotEmpty ? NetworkImage(barber.avatarUrl) : null,
            child: barber.avatarUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(barber.displayName, style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(
                  barber.address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BarberProfileModel barber, BookingState bookingState) {
    final canSubmit = bookingState.canSubmit;
    final isSubmitting = bookingState.isSubmitting;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng tiền',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  bookingState.selectedService != null
                      ? DateFormatter.formatCurrency(bookingState.selectedService!.price)
                      : '0 đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: AppButton(
                text: 'Xác Nhận Đặt Lịch',
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                isLoading: isSubmitting,
                onPressed: canSubmit
                    ? () => _handleConfirmBooking(barber: barber)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
