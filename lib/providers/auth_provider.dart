// ============================================================================
// File: lib/providers/auth_provider.dart
// Mục đích: Quản lý trạng thái (State Management) cho auth.
// Kết cấu:
//  - Sử dụng Riverpod (Notifier/StateNotifier/Provider) để cung cấp trạng thái và xử lý logic nghiệp vụ.
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../models/user_model.dart';
import 'app_providers.dart';

/// Provider cung cấp instance AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(firebaseAuth: firebaseAuth, firestore: firestore);
});

/// Provider cung cấp instance AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService: authService);
});

/// AsyncNotifier quản lý trạng thái tài khoản người dùng theo Riverpod 2.x (Task 2.2)
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    final authService = ref.watch(authServiceProvider);
    return await authService.getCurrentUserModel();
  }

  /// Đăng nhập tài khoản
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(email: email, password: password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordReset(String email) async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.sendPasswordResetEmail(email);
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cập nhật thông tin hồ sơ người dùng
  Future<UserModel> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) {
      throw const AuthException('Người dùng chưa đăng nhập');
    }

    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final updatedUser = await authRepo.updateUserProfile(
        uid: currentUser.uid,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(updatedUser);
      return updatedUser;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Tải lại thông tin người dùng từ Firestore
  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      return await authRepo.getCurrentUser();
    });
  }
}

/// Provider toàn cục cho Auth State
final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});
