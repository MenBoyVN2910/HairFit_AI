// ============================================================================
// File: lib/features/booking/data/booking_repository.dart
// Mục đích: Quản lý dữ liệu (Repository) cho tính năng booking.
// Kết cấu:
//  - Tương tác với cơ sở dữ liệu (Firestore) hoặc API, cung cấp CRUD operations.
// ============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/business_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/appointment_model.dart';
import '../../../models/booked_slot_model.dart';

/// Ngoại lệ cơ sở cho các lỗi đặt lịch
class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => message;
}

/// Ngoại lệ khi một hoặc nhiều slot thời gian đã bị người khác đặt trước
class SlotAlreadyBookedException extends BookingException {
  final String slotId;
  SlotAlreadyBookedException(this.slotId)
    : super(
        'Khung giờ này vừa có người khác đặt. Vui lòng chọn khung giờ khác!',
      );
}

/// Ngoại lệ khi khách hàng đã đạt giới hạn tối đa 2 lịch hẹn đang active (pending/confirmed)
class MaxBookingsExceededException extends BookingException {
  MaxBookingsExceededException()
    : super(
        'Bạn đã có ${BusinessConstants.maxActiveBookingsPerCustomer} lịch hẹn chưa hoàn thành. Không thể đặt thêm!',
      );
}

/// Ngoại lệ khi đặt lịch quá sát giờ (dưới 30 phút)
class BookingLeadTimeException extends BookingException {
  BookingLeadTimeException()
    : super(
        'Vui lòng đặt lịch trước ít nhất ${BusinessConstants.leadTimeMinutes} phút!',
      );
}

/// Ngoại lệ khi đặt lịch vượt quá 30 ngày tới
class BookingMaxDaysExceededException extends BookingException {
  BookingMaxDaysExceededException()
    : super(
        'Chỉ được đặt lịch trước tối đa ${BusinessConstants.maxBookingDaysAhead} ngày!',
      );
}

/// Ngoại lệ khi không thể hủy lịch (do quá hạn 30 phút hoặc sai trạng thái)
class CannotCancelException extends BookingException {
  const CannotCancelException(super.message);
}

/// Repository xử lý giao dịch đặt lịch và hủy lịch chống trùng (Tasks 4.4, 4.5, 4.9)
class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Đếm số lượng lịch hẹn đang active (pending hoặc confirmed) của một khách hàng
  Future<int> countActiveBookings(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // Fallback nếu chưa tạo composite index trên Firestore
      final snapshot = await _firestore
          .collection('appointments')
          .where('customerId', isEqualTo: customerId)
          .get();

      return snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'pending' || status == 'confirmed';
      }).length;
    }
  }

  /// Lấy danh sách các slot đã đặt của thợ theo ngày.
  /// Chỉ coi là đã đặt khi có tài khoản khách hàng thực sự đặt (tồn tại appointment pending hoặc confirmed).
  /// Không tự bịa, không dùng dữ liệu rác mồ côi.
  Future<List<BookedSlotModel>> getBookedSlotsForDate(
    String barberId,
    String date,
  ) async {
    try {
      // 1. Lấy tất cả lịch hẹn thật sự đang active (pending / confirmed) của thợ trong ngày này
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('date', isEqualTo: date)
          .get();

      final activeAppointments = appointmentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String?;
        return status == 'pending' || status == 'confirmed';
      }).toList();

      // Nếu không có lịch hẹn thật nào đang active trong ngày này -> không có slot nào đã đặt
      if (activeAppointments.isEmpty) {
        // Chủ động dọn dẹp các document rác mồ côi nếu có trong bookedSlots
        _cleanupOrphanedBookedSlots(barberId, date, activeAppointmentIds: {});
        return [];
      }

      final activeAppointmentIds = activeAppointments
          .map((doc) => doc.id)
          .toSet();

      // 2. Lấy danh sách các slot trong bookedSlots và chỉ giữ lại các slot liên kết với appointment active thật
      final bookedSlotsSnapshot = await _firestore
          .collection('bookedSlots')
          .where('barberId', isEqualTo: barberId)
          .where('date', isEqualTo: date)
          .get();

      final validSlots = <BookedSlotModel>[];
      final orphanedDocRefs = <DocumentReference>[];

      for (final doc in bookedSlotsSnapshot.docs) {
        final data = doc.data();
        final appointmentId = data['appointmentId'] as String? ?? '';
        if (activeAppointmentIds.contains(appointmentId)) {
          validSlots.add(BookedSlotModel.fromFirestore(doc));
        } else {
          orphanedDocRefs.add(doc.reference);
        }
      }

      // 3. Tự động dọn dẹp các document mồ côi nếu có
      if (orphanedDocRefs.isNotEmpty) {
        for (final ref in orphanedDocRefs) {
          ref.delete().catchError((_) => null);
        }
      }

      // 4. Bổ sung các slotIds từ active appointments nếu bookedSlots bị thiếu
      final existingValidSlotIds = validSlots.map((s) => s.id).toSet();
      for (final appDoc in activeAppointments) {
        final data = appDoc.data();
        final rawSlotIds = data['slotIds'] as List<dynamic>? ?? [];
        final appDate = data['date'] as String? ?? date;
        final appTime = data['startTime'] as String? ?? '';

        for (final slotId in rawSlotIds) {
          final slotIdStr = slotId.toString();
          if (!existingValidSlotIds.contains(slotIdStr)) {
            final timePart = slotIdStr.contains('_')
                ? slotIdStr.split('_').last.replaceAll('-', ':')
                : appTime;
            final subSlotTimestamp = DateFormatter.combineDateAndTime(
              appDate,
              timePart,
            );
            validSlots.add(
              BookedSlotModel(
                id: slotIdStr,
                barberId: barberId,
                date: appDate,
                time: timePart,
                appointmentId: appDoc.id,
                startTimestamp: subSlotTimestamp,
              ),
            );
            existingValidSlotIds.add(slotIdStr);
          }
        }
      }

      return validSlots;
    } catch (e) {
      // Khi gặp lỗi mạng / index, trả về rỗng để không bịa đặt slot giả
      return [];
    }
  }

  void _cleanupOrphanedBookedSlots(
    String barberId,
    String date, {
    required Set<String> activeAppointmentIds,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookedSlots')
          .where('barberId', isEqualTo: barberId)
          .where('date', isEqualTo: date)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final appointmentId = data['appointmentId'] as String? ?? '';
        if (!activeAppointmentIds.contains(appointmentId)) {
          doc.reference.delete().catchError((_) => null);
        }
      }
    } catch (_) {}
  }

  /// Thực thi TRANSACTION đặt lịch nguyên tử (Atomic Transaction):
  /// 1. Kiểm tra giới hạn 2 lịch active của khách
  /// 2. Kiểm tra tính hợp lệ về thời gian (lead time 30 phút, tối đa 30 ngày)
  /// 3. Khóa và kiểm tra TẤT CẢ bookedSlots/{slotId} trong transaction
  /// 4. Tạo document appointments/{id}
  /// 5. Tạo các document bookedSlots/{slotId}
  Future<String> createBooking({
    required String customerId,
    required String customerName,
    required String barberId,
    required String barberName,
    required String serviceId,
    required String serviceName,
    required int price,
    required int durationMinutes,
    required String date,
    required String startTime,
    required String endTime,
    required List<String> slotIds,
    String hairstyleId = '',
    String note = '',
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();

    // 1. Kiểm tra số lượng lịch active của khách hàng (Tối đa 2)
    final activeBookingsCount = await countActiveBookings(customerId);
    if (activeBookingsCount >= BusinessConstants.maxActiveBookingsPerCustomer) {
      throw MaxBookingsExceededException();
    }

    // 2. Kiểm tra tính hợp lệ về thời gian bắt đầu
    final startTimestamp = DateFormatter.combineDateAndTime(date, startTime);
    final endTimestamp = DateFormatter.combineDateAndTime(date, endTime);

    final leadTimeCutoff = now.add(
      const Duration(minutes: BusinessConstants.leadTimeMinutes),
    );
    if (startTimestamp.isBefore(leadTimeCutoff)) {
      throw BookingLeadTimeException();
    }

    final maxBookingLimit = now.add(
      const Duration(days: BusinessConstants.maxBookingDaysAhead),
    );
    if (startTimestamp.isAfter(maxBookingLimit)) {
      throw BookingMaxDaysExceededException();
    }

    if (slotIds.isEmpty) {
      throw const BookingException('Danh sách slot thời gian không hợp lệ');
    }

    // 3. Thực hiện Firestore Transaction chống trùng lịch
    final appointmentRef = _firestore.collection('appointments').doc();
    final appointmentId = appointmentRef.id;

    await _firestore.runTransaction((transaction) async {
      // 3.1 Đọc và kiểm tra tất cả các slotIds trước
      for (final slotId in slotIds) {
        final slotDocRef = _firestore.collection('bookedSlots').doc(slotId);
        final slotSnapshot = await transaction.get(slotDocRef);
        if (slotSnapshot.exists) {
          throw SlotAlreadyBookedException(slotId);
        }
      }

      // 3.2 Ghi document lịch hẹn vào appointments
      final appointmentData = {
        'id': appointmentId,
        'customerId': customerId,
        'customerName': customerName,
        'barberId': barberId,
        'barberName': barberName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'price': price,
        'durationMinutes': durationMinutes,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'startTimestamp': Timestamp.fromDate(startTimestamp),
        'endTimestamp': Timestamp.fromDate(endTimestamp),
        'timezone': BusinessConstants.timezone,
        'slotIds': slotIds,
        'hairstyleId': hairstyleId,
        'note': note.trim(),
        'status': AppointmentStatus.pending.toStatusString(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      transaction.set(appointmentRef, appointmentData);

      // 3.3 Tạo các bản ghi giữ chỗ trong bookedSlots
      for (final slotId in slotIds) {
        final slotDocRef = _firestore.collection('bookedSlots').doc(slotId);

        // Lấy thời gian bắt đầu của từng sub-slot 30 phút từ slotId
        // slotId format: "{barberId}_{yyyy-MM-dd}_{HH-mm}"
        final timePart = slotId.split('_').last.replaceAll('-', ':');
        final subSlotTimestamp = DateFormatter.combineDateAndTime(
          date,
          timePart,
        );

        final bookedSlotData = {
          'barberId': barberId,
          'date': date,
          'time': timePart,
          'appointmentId': appointmentId,
          'startTimestamp': Timestamp.fromDate(subSlotTimestamp),
          'createdAt': FieldValue.serverTimestamp(),
        };
        transaction.set(slotDocRef, bookedSlotData);
      }
    });

    return appointmentId;
  }

  /// Thực thi TRANSACTION hủy lịch nguyên tử (Atomic Cancel Transaction) (Task 4.9)
  /// 1. Kiểm tra trạng thái hiện tại (chỉ được hủy pending hoặc confirmed)
  /// 2. Kiểm tra điều kiện thời gian (chỉ được hủy trước giờ hẹn tối thiểu 30 phút)
  /// 3. Cập nhật status thành 'cancelled'
  /// 4. Xóa tất cả các document trong bookedSlots để giải phóng khung giờ
  Future<void> cancelBooking({
    required String appointmentId,
    required String cancelledByUid,
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final appointmentRef = _firestore
          .collection('appointments')
          .doc(appointmentId);
      final appointmentSnapshot = await transaction.get(appointmentRef);

      if (!appointmentSnapshot.exists) {
        throw const CannotCancelException(
          'Lịch hẹn không tồn tại trên hệ thống!',
        );
      }

      final data = appointmentSnapshot.data()!;
      final currentStatus = data['status'] as String? ?? '';

      // Kiểm tra trạng thái hợp lệ
      if (currentStatus != 'pending' && currentStatus != 'confirmed') {
        throw CannotCancelException(
          'Không thể hủy lịch hẹn đã ở trạng thái "$currentStatus"!',
        );
      }

      // Kiểm tra thời gian: phải hủy trước ít nhất 30 phút
      final rawStartTimestamp = data['startTimestamp'];
      final DateTime startTimestamp;
      if (rawStartTimestamp is Timestamp) {
        startTimestamp = rawStartTimestamp.toDate();
      } else if (rawStartTimestamp is String) {
        startTimestamp = DateTime.tryParse(rawStartTimestamp) ?? now;
      } else {
        startTimestamp = now;
      }

      final cancelCutoff = startTimestamp.subtract(
        const Duration(minutes: BusinessConstants.leadTimeMinutes),
      );
      if (now.isAfter(cancelCutoff)) {
        throw const CannotCancelException(
          'Chỉ được hủy lịch trước giờ hẹn ít nhất 30 phút!',
        );
      }

      // Cập nhật trạng thái lịch hẹn
      transaction.update(appointmentRef, {
        'status': AppointmentStatus.cancelled.toStatusString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Xóa toàn bộ bookedSlots liên kết để giải phóng slot
      final rawSlotIds = data['slotIds'] as List<dynamic>? ?? [];
      for (final slotId in rawSlotIds) {
        final slotDocRef = _firestore
            .collection('bookedSlots')
            .doc(slotId.toString());
        transaction.delete(slotDocRef);
      }
    });
  }
}
