import '../models/user_model.dart';

/// 🎭 SERVICE D'AUTHENTIFICATION MOCK (pour développement frontend)
/// Simule l'authentification sans Firebase
class MockAuthService {
  UserModel? _currentUser;
  final List<Map<String, dynamic>> _users = [];

  /// Utilisateur actuel connecté
  UserModel? get currentUser => _currentUser;

  /// 📧 INSCRIPTION MOCK
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String gender,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    // Vérifier si l'email existe déjà
    if (_users.any((u) => u['email'] == email)) {
      throw 'Cet email est déjà utilisé';
    }

    // Créer un nouvel utilisateur
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      role: UserRole.patient,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    _users.add({
      'email': email,
      'password': password,
      'user': newUser,
    });

    _currentUser = newUser;
    return newUser;
  }

  /// 🔑 CONNEXION MOCK
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    // Chercher l'utilisateur
    final userData = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (userData.isEmpty) {
      throw 'Email ou mot de passe incorrect';
    }

    _currentUser = userData['user'] as UserModel;
    return _currentUser;
  }

  /// 🔄 RÉINITIALISATION DU MOT DE PASSE MOCK
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!_users.any((u) => u['email'] == email)) {
      throw 'Aucun compte trouvé avec cet email';
    }

    // Simuler l'envoi d'email
    print('📧 Email de réinitialisation envoyé à: $email');
  }

  /// 🚪 DÉCONNEXION
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// 👤 RÉCUPÉRER DONNÉES UTILISATEUR ACTUEL
  Future<UserModel?> getCurrentUserData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  /// ✏️ MISE À JOUR DU PROFIL
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_currentUser == null) return;

    _currentUser = UserModel(
      id: _currentUser!.id,
      firstName: firstName ?? _currentUser!.firstName,
      lastName: lastName ?? _currentUser!.lastName,
      email: _currentUser!.email,
      phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      dateOfBirth: dateOfBirth ?? _currentUser!.dateOfBirth,
      gender: gender ?? _currentUser!.gender,
      profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      role: _currentUser!.role,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
      isActive: _currentUser!.isActive,
    );

    // Mettre à jour dans la liste
    final index = _users.indexWhere((u) => u['user'].id == _currentUser!.id);
    if (index != -1) {
      _users[index]['user'] = _currentUser;
    }
  }

  /// 🗑️ SUPPRIMER LE COMPTE
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));

    if (_currentUser != null) {
      _users.removeWhere((u) => u['user'].id == _currentUser!.id);
      _currentUser = null;
    }
  }
}
