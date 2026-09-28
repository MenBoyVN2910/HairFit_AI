/// Mô hình dịch vụ của thợ cắt tóc
class ServiceModel {
  final String id;
  final String name;
  final int price; // Giá tính bằng VNĐ
  final int durationMinutes; // Thời lượng, phải là bội số của 30 (30, 60, 90, ...)
  final bool active;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.active = true,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
      'active': active,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    int? price,
    int? durationMinutes,
    bool? active,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      active: active ?? this.active,
    );
  }

  /// Số slot 30 phút mà dịch vụ này chiếm giữ
  int get slotCount => (durationMinutes / 30).ceil();
}
