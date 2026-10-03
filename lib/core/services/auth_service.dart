// ============================================================================
// File: lib/core/services/auth_service.dart
// Mục đích: Cung cấp dịch vụ hạ tầng (auth).
// Kết cấu:
//  - Lớp Service xử lý giao tiếp với các hệ thống bên ngoài hoặc phần cứng (Firebase, Location, API).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';

/// Exception khi tài khoản bị khóa
class BlockedAccountException implements Exception {
  final String message;
  const BlockedAccountException([
    this.message =
        'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.',
  ]);

  @override
  String toString() => message;
}

/// Exception chung cho Auth với thông báo thân thiện bằng tiếng Việt
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Service xử lý xác thực người dùng bằng Firebase Auth và Cloud Firestore (Task 2.1)
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream theo dõi trạng thái Authentication của Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// User hiện tại từ Firebase Auth
  User? get currentAuthUser => _firebaseAuth.currentUser;

  /// Đăng ký tài khoản mới bằng Email/Password (UC-01)
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      debugPrint(
        '🔑 [AuthService] Bắt đầu đăng ký: $email, role: ${role.toRoleString()}',
      );

      // 1. Tạo tài khoản trong Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Đăng ký không thành công. Vui lòng thử lại.',
        );
      }

      // 2. Cập nhật Display Name trong Firebase Auth
      await firebaseUser.updateDisplayName(displayName.trim());

      // 3. Khởi tạo Document users/{uid} trong Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        avatarUrl: '',
        role: role,
        isBlocked: false,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toMap());

      debugPrint(
        '✅ [AuthService] Đăng ký thành công và đã tạo Firestore user: ${firebaseUser.uid}',
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}',
      );
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('❌ [AuthService] Lỗi không xác định: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  /// Đăng nhập tài khoản bằng Email/Password (UC-01)
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 [AuthService] Đăng nhập: $email');

      // 1. Xác thực qua Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      // 2. Lấy dữ liệu user profile từ Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Trường hợp tài khoản auth tồn tại nhưng chưa có doc (hoặc admin tạo sẵn)
        debugPrint(
          '⚠️ [AuthService] Doc user chưa tồn tại, tự động đồng bộ...',
        );
        final defaultUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email.trim(),
          displayName: firebaseUser.displayName ?? email.split('@').first,
          role: UserRole.customer,
          isBlocked: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(defaultUser.toMap());
        return defaultUser;
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // 3. Kiểm tra tài khoản có bị khóa không (isBlocked)
      if (userModel.isBlocked) {
        debugPrint(
          '🚫 [AuthService] Tài khoản ${userModel.uid} bị khóa. Buộc đăng xuất.',
        );
        await _firebaseAuth.signOut();
        throw const BlockedAccountException();
      }

      debugPrint(
        '✅ [AuthService] Đăng nhập thành công: ${userModel.displayName} (${userModel.role.toRoleString()})',
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}',
      );
      throw AuthException(_mapFirebaseError(e));
    } on BlockedAccountException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] Login error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  /// Lấy thông tin UserModel hiện tại từ Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final authUser = _firebaseAuth.currentUser;
    if (authUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();
      if (!doc.exists) return null;

      final userModel = UserModel.fromFirestore(doc);
      if (userModel.isBlocked) {
        await _firebaseAuth.signOut();
        throw const BlockedAccountException();
      }

      return userModel;
    } catch (e) {
      debugPrint('⚠️ [AuthService] Lỗi khi lấy thông tin user: $e');
      return null;
    }
  }

  /// Gửi email đặt lại mật khẩu (UC-01)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 [AuthService] Gửi email reset password tới: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ [AuthService] Đã gửi email reset password');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] sendPasswordResetEmail error: ${e.code}');
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      throw AuthException('Không thể gửi yêu cầu đặt lại mật khẩu: $e');
    }
  }

  /// Cập nhật thông tin hồ sơ người dùng (displayName, avatarUrl)
  Future<UserModel> updateUserProfile({
    required String uid,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      debugPrint('👤 [AuthService] Cập nhật thông tin hồ sơ: $displayName');
      final updates = <String, dynamic>{
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl.trim();
      }

      await _firestore.collection('users').doc(uid).update(updates);

      // Cập nhật Firebase Auth nếu người dùng hiện tại trùng uid
      final authUser = _firebaseAuth.currentUser;
      if (authUser != null && authUser.uid == uid) {
        await authUser.updateDisplayName(displayName.trim());
      }

      // Đồng bộ sang barberProfiles nếu tồn tại profile của thợ
      try {
        final barberDoc =
            await _firestore.collection('barberProfiles').doc(uid).get();
        if (barberDoc.exists) {
          final barberUpdates = <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (avatarUrl != null) {
            barberUpdates['avatarUrl'] = avatarUrl.trim();
          }
          if (displayName.trim().isNotEmpty) {
            barberUpdates['displayName'] = displayName.trim();
          }
          await _firestore
              .collection('barberProfiles')
              .doc(uid)
              .update(barberUpdates);
          debugPrint('💈 [AuthService] Đã đồng bộ sang barberProfiles/$uid');
        }
      } catch (err) {
        debugPrint('⚠️ [AuthService] Không thể đồng bộ sang barberProfiles: $err');
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [AuthService] Lỗi cập nhật profile: $e');
      throw AuthException('Không thể cập nhật thông tin: $e');
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    debugPrint('👋 [AuthService] Đăng xuất');
    await _firebaseAuth.signOut();
  }

  /// Chuyển đổi mã lỗi Firebase Auth sang thông báo tiếng Việt dễ hiểu
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      case 'email-already-in-use':
        return 'Địa chỉ email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu có ít nhất 6 ký tự.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Bạn đã thao tác sai quá nhiều lần. Vui lòng đợi trong giây lát và thử lại.';
      case 'network-request-failed':
        return 'Không thể kết nối Internet. Vui lòng kiểm tra kết nối mạng của bạn.';
      case 'operation-not-allowed':
        return 'Tính năng đăng nhập bằng email chưa được bật trên Firebase. Vui lòng bật Email/Password trong Firebase Console.';
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực. Vui lòng thử lại sau.';
    }
  }
}
