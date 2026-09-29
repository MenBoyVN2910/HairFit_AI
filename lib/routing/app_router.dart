import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/ai_consult/presentation/ai_spike_test_screen.dart';
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
import '../features/booking/presentation/booking_screen.dart';
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

      final isPublicRoute = loc == '/splash' ||
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

      final isAuthFormRoute = loc == '/login' || 
                             loc == '/register' || 
                             loc == '/forgot-password';

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
      // --- ADMIN SHELL ---
      GoRoute(
        path: '/admin/approve-barbers',
        name: 'admin_approve_barbers',
        builder: (context, state) => const ApproveBarbersScreen(),
      ),
      // --- TEST ---
      GoRoute(
        path: '/spike-test',
        name: 'spike_test',
        builder: (context, state) => const AISpikeTestScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Không tìm thấy đường dẫn: ${state.uri}'),
      ),
    ),
  );
});
