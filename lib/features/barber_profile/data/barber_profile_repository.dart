import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/barber_profile_model.dart';
import '../../../providers/app_providers.dart';

final barberProfileRepositoryProvider = Provider<BarberProfileRepository>((ref) {
  return BarberProfileRepository(ref.watch(firestoreProvider));
});

final barberProfileProvider = FutureProvider.family<BarberProfileModel?, String>((ref, uid) async {
  return ref.watch(barberProfileRepositoryProvider).getBarberProfile(uid);
});

class BarberProfileRepository {
  final FirebaseFirestore _firestore;

  BarberProfileRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('barberProfiles');

  Future<BarberProfileModel?> getBarberProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return BarberProfileModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<void> createOrUpdateProfile(BarberProfileModel profile) async {
    await _collection.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<List<BarberProfileModel>> getPendingBarbers() async {
    final snapshot = await _collection.where('approvalStatus', isEqualTo: 'pending').get();
    return snapshot.docs.map((doc) => BarberProfileModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  Future<void> updateApprovalStatus(String uid, String status) async {
    await _collection.doc(uid).update({
      'approvalStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
