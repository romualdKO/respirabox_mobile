import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

/// 👤 PROVIDER UTILISATEUR GLOBAL
/// Gère l'état de l'utilisateur connecté dans toute l'application

// Provider AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider UserModel (utilisateur connecté)
final currentUserProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref.read(authServiceProvider));
});

/// Notifier pour gérer l'état utilisateur
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(const AsyncValue.loading()) {
    loadUser();
  }

  /// Charge les données utilisateur
  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUserData();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Rafraîchit les données utilisateur
  Future<void> refresh() async {
    await loadUser();
  }

  /// Met à jour l'utilisateur après modification
  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  /// Déconnexion
  Future<void> logout() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}
