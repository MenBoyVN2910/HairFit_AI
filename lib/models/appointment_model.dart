// ============================================================================
// File: lib/models/appointment_model.dart
// Mục đích: Định nghĩa cấu trúc dữ liệu (appointment_model).
// Kết cấu:
//  - Lớp mô hình (Model) bao gồm các thuộc tính và phương thức chuyển đổi (toMap, fromMap, copyWith).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rejected;

  static AppointmentStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'pending':
      default:
        return AppointmentStatus.pending;
    }
  }

  String toStatusString() {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.rejected:
        return 'rejected';
    }
  }
}

/// Mô hình lịch hẹn cắt tóc (appointments/{appointmentId})
class AppointmentModel {
  final String id;
  final String customerId;
  final String barberId;
  final String barberName;
  final String customerName;
  final String serviceId;
  final String serviceName;
  final int price;
  final int durationMinutes;
  final String date; // "yyyy-MM-dd"
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final DateTime startTimestamp;
  final DateTime endTimestamp;
  final String timezone;
  final List<String> slotIds;
  final String hairstyleId;
  final String note;
  final AppointmentStatus status;
  final int? rating;
  final String? reviewComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.customerId,
    required this.barberId,
    required this.barberName,
    required this.customerName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.startTimestamp,
    required this.endTimestamp,
    this.timezone = 'Asia/Ho_Chi_Minh',
    required this.slotIds,
    this.hairstyleId = '',
    this.note = '',
    this.status = AppointmentStatus.pending,
    this.rating,
    this.reviewComment,
    this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseTimestamp(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();

    return AppointmentModel(
      id: id ?? map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      barberId: map['barberId'] as String? ?? '',
      barberName: map['barberName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      serviceId: map['serviceId'] as String? ?? '',
      serviceName: map['serviceName'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
      date: map['date'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      startTimestamp: parseTimestamp(map['startTimestamp'], now),
      endTimestamp: parseTimestamp(
        map['endTimestamp'],
        now.add(const Duration(minutes: 30)),
      ),
      timezone: map['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      slotIds:
          (map['slotIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hairstyleId: map['hairstyleId'] as String? ?? '',
      note: map['note'] as String? ?? '',
      status: AppointmentStatus.fromString(map['status'] as String?),
      rating: (map['rating'] as num?)?.toInt(),
      reviewComment: map['reviewComment'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory AppointmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AppointmentModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'barberId': barberId,
      'barberName': barberName,
      'customerName': customerName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'durationMinutes': durationMinutes,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'startTimestamp': Timestamp.fromDate(startTimestamp),
      'endTimestamp': Timestamp.fromDate(endTimestamp),
      'timezone': timezone,
      'slotIds': slotIds,
      'hairstyleId': hairstyleId,
      'note': note,
      'status': status.toStatusString(),
      if (rating != null) 'rating': rating,
      if (reviewComment != null) 'reviewComment': reviewComment,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? barberId,
    String? barberName,
    String? customerName,
    String? serviceId,
    String? serviceName,
    int? price,
    int? durationMinutes,
    String? date,
    String? startTime,
    String? endTime,
    DateTime? startTimestamp,
    DateTime? endTimestamp,
    String? timezone,
    List<String>? slotIds,
    String? hairstyleId,
    String? note,
    AppointmentStatus? status,
    int? rating,
    String? reviewComment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      customerName: customerName ?? this.customerName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      timezone: timezone ?? this.timezone,
      slotIds: slotIds ?? this.slotIds,
      hairstyleId: hairstyleId ?? this.hairstyleId,
      note: note ?? this.note,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isRejected => status == AppointmentStatus.rejected;

  /// Kiểm tra xem khách có thể hủy lịch này không
  /// Điều kiện: Trạng thái là pending hoặc confirmed, và thời điểm hủy trước giờ bắt đầu ít nhất 30 phút
  bool canCustomerCancel() {
    if (status != AppointmentStatus.pending &&
        status != AppointmentStatus.confirmed) {
      return false;
    }
    final leadTimeCutoff = startTimestamp.subtract(const Duration(minutes: 30));
    return DateTime.now().isBefore(leadTimeCutoff);
  }
}
