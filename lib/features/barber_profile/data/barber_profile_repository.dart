// ============================================================================
// File: lib/features/barber_profile/data/barber_profile_repository.dart
// Mục đích: Quản lý dữ liệu (Repository) cho tính năng barber_profile.
// Kết cấu:
//  - Tương tác với cơ sở dữ liệu (Firestore) hoặc API, cung cấp CRUD operations.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/barber_profile_model.dart';
import '../../../providers/app_providers.dart';

final barberProfileRepositoryProvider = Provider<BarberProfileRepository>((
  ref,
) {
  return BarberProfileRepository(ref.watch(firestoreProvider));
});

final barberProfileProvider =
    FutureProvider.family<BarberProfileModel?, String>((ref, uid) async {
      return ref.watch(barberProfileRepositoryProvider).getBarberProfile(uid);
    });

class BarberProfileRepository {
  final FirebaseFirestore _firestore;

  BarberProfileRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('barberProfiles');

  Future<BarberProfileModel?> getBarberProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    var profile = BarberProfileModel.fromMap(doc.data()!, id: doc.id);
    if (profile.avatarUrl.trim().isEmpty) {
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userAvatar = userDoc.data()?['avatarUrl'] as String? ?? '';
          if (userAvatar.trim().isNotEmpty) {
            profile = profile.copyWith(avatarUrl: userAvatar.trim());
            _collection
                .doc(uid)
                .update({'avatarUrl': userAvatar.trim()})
                .catchError((_) {});
          }
        }
      } catch (_) {}
    }
    return profile;
  }

  Future<void> createOrUpdateProfile(BarberProfileModel profile) async {
    await _collection
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));

    // Đồng bộ avatar và displayName sang collection users
    try {
      final userUpdates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (profile.avatarUrl.trim().isNotEmpty) {
        userUpdates['avatarUrl'] = profile.avatarUrl.trim();
      }
      if (profile.displayName.trim().isNotEmpty) {
        userUpdates['displayName'] = profile.displayName.trim();
      }
      if (userUpdates.length > 1) {
        await _firestore
            .collection('users')
            .doc(profile.uid)
            .update(userUpdates);
      }
    } catch (_) {}
  }

  Future<List<BarberProfileModel>> getPendingBarbers() async {
    final snapshot = await _collection
        .where('approvalStatus', isEqualTo: 'pending')
        .get();
    final list = <BarberProfileModel>[];
    for (final doc in snapshot.docs) {
      var item = BarberProfileModel.fromMap(doc.data(), id: doc.id);
      if (item.avatarUrl.trim().isEmpty) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final userAvatar =
                userDoc.data()?['avatarUrl'] as String? ?? '';
            if (userAvatar.trim().isNotEmpty) {
              item = item.copyWith(avatarUrl: userAvatar.trim());
              _collection
                  .doc(doc.id)
                  .update({'avatarUrl': userAvatar.trim()})
                  .catchError((_) {});
            }
          }
        } catch (_) {}
      }
      list.add(item);
    }
    return list;
  }

  Future<void> updateApprovalStatus(String uid, String status) async {
    await _collection.doc(uid).update({
      'approvalStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
