import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/appointment_model.dart';
import '../../booking/data/booking_repository.dart';

/// Repository quản lý truy vấn và cập nhật trạng thái lịch hẹn (Tasks 4.9, 4.10, 4.13)
class AppointmentRepository {
  final FirebaseFirestore _firestore;
  final BookingRepository _bookingRepository;

  AppointmentRepository({
    FirebaseFirestore? firestore,
    BookingRepository? bookingRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _bookingRepository = bookingRepository ??
            BookingRepository(firestore: firestore ?? FirebaseFirestore.instance);

  /// Lắng nghe danh sách lịch hẹn của một khách hàng (real-time stream)
  /// Sắp xếp theo startTimestamp mới nhất lên đầu
  Stream<List<AppointmentModel>> streamCustomerAppointments(String customerId) {
    return _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();

          // Sắp xếp theo startTimestamp giảm dần
          list.sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));
          return list;
        });
  }

  /// Lắng nghe danh sách lịch hẹn của một thợ cắt tóc (real-time stream)
  /// Sắp xếp theo startTimestamp
  Stream<List<AppointmentModel>> streamBarberAppointments(String barberId) {
    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();

          // Sắp xếp theo startTimestamp giảm dần
          list.sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));
          return list;
        });
  }

  /// Lấy thông tin chi tiết một lịch hẹn bằng ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    final doc = await _firestore.collection('appointments').doc(appointmentId).get();
    if (!doc.exists) return null;
    return AppointmentModel.fromFirestore(doc);
  }

  /// Thợ xác nhận tiếp nhận lịch hẹn (pending -> confirmed)
  Future<void> confirmAppointment(String appointmentId) async {
    final docRef = _firestore.collection('appointments').doc(appointmentId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw const BookingException('Lịch hẹn không tồn tại');
    }

    final currentStatus = snapshot.data()?['status'] as String?;
    if (currentStatus != AppointmentStatus.pending.toStatusString()) {
      throw BookingException('Chỉ có thể xác nhận lịch hẹn ở trạng thái chờ duyệt');
    }

    await docRef.update({
      'status': AppointmentStatus.confirmed.toStatusString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Thợ từ chối lịch hẹn (pending -> rejected):
  /// Chuyển trạng thái sang rejected VÀ XÓA bookedSlots để giải phóng khung giờ
  Future<void> rejectAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
      final snapshot = await transaction.get(appointmentRef);

      if (!snapshot.exists) {
        throw const BookingException('Lịch hẹn không tồn tại');
      }

      final data = snapshot.data()!;
      final currentStatus = data['status'] as String?;
      if (currentStatus != AppointmentStatus.pending.toStatusString()) {
        throw BookingException('Chỉ có thể từ chối lịch hẹn ở trạng thái chờ duyệt');
      }

      // 1. Cập nhật trạng thái appointment
      transaction.update(appointmentRef, {
        'status': AppointmentStatus.rejected.toStatusString(),
        if (reason != null && reason.trim().isNotEmpty) 'rejectReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Xóa các bookedSlots tương ứng để giải phóng khung giờ
      final rawSlotIds = data['slotIds'] as List<dynamic>? ?? [];
      for (final slotId in rawSlotIds) {
        final slotDocRef = _firestore.collection('bookedSlots').doc(slotId.toString());
        transaction.delete(slotDocRef);
      }
    });
  }

  /// Thợ hoàn tất dịch vụ cắt tóc (confirmed -> completed)
  Future<void> completeAppointment(String appointmentId) async {
    final docRef = _firestore.collection('appointments').doc(appointmentId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw const BookingException('Lịch hẹn không tồn tại');
    }

    final currentStatus = snapshot.data()?['status'] as String?;
    if (currentStatus != AppointmentStatus.confirmed.toStatusString()) {
      throw BookingException('Chỉ có thể hoàn tất lịch hẹn đã được xác nhận');
    }

    await docRef.update({
      'status': AppointmentStatus.completed.toStatusString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Khách hàng hủy lịch hẹn (ủy thác qua BookingRepository transaction)
  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancelledByUid,
    DateTime? currentTime,
  }) async {
    await _bookingRepository.cancelBooking(
      appointmentId: appointmentId,
      cancelledByUid: cancelledByUid,
      currentTime: currentTime,
    );
  }
}
