// ============================================================================
// File: lib/providers/appointment_provider.dart
// Mục đích: Quản lý trạng thái (State Management) cho appointment.
// Kết cấu:
//  - Sử dụng Riverpod (Notifier/StateNotifier/Provider) để cung cấp trạng thái và xử lý logic nghiệp vụ.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/data/appointment_repository.dart';
import '../models/appointment_model.dart';
import 'app_providers.dart';

import 'auth_provider.dart';

/// Provider cung cấp instance của AppointmentRepository
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AppointmentRepository(firestore: firestore);
});

/// StreamProvider lắng nghe danh sách lịch hẹn của khách hàng hiện tại
final customerAppointmentsProvider =
    StreamProvider.autoDispose<List<AppointmentModel>>((ref) {
      final authUser = ref.watch(authStateProvider).value;
      final uid =
          authUser?.uid ??
          ref.watch(currentUserModelProvider).value?.uid ??
          ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return const Stream.empty();

      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.streamCustomerAppointments(uid);
    });

/// StreamProvider lắng nghe danh sách lịch hẹn của thợ hiện tại
final barberAppointmentsProvider =
    StreamProvider.autoDispose<List<AppointmentModel>>((ref) {
      final authUser = ref.watch(authStateProvider).value;
      final uid =
          authUser?.uid ??
          ref.watch(currentUserModelProvider).value?.uid ??
          ref.watch(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return const Stream.empty();

      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.streamBarberAppointments(uid);
    });

/// Trạng thái của các thao tác cập nhật lịch hẹn (Hủy, Xác nhận, Từ chối, Hoàn tất)
class AppointmentActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AppointmentActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AppointmentActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AppointmentActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier quản lý các thao tác hành động trên lịch hẹn (Task 4.11)
class AppointmentActionNotifier extends StateNotifier<AppointmentActionState> {
  final AppointmentRepository _repository;

  AppointmentActionNotifier(this._repository)
    : super(const AppointmentActionState());

  /// Khách hàng hủy lịch hẹn
  Future<bool> cancelAppointment({
    required String appointmentId,
    required String customerId,
    DateTime? currentTime,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.cancelAppointment(
        appointmentId: appointmentId,
        cancelledByUid: customerId,
        currentTime: currentTime,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đã hủy lịch hẹn thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Thợ tiếp nhận lịch hẹn
  Future<bool> confirmAppointment(
    String appointmentId, {
    String? barberId,
    String? barberName,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.confirmAppointment(appointmentId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đã tiếp nhận lịch hẹn thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Thợ từ chối lịch hẹn (và giải phóng slot)
  Future<bool> rejectAppointment(String appointmentId, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.rejectAppointment(appointmentId, reason: reason);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đã từ chối lịch hẹn và mở lại khung giờ!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Thợ hoàn tất dịch vụ
  Future<bool> completeAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.completeAppointment(appointmentId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đã cập nhật hoàn thành dịch vụ!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Khách hàng đánh giá dịch vụ (Task 6.9)
  Future<bool> rateAppointment({
    required String appointmentId,
    required String barberId,
    required int rating,
    String? customerId,
    String? customerName,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.rateAppointment(
        appointmentId: appointmentId,
        barberId: barberId,
        rating: rating,
        customerId: customerId,
        customerName: customerName,
        comment: comment,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cảm ơn bạn đã đánh giá dịch vụ!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearStatus() {
    state = const AppointmentActionState();
  }
}

/// Provider cho các thao tác trên lịch hẹn
final appointmentActionProvider =
    StateNotifierProvider.autoDispose<
      AppointmentActionNotifier,
      AppointmentActionState
    >((ref) {
      final repo = ref.watch(appointmentRepositoryProvider);
      return AppointmentActionNotifier(repo);
    });
