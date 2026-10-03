// ============================================================================
// File: lib/models/hairstyle_model.dart
// Mục đích: Định nghĩa cấu trúc dữ liệu (hairstyle_model).
// Kết cấu:
//  - Lớp mô hình (Model) bao gồm các thuộc tính và phương thức chuyển đổi (toMap, fromMap, copyWith).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình kiểu tóc trong danh mục chuẩn (hairstyleCatalog/{styleId})
class HairstyleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final List<String> faceShapes; // "oval", "round", "square", "heart", "oblong"
  final List<String> tags;
  final bool active;

  const HairstyleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.faceShapes,
    required this.tags,
    this.active = true,
  });

  /// Danh sách ảnh minh họa kiểu tóc (tối đa 5 ảnh)
  List<String> get displayImages {
    if (imageUrls.isNotEmpty) {
      return imageUrls.take(5).toList();
    }
    if (imageUrl.isNotEmpty) {
      return [imageUrl];
    }
    return [];
  }

  factory HairstyleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawImgs =
        (map['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    final singleImg = map['imageUrl'] as String? ?? '';
    final combinedImgs = rawImgs.isNotEmpty
        ? rawImgs
        : (singleImg.isNotEmpty ? [singleImg] : <String>[]);

    return HairstyleModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: singleImg.isNotEmpty
          ? singleImg
          : (combinedImgs.isNotEmpty ? combinedImgs.first : ''),
      imageUrls: combinedImgs.take(5).toList(),
      faceShapes:
          (map['faceShapes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      active: map['active'] as bool? ?? true,
    );
  }

  factory HairstyleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return HairstyleModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl.isNotEmpty
          ? imageUrl
          : (imageUrls.isNotEmpty ? imageUrls.first : ''),
      'imageUrls': imageUrls.isNotEmpty
          ? imageUrls.take(5).toList()
          : (imageUrl.isNotEmpty ? [imageUrl] : []),
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
    List<String>? imageUrls,
    List<String>? faceShapes,
    List<String>? tags,
    bool? active,
  }) {
    return HairstyleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
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
