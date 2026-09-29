import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình slot thời gian đã đặt (bookedSlots/{slotId})
/// Dùng để chống trùng lịch bằng Firestore Transaction
class BookedSlotModel {
  final String id; // Format: "{barberId}_{yyyy-MM-dd}_{HH-mm}"
  final String barberId;
  final String date; // "yyyy-MM-dd"
  final String time; // "HH:mm"
  final String appointmentId;
  final DateTime startTimestamp;
  final DateTime? createdAt;

  const BookedSlotModel({
    required this.id,
    required this.barberId,
    required this.date,
    required this.time,
    required this.appointmentId,
    required this.startTimestamp,
    this.createdAt,
  });

  /// Hàm tạo mã slotId chuẩn theo định dạng quy định
  /// Ví dụ: barberId="barber_456", date="2026-10-10", time="09:00" -> "barber_456_2026-10-10_09-00"
  static String generateSlotId({
    required String barberId,
    required String date,
    required String time,
  }) {
    final sanitizedTime = time.replaceAll(':', '-');
    return '${barberId}_${date}_$sanitizedTime';
  }

  factory BookedSlotModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return BookedSlotModel(
      id: id ?? map['id'] as String? ?? '',
      barberId: map['barberId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      appointmentId: map['appointmentId'] as String? ?? '',
      startTimestamp: parseTimestamp(map['startTimestamp']),
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  factory BookedSlotModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BookedSlotModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'barberId': barberId,
      'date': date,
      'time': time,
      'appointmentId': appointmentId,
      'startTimestamp': Timestamp.fromDate(startTimestamp),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
