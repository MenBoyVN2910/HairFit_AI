// ============================================================================
// File: lib/providers/app_providers.dart
// Mục đích: Quản lý trạng thái (State Management) cho app_providers.dart.
// Kết cấu:
//  - Sử dụng Riverpod (Notifier/StateNotifier/Provider) để cung cấp trạng thái và xử lý logic nghiệp vụ.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

/// Provider cung cấp FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider cung cấp FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider theo dõi trạng thái Authentication của người dùng
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider cung cấp thông tin tài khoản người dùng hiện tại từ Firestore
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return null;

  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('users').doc(authUser.uid).get();
  if (!doc.exists) return null;

  return UserModel.fromFirestore(doc);
});
