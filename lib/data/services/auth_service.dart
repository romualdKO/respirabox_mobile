import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// 🔐 SERVICE D'AUTHENTIFICATION FIREBASE
/// Gère l'inscription, la connexion, la déconnexion et la gestion des utilisateurs
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  /// 🔵 CONNEXION AVEC GOOGLE
  Future<UserModel?> signInWithGoogle() async {
    try {
      // 1. Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      // 2. Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Se connecter à Firebase avec les credentials Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // 5. Vérifier si l'utilisateur existe déjà dans Firestore
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          // Utilisateur existant, récupérer ses données
          return UserModel.fromFirestore(userDoc);
        } else {
          // Nouvel utilisateur, créer son profil
          final nameParts = (googleUser.displayName ?? '').split(' ');
          final newUser = UserModel(
            id: firebaseUser.uid,
            firstName: nameParts.isNotEmpty ? nameParts[0] : 'Utilisateur',
            lastName:
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            email: firebaseUser.email ?? googleUser.email,
            phoneNumber: firebaseUser.phoneNumber,
            gender: 'other',
            profileImageUrl: googleUser.photoUrl,
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
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de la connexion Google: $e';
    }
  }

  /// 👤 RÉCUPÉRER LES DONNÉES DE L'UTILISATEUR CONNECTÉ
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

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

  /// 🔒 CHANGER LE MOT DE PASSE
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Aucun utilisateur connecté';
      }

      // Ré-authentifier l'utilisateur avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Le mot de passe actuel est incorrect';
      } else if (e.code == 'weak-password') {
        throw 'Le nouveau mot de passe est trop faible';
      } else {
        throw _handleAuthException(e);
      }
    } catch (e) {
      throw 'Erreur lors du changement de mot de passe: $e';
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
