// ============================================================================
// File: lib/features/ai_consult/data/hairstyle_repository.dart
// Mục đích: Quản lý dữ liệu (Repository) cho tính năng ai_consult.
// Kết cấu:
//  - Tương tác với cơ sở dữ liệu (Firestore) hoặc API, cung cấp CRUD operations.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/hairstyle_model.dart';
import '../../../../providers/app_providers.dart';

final hairstyleRepositoryProvider = Provider<HairstyleRepository>((ref) {
  return HairstyleRepository(ref.watch(firestoreProvider));
});

final hairstylesProvider = FutureProvider<List<HairstyleModel>>((ref) {
  return ref.watch(hairstyleRepositoryProvider).getAllHairstyles();
});

class HairstyleRepository {
  final FirebaseFirestore _firestore;

  HairstyleRepository(this._firestore);

  Future<List<HairstyleModel>> getAllHairstyles() async {
    final snapshot = await _firestore
        .collection('hairstyleCatalog')
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => HairstyleModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }
}
