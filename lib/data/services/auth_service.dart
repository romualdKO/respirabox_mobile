import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// 🔐 SERVICE D'AUTHENTIFICATION FIREBASE
/// Gère l'inscription, la connexion, la déconnexion et la gestion des utilisateurs
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Utilisateur actuel connecté
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 📧 INSCRIPTION PAR EMAIL/MOT DE PASSE
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String gender,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth sans paramètres optionnels
      final UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Créer le profil utilisateur dans Firestore
      if (userCredential.user != null) {
        final UserModel newUser = UserModel(
          id: userCredential.user!.uid,
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

        // Sauvegarder dans Firestore
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toFirestore());

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de l\'inscription: $e';
    }
  }

  /// 🔑 CONNEXION PAR EMAIL/MOT DE PASSE
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Se connecter avec Firebase Auth sans paramètres optionnels
      final UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Récupérer les données utilisateur depuis Firestore
      if (userCredential.user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (docSnapshot.exists) {
          return UserModel.fromFirestore(docSnapshot);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de la connexion: $e';
    }
  }

  /// 🔄 RÉINITIALISATION DU MOT DE PASSE
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de l\'envoi de l\'email: $e';
    }
  }

  /// 🚪 DÉCONNEXION
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  /// 👤 RÉCUPÉRER LES DONNÉES DE L'UTILISATEUR CONNECTÉ
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération des données: $e';
    }
  }

  /// ✏️ METTRE À JOUR LE PROFIL UTILISATEUR
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  /// 🗑️ SUPPRIMER LE COMPTE
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Supprimer les données Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Supprimer le compte Auth
        await user.delete();
      }
    } catch (e) {
      throw 'Erreur lors de la suppression du compte: $e';
    }
  }

  /// ⚠️ GESTION DES ERREURS D'AUTHENTIFICATION
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
