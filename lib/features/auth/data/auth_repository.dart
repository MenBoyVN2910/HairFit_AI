import '../../../core/services/auth_service.dart';
import '../../../models/user_model.dart';

/// Repository quản lý nghiệp vụ Authentication
class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  Stream<UserModel?> get authStateChanges {
    return _authService.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      return await _authService.getCurrentUserModel();
    });
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) {
    return _authService.register(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  Future<UserModel?> getCurrentUser() {
    return _authService.getCurrentUserModel();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
