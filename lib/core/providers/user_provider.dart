import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import 'app_providers.dart';

/// Provider StateNotifier pour gérer les actions sur l'utilisateur connecté.
/// Pour lire l'utilisateur courant, utiliser [currentUserProvider] de app_providers.dart.
final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref.read(authServiceProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(const AsyncValue.loading()) {
    loadUser();
  }

  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUserData();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async => await loadUser();

  void updateUser(UserModel user) => state = AsyncValue.data(user);

  Future<void> logout() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}
