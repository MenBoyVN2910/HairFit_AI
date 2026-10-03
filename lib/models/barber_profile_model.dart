// ============================================================================
// File: lib/models/barber_profile_model.dart
// Mục đích: Định nghĩa cấu trúc dữ liệu (barber_profile_model).
// Kết cấu:
//  - Lớp mô hình (Model) bao gồm các thuộc tính và phương thức chuyển đổi (toMap, fromMap, copyWith).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'service_model.dart';

/// Toạ độ địa lý vị trí tiệm thợ
class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation({required this.latitude, required this.longitude});

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

/// Giờ làm việc trong 1 ngày
class DayWorkingHours {
  final bool closed;
  final String open; // "HH:mm" ví dụ: "09:00"
  final String close; // "HH:mm" ví dụ: "19:00"

  const DayWorkingHours({
    required this.closed,
    required this.open,
    required this.close,
  });

  factory DayWorkingHours.fromMap(Map<String, dynamic> map) {
    return DayWorkingHours(
      closed: map['closed'] as bool? ?? false,
      open: map['open'] as String? ?? '09:00',
      close: map['close'] as String? ?? '19:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {'closed': closed, 'open': open, 'close': close};
  }
}

/// Ngày nghỉ ngoại lệ của thợ
class WorkException {
  final String date; // "yyyy-MM-dd"
  final bool closed;
  final String reason;

  const WorkException({
    required this.date,
    required this.closed,
    required this.reason,
  });

  factory WorkException.fromMap(Map<String, dynamic> map) {
    return WorkException(
      date: map['date'] as String? ?? '',
      closed: map['closed'] as bool? ?? true,
      reason: map['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date, 'closed': closed, 'reason': reason};
  }
}

/// Mô hình hồ sơ thợ cắt tóc (barberProfiles/{uid})
class BarberProfileModel {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String address;
  final GeoLocation location;
  final int priceMin;
  final int priceMax;
  final double ratingAvg;
  final int ratingCount;
  final String approvalStatus; // "pending" | "approved" | "rejected"
  final List<String> hairstyleIds;
  final List<ServiceModel> services;
  final Map<String, DayWorkingHours>
  workingHours; // mon, tue, wed, thu, fri, sat, sun
  final List<WorkException> exceptions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BarberProfileModel({
    required this.uid,
    required this.displayName,
    this.avatarUrl = '',
    this.coverUrl = '',
    this.bio = '',
    required this.address,
    required this.location,
    this.priceMin = 0,
    this.priceMax = 0,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.approvalStatus = 'pending',
    this.hairstyleIds = const [],
    this.services = const [],
    this.workingHours = const {},
    this.exceptions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BarberProfileModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawServices = map['services'] as List<dynamic>? ?? [];
    final parsedServices = rawServices
        .map((e) => ServiceModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawWorkingHours = map['workingHours'] as Map<String, dynamic>? ?? {};
    final parsedWorkingHours = rawWorkingHours.map(
      (key, val) => MapEntry(
        key,
        DayWorkingHours.fromMap(Map<String, dynamic>.from(val as Map)),
      ),
    );

    final rawExceptions = map['exceptions'] as List<dynamic>? ?? [];
    final parsedExceptions = rawExceptions
        .map((e) => WorkException.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Tự động tính priceMin và priceMax nếu không có hoặc cần cập nhật
    int pMin = (map['priceMin'] as num?)?.toInt() ?? 0;
    int pMax = (map['priceMax'] as num?)?.toInt() ?? 0;
    if (parsedServices.isNotEmpty && (pMin == 0 && pMax == 0)) {
      final activePrices = parsedServices
          .where((s) => s.active)
          .map((s) => s.price)
          .toList();
      if (activePrices.isNotEmpty) {
        pMin = activePrices.reduce((a, b) => a < b ? a : b);
        pMax = activePrices.reduce((a, b) => a > b ? a : b);
      }
    }

    return BarberProfileModel(
      uid: id ?? map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      address: map['address'] as String? ?? '',
      location: GeoLocation.fromMap(
        Map<String, dynamic>.from(map['location'] as Map? ?? {}),
      ),
      priceMin: pMin,
      priceMax: pMax,
      ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      approvalStatus: map['approvalStatus'] as String? ?? 'pending',
      hairstyleIds:
          (map['hairstyleIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      services: parsedServices,
      workingHours: parsedWorkingHours,
      exceptions: parsedExceptions,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  factory BarberProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BarberProfileModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    int calculatedMin = 0;
    int calculatedMax = 0;
    final activePrices = services
        .where((s) => s.active)
        .map((s) => s.price)
        .toList();
    if (activePrices.isNotEmpty) {
      calculatedMin = activePrices.reduce((a, b) => a < b ? a : b);
      calculatedMax = activePrices.reduce((a, b) => a > b ? a : b);
    }

    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'address': address,
      'location': location.toMap(),
      'priceMin': calculatedMin > 0 ? calculatedMin : priceMin,
      'priceMax': calculatedMax > 0 ? calculatedMax : priceMax,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'approvalStatus': approvalStatus,
      'hairstyleIds': hairstyleIds,
      'services': services.map((s) => s.toMap()).toList(),
      'workingHours': workingHours.map((k, v) => MapEntry(k, v.toMap())),
      'exceptions': exceptions.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';

  BarberProfileModel copyWith({
    String? uid,
    String? displayName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? address,
    GeoLocation? location,
    int? priceMin,
    int? priceMax,
    double? ratingAvg,
    int? ratingCount,
    String? approvalStatus,
    List<String>? hairstyleIds,
    List<ServiceModel>? services,
    Map<String, DayWorkingHours>? workingHours,
    List<WorkException>? exceptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarberProfileModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      location: location ?? this.location,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      hairstyleIds: hairstyleIds ?? this.hairstyleIds,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      exceptions: exceptions ?? this.exceptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
