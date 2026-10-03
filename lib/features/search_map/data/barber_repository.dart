// ============================================================================
// File: lib/features/search_map/data/barber_repository.dart
// Mục đích: Quản lý dữ liệu (Repository) cho tính năng search_map.
// Kết cấu:
//  - Tương tác với cơ sở dữ liệu (Firestore) hoặc API, cung cấp CRUD operations.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barber_profile_model.dart';
import '../../../providers/app_providers.dart';

/// Provider cung cấp BarberRepository cho tính năng tìm kiếm và bản đồ (Task 3.2)
final barberRepositoryProvider = Provider<BarberRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return BarberRepository(firestore: firestore);
});

/// FutureProvider lấy danh sách toàn bộ thợ đã được duyệt (approved)
final approvedBarbersProvider = FutureProvider<List<BarberProfileModel>>((
  ref,
) async {
  final repo = ref.watch(barberRepositoryProvider);
  return await repo.getApprovedBarbers();
});

/// StreamProvider theo dõi danh sách thợ approved theo thời gian thực
final approvedBarbersStreamProvider = StreamProvider<List<BarberProfileModel>>((
  ref,
) {
  final repo = ref.watch(barberRepositoryProvider);
  return repo.streamApprovedBarbers();
});

/// FutureProvider.family lấy chi tiết một thợ cắt tóc theo UID
final barberDetailProvider = FutureProvider.family<BarberProfileModel?, String>(
  (ref, barberId) async {
    final repo = ref.watch(barberRepositoryProvider);
    return await repo.getBarberById(barberId);
  },
);

/// StreamProvider lấy danh sách đánh giá của thợ theo barberId
final barberReviewsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, barberId) {
  final repo = ref.watch(barberRepositoryProvider);
  return repo.streamReviewsForBarber(barberId);
});

/// Repository quản lý truy vấn thông tin thợ đã duyệt (Task 3.2)
class BarberRepository {
  final FirebaseFirestore _firestore;

  BarberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('barberProfiles');

  Future<BarberProfileModel> _resolveAvatarIfEmpty(
    BarberProfileModel barber,
  ) async {
    if (barber.avatarUrl.trim().isNotEmpty) return barber;

    try {
      final userDoc =
          await _firestore.collection('users').doc(barber.uid).get();
      if (userDoc.exists) {
        final userAvatar = userDoc.data()?['avatarUrl'] as String? ?? '';
        if (userAvatar.trim().isNotEmpty) {
          final updated = barber.copyWith(avatarUrl: userAvatar.trim());
          _collection
              .doc(barber.uid)
              .update({'avatarUrl': userAvatar.trim()})
              .catchError((_) {});
          return updated;
        }
      }
    } catch (_) {}

    return barber;
  }

  /// Truy vấn tất cả các thợ có trạng thái approvalStatus == "approved"
  Future<List<BarberProfileModel>> getApprovedBarbers() async {
    try {
      final snapshot = await _collection
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final list = <BarberProfileModel>[];
      for (final doc in snapshot.docs) {
        final initial =
            BarberProfileModel.fromMap(doc.data(), id: doc.id);
        list.add(await _resolveAvatarIfEmpty(initial));
      }
      return list;
    } catch (e) {
      debugPrint('⚠️ [BarberRepository] Lỗi tải danh sách thợ approved: $e');
      rethrow;
    }
  }

  /// Lắng nghe stream các thợ có trạng thái approved theo thời gian thực
  Stream<List<BarberProfileModel>> streamApprovedBarbers() {
    return _collection
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .asyncMap(
          (snapshot) async {
            final list = <BarberProfileModel>[];
            for (final doc in snapshot.docs) {
              final initial =
                  BarberProfileModel.fromMap(doc.data(), id: doc.id);
              list.add(await _resolveAvatarIfEmpty(initial));
            }
            return list;
          },
        );
  }

  /// Lấy thông tin chi tiết một thợ cắt tóc theo UID
  Future<BarberProfileModel?> getBarberById(String uid) async {
    try {
      final doc = await _collection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      final initial = BarberProfileModel.fromMap(doc.data()!, id: doc.id);
      return await _resolveAvatarIfEmpty(initial);
    } catch (e) {
      debugPrint('⚠️ [BarberRepository] Lỗi tải thông tin thợ ($uid): $e');
      return null;
    }
  }

  /// Lấy danh sách thợ nổi bật (sắp xếp theo ratingAvg giảm dần)
  Future<List<BarberProfileModel>> getFeaturedBarbers({int limit = 5}) async {
    try {
      final snapshot = await _collection
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('ratingAvg', descending: true)
          .limit(limit)
          .get();

      final list = <BarberProfileModel>[];
      for (final doc in snapshot.docs) {
        final initial =
            BarberProfileModel.fromMap(doc.data(), id: doc.id);
        list.add(await _resolveAvatarIfEmpty(initial));
      }
      return list;
    } catch (e) {
      debugPrint(
        '⚠️ [BarberRepository] Lỗi tải thợ nổi bật: $e. Fallback getApprovedBarbers.',
      );
      // Fallback nếu chưa tạo composite index trong Firestore
      final all = await getApprovedBarbers();
      all.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
      return all.take(limit).toList();
    }
  }

  /// Lắng nghe stream danh sách đánh giá của thợ theo thời gian thực
  Stream<List<Map<String, dynamic>>> streamReviewsForBarber(String barberId) {
    return _firestore
        .collection('reviews')
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => doc.data()).toList();
          list.sort((a, b) {
            final tA = a['createdAt'] as Timestamp?;
            final tB = b['createdAt'] as Timestamp?;
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });
          return list;
        });
  }
}
