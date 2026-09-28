import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình kiểu tóc trong danh mục chuẩn (hairstyleCatalog/{styleId})
class HairstyleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> faceShapes; // "oval", "round", "square", "heart", "oblong"
  final List<String> tags;
  final bool active;

  const HairstyleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.faceShapes,
    required this.tags,
    this.active = true,
  });

  factory HairstyleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return HairstyleModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      faceShapes: (map['faceShapes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      active: map['active'] as bool? ?? true,
    );
  }

  factory HairstyleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return HairstyleModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'faceShapes': faceShapes,
      'tags': tags,
      'active': active,
    };
  }

  HairstyleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? faceShapes,
    List<String>? tags,
    bool? active,
  }) {
    return HairstyleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      faceShapes: faceShapes ?? this.faceShapes,
      tags: tags ?? this.tags,
      active: active ?? this.active,
    );
  }

  /// Kiểm tra xem kiểu tóc này có phù hợp với một dáng mặt cụ thể hay không
  bool matchesFaceShape(String shape) {
    return faceShapes.contains(shape.toLowerCase().trim());
  }
}
