// ============================================================================
// File: lib/routing/app_router.dart
// Mục đích: Cấu hình điều hướng (Routing) của ứng dụng.
// Kết cấu:
//  - Sử dụng GoRouter để định nghĩa các đường dẫn (routes) và logic bảo vệ (guards).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_consult/presentation/ai_consult_screen.dart';
import '../features/ai_consult/presentation/ai_result_screen.dart';
import '../features/ai_consult/presentation/ai_spike_test_screen.dart';
import '../features/ai_consult/presentation/manual_select_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/presentation/customer_home_screen.dart';
import '../features/search_map/presentation/search_map_screen.dart';
import '../features/search_map/presentation/barber_detail_screen.dart';
import '../features/admin/presentation/approve_barbers_screen.dart';
import '../features/appointments/presentation/barber_appointments_screen.dart';
import '../features/appointments/presentation/customer_appointments_screen.dart';
import '../features/barber_profile/presentation/barber_pending_screen.dart';
import '../features/barber_profile/presentation/barber_registration_screen.dart';
import '../features/barber_profile/presentation/barber_edit_screen.dart';
import '../features/booking/presentation/booking_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../providers/auth_provider.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) {
        return null; // Đang tải
      }

      final user = authState.value;
      final isAuth = user != null;
      final loc = state.uri.toString();

      final isPublicRoute =
          loc == '/splash' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/spike-test';

      // 1. Chưa đăng nhập mà truy cập route riêng tư -> về /login
      if (!isAuth && !isPublicRoute) {
        return '/login';
      }

      // 2. Tài khoản bị khóa (isBlocked) -> buộc về /login
      if (isAuth && user.isBlocked) {
        return '/login';
      }

      final isAuthFormRoute =
          loc == '/login' || loc == '/register' || loc == '/forgot-password';

      // 3. Đã đăng nhập mà còn ở trang login/register thì điều hướng về role shell
      if (isAuth && isAuthFormRoute) {
        if (user.isAdmin) {
          return '/admin/approve-barbers';
        } else if (user.isBarber) {
          return '/barber/pending';
        } else {
          return '/customer/home';
        }
      }

      // 4. Role Guard: Phân quyền điều hướng theo vai trò (Task 2.7)
      if (isAuth) {
        if (loc.startsWith('/admin') && !user.isAdmin) {
          return user.isBarber ? '/barber/pending' : '/customer/home';
        }
        if (loc.startsWith('/barber') && !user.isBarber) {
          return user.isAdmin ? '/admin/approve-barbers' : '/customer/home';
        }
        if (loc.startsWith('/customer') && !user.isCustomer) {
          // Cho phép thợ và admin xem trang hồ sơ tiệm công khai (/customer/barber/:barberId)
          if (loc.startsWith('/customer/barber/')) {
            return null;
          }
          return user.isAdmin ? '/admin/approve-barbers' : '/barber/pending';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // --- CUSTOMER SHELL ---
      GoRoute(
        path: '/customer/home',
        name: 'customer_home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/search',
        name: 'customer_search',
        builder: (context, state) => SearchMapScreen(
          initialHairstyleId: state.uri.queryParameters['hairstyleId'],
        ),
      ),
      GoRoute(
        path: '/customer/barber/:barberId',
        name: 'barber_detail',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId'] ?? '';
          return BarberDetailScreen(barberId: barberId);
        },
      ),
      GoRoute(
        path: '/customer/booking/:barberId',
        name: 'customer_booking',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId'] ?? '';
          final serviceId = state.uri.queryParameters['serviceId'];
          final hairstyleId = state.uri.queryParameters['hairstyleId'];
          return BookingScreen(
            barberId: barberId,
            preselectedServiceId: serviceId,
            hairstyleId: hairstyleId,
          );
        },
      ),
      GoRoute(
        path: '/customer/appointments',
        name: 'customer_appointments',
        builder: (context, state) => const CustomerAppointmentsScreen(),
      ),
      GoRoute(
        path: '/customer/ai-consult',
        name: 'customer_ai_consult',
        builder: (context, state) => const AIConsultScreen(),
      ),
      GoRoute(
        path: '/customer/ai-result',
        name: 'customer_ai_result',
        builder: (context, state) => const AIResultScreen(),
      ),
      GoRoute(
        path: '/customer/manual-select',
        name: 'customer_manual_select',
        builder: (context, state) => const ManualSelectScreen(),
      ),
      GoRoute(
        path: '/customer/profile',
        name: 'customer_profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/customer/profile-edit',
        name: 'customer_profile_edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // --- BARBER SHELL ---
      GoRoute(
        path: '/barber/appointments',
        name: 'barber_appointments',
        builder: (context, state) => const BarberAppointmentsScreen(),
      ),
      GoRoute(
        path: '/barber/pending',
        name: 'barber_pending',
        builder: (context, state) => const BarberPendingScreen(),
      ),
      GoRoute(
        path: '/barber/profile-setup',
        name: 'barber_profile_setup',
        builder: (context, state) => const BarberRegistrationScreen(),
      ),
      GoRoute(
        path: '/barber/profile-edit',
        name: 'barber_profile_edit',
        builder: (context, state) => const BarberEditScreen(),
      ),
      GoRoute(
        path: '/barber/profile',
        name: 'barber_profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/barber/profile-edit-user',
        name: 'barber_profile_edit_user',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // --- ADMIN SHELL ---
      GoRoute(
        path: '/admin/approve-barbers',
        name: 'admin_approve_barbers',
        builder: (context, state) => const ApproveBarbersScreen(),
      ),
      // --- CHAT 1:1 ---
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final otherUserId = state.uri.queryParameters['otherUserId'] ?? '';
          final otherUserName =
              state.uri.queryParameters['otherUserName'] ?? 'Người dùng';
          final customerId = state.uri.queryParameters['customerId'] ?? '';
          final customerName = state.uri.queryParameters['customerName'] ?? '';
          final barberId = state.uri.queryParameters['barberId'] ?? '';
          final barberName = state.uri.queryParameters['barberName'] ?? '';

          return ChatScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            customerId: customerId,
            customerName: customerName,
            barberId: barberId,
            barberName: barberName,
          );
        },
      ),
      // --- TEST ---
      GoRoute(
        path: '/spike-test',
        name: 'spike_test',
        builder: (context, state) => const AISpikeTestScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy đường dẫn: ${state.uri}')),
    ),
  );
});
