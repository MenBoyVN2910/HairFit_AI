import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/barber_profile/data/barber_profile_repository.dart';
import '../models/barber_profile_model.dart';

final pendingBarbersProvider = FutureProvider.autoDispose<List<BarberProfileModel>>((ref) async {
  final repo = ref.watch(barberProfileRepositoryProvider);
  return repo.getPendingBarbers();
});

class AdminController extends StateNotifier<AsyncValue<void>> {
  final BarberProfileRepository _repository;
  final Ref _ref;

  AdminController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> approveBarber(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateApprovalStatus(uid, 'approved');
      state = const AsyncValue.data(null);
      _ref.invalidate(pendingBarbersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectBarber(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateApprovalStatus(uid, 'rejected');
      state = const AsyncValue.data(null);
      _ref.invalidate(pendingBarbersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminControllerProvider = StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  return AdminController(ref.watch(barberProfileRepositoryProvider), ref);
});
