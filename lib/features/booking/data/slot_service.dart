import '../../../core/constants/business_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/barber_profile_model.dart';
import '../../../models/booked_slot_model.dart';
import '../../../models/service_model.dart';

/// Đại diện cho một khung giờ có thể đặt trên giao diện
class AvailableSlot {
  /// Giờ bắt đầu (định dạng "HH:mm", ví dụ: "09:00")
  final String startTime;

  /// Giờ kết thúc (định dạng "HH:mm", ví dụ: "09:30" hoặc "10:30")
  final String endTime;

  /// Khung giờ này có sẵn sàng để đặt hay không
  final bool isAvailable;

  /// Danh sách các mã slot 30 phút mà khung giờ này chiếm dụng
  /// Ví dụ dịch vụ 60 phút từ 09:00: ["barber_1_2026-10-10_09-00", "barber_1_2026-10-10_09-30"]
  final List<String> slotIds;

  /// Lý do không khả dụng (nếu có): "Đã có người đặt", "Đã qua giờ", "Nghỉ làm việc"...
  final String? unavailabilityReason;

  /// Thời điểm bắt đầu chính xác dạng DateTime
  final DateTime startTimestamp;

  /// Thời điểm kết thúc chính xác dạng DateTime
  final DateTime endTimestamp;

  const AvailableSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.slotIds,
    this.unavailabilityReason,
    required this.startTimestamp,
    required this.endTimestamp,
  });

  @override
  String toString() =>
      'AvailableSlot($startTime-$endTime, available: $isAvailable, reason: $unavailabilityReason)';
}

/// Dịch vụ tính toán và sinh danh sách slot trống của thợ cắt tóc (Tasks 4.1, 4.2, 4.3)
///
/// Tuân thủ quy tắc nghiệp vụ:
/// 1. Kiểm tra ngày nghỉ theo tuần (workingHours.closed) và ngày nghỉ ngoại lệ (exceptions)
/// 2. Lấy giờ mở/đóng cửa và sinh slot với bước nhảy 30 phút
/// 3. Hỗ trợ thời lượng dịch vụ đa dạng (30, 60, 90, 120 phút = bội số của 30)
/// 4. Loại bỏ slot quá khứ, slot trong vòng lead time 30 phút, slot vượt quá 30 ngày tới
/// 5. Kiểm tra tính khả dụng đồng thời của TẤT CẢ các sub-slot 30 phút liên tiếp
class SlotService {
  const SlotService();

  /// Chuyển đổi DateTime.weekday (1..7) sang key chuẩn trong BarberProfileModel ('mon'..'sun')
  static String weekdayToKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  /// Chuyển chuỗi "HH:mm" thành số phút tính từ 00:00
  static int timeToMinutes(String timeStr) {
    final parts = timeStr.trim().split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  /// Chuyển số phút từ 00:00 thành chuỗi "HH:mm"
  static String minutesToTime(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Sinh toàn bộ danh sách các khung giờ (AvailableSlot) cho một thợ vào một ngày cụ thể
  ///
  /// [barberProfile]: Hồ sơ thợ chứa giờ làm việc và ngày nghỉ ngoại lệ
  /// [selectedDate]: Ngày được chọn (dạng yyyy-MM-dd hoặc DateTime)
  /// [selectedService]: Dịch vụ được chọn (xác định thời lượng durationMinutes)
  /// [existingBookedSlots]: Danh sách các slot đã có người đặt trên Firestore
  /// [currentTime]: Thời điểm hiện tại (cho phép inject để unit test)
  List<AvailableSlot> generateAvailableSlots({
    required BarberProfileModel barberProfile,
    required DateTime selectedDate,
    required ServiceModel selectedService,
    required List<BookedSlotModel> existingBookedSlots,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final dateStr = DateFormatter.toIsoDateString(selectedDate);

    // Chuẩn hóa ngày chỉ lấy phần Year-Month-Day (00:00:00)
    final normalizedSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final normalizedToday = DateTime(now.year, now.month, now.day);

    // ══════════════════════════════════════════════════════════════
    // BƯỚC 1: KIỂM TRA TÍNH HỢP LỆ CỦA NGÀY
    // ══════════════════════════════════════════════════════════════

    // 1.1 Không cho đặt ngày trong quá khứ
    if (normalizedSelectedDate.isBefore(normalizedToday)) {
      return [];
    }

    // 1.2 Không cho đặt quá 30 ngày tính từ hôm nay (BusinessConstants.maxBookingDaysAhead)
    final maxDateAllowed = normalizedToday.add(
      const Duration(days: BusinessConstants.maxBookingDaysAhead),
    );
    if (normalizedSelectedDate.isAfter(maxDateAllowed)) {
      return [];
    }

    // 1.3 Kiểm tra ngày nghỉ ngoại lệ (exceptions) của thợ
    final isExceptionClosed = barberProfile.exceptions.any(
      (e) => e.date == dateStr && e.closed,
    );
    if (isExceptionClosed) {
      return [];
    }

    // 1.4 Kiểm tra lịch làm việc định kỳ trong tuần (workingHours)
    final dayKey = weekdayToKey(selectedDate.weekday);
    final dayConfig = barberProfile.workingHours[dayKey];

    // Nếu thợ không cấu hình hoặc đánh dấu đóng cửa vào ngày này
    if (dayConfig == null || dayConfig.closed) {
      return [];
    }

    // ══════════════════════════════════════════════════════════════
    // BƯỚC 2: PHÂN TÍCH GIỜ MỞ/ĐÓNG & THỜI LƯỢNG DỊCH VỤ
    // ══════════════════════════════════════════════════════════════
    final openMinutes = timeToMinutes(dayConfig.open);
    final closeMinutes = timeToMinutes(dayConfig.close);

    // Thời lượng dịch vụ (bội số 30 phút, tối thiểu 30)
    final durationMinutes = selectedService.durationMinutes > 0
        ? selectedService.durationMinutes
        : BusinessConstants.slotMinutes;
    final slotsCount = (durationMinutes / BusinessConstants.slotMinutes).ceil();

    if (openMinutes >= closeMinutes || (closeMinutes - openMinutes) < durationMinutes) {
      return [];
    }

    // Tập hợp các ID slot đã bị đặt trước trong ngày
    final bookedSlotIdSet = existingBookedSlots.map((e) => e.id).toSet();

    // ══════════════════════════════════════════════════════════════
    // BƯỚC 3 & 4: SINH SLOT VÀ KIỂM TRA ĐIỀU KIỆN KHẢ DỤNG
    // ══════════════════════════════════════════════════════════════
    final resultSlots = <AvailableSlot>[];

    // Thời điểm cắt (lead time): Phải đặt trước ít nhất leadTimeMinutes (30 phút)
    final leadTimeCutoff = now.add(
      const Duration(minutes: BusinessConstants.leadTimeMinutes),
    );

    // Duyệt qua từng khung giờ bắt đầu có thể (bước nhảy 30 phút)
    for (
      int startMin = openMinutes;
      startMin <= closeMinutes - durationMinutes;
      startMin += BusinessConstants.slotMinutes
    ) {
      final endMin = startMin + durationMinutes;
      final startTimeStr = minutesToTime(startMin);
      final endTimeStr = minutesToTime(endMin);

      final slotStartDateTime = DateFormatter.combineDateAndTime(
        dateStr,
        startTimeStr,
      );
      final slotEndDateTime = DateFormatter.combineDateAndTime(
        dateStr,
        endTimeStr,
      );

      // Sinh danh sách các mã slot 30 phút liên tiếp cần chiếm dụng
      final requiredSlotIds = <String>[];
      for (int i = 0; i < slotsCount; i++) {
        final subSlotStartMin = startMin + (i * BusinessConstants.slotMinutes);
        final subSlotTimeStr = minutesToTime(subSlotStartMin);
        final slotId = BookedSlotModel.generateSlotId(
          barberId: barberProfile.uid,
          date: dateStr,
          time: subSlotTimeStr,
        );
        requiredSlotIds.add(slotId);
      }

      // Kiểm tra lý do không khả dụng
      bool isAvailable = true;
      String? unavailabilityReason;

      // Kiểm tra 1: Khung giờ nằm trong quá khứ hoặc quá sát giờ hẹn (< 30 phút)
      if (slotStartDateTime.isBefore(leadTimeCutoff)) {
        isAvailable = false;
        unavailabilityReason = slotStartDateTime.isBefore(now)
            ? 'Đã qua giờ'
            : 'Quá sát giờ hẹn (tối thiểu 30 phút)';
      }

      // Kiểm tra 2: Có bất kỳ sub-slot 30 phút nào đã có người đặt trước
      if (isAvailable) {
        final hasConflict = requiredSlotIds.any(
          (slotId) => bookedSlotIdSet.contains(slotId),
        );
        if (hasConflict) {
          isAvailable = false;
          unavailabilityReason = 'Đã có người đặt';
        }
      }

      resultSlots.add(
        AvailableSlot(
          startTime: startTimeStr,
          endTime: endTimeStr,
          isAvailable: isAvailable,
          slotIds: requiredSlotIds,
          unavailabilityReason: unavailabilityReason,
          startTimestamp: slotStartDateTime,
          endTimestamp: slotEndDateTime,
        ),
      );
    }

    return resultSlots;
  }
}
