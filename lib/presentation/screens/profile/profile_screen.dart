import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';

/// 👤 ÉCRAN DE PROFIL UTILISATEUR
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 💾 SAUVEGARDER LES MODIFICATIONS DU PROFIL DANS FIREBASE
  Future<void> _saveUserProfile() async {
    if (_currentUser == null) return;

    try {
      // Mettre à jour la date de modification
      final updatedUser = _currentUser!.copyWith(
        updatedAt: DateTime.now(),
      );

      // Sauvegarder dans Firebase
      await _authService.updateUserProfile(updatedUser);

      setState(() {
        _currentUser = updatedUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil enregistré avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête avec photo de profil
          _buildProfileHeader().animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
          const SizedBox(height: 20),

          // Informations personnelles
          _buildSection(
            title: 'Informations personnelles',
            delayMs: 100,
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Nom complet',
                value: _currentUser?.fullName ?? 'Non renseigné',
                onTap: () => _showFullNameEditDialog(context),
              ),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: _currentUser?.email ?? 'Non renseigné',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Email',
                  currentValue: _currentUser?.email ?? '',
                  keyboardType: TextInputType.emailAddress,
                  onSave: (value) {
                    setState(() {
                      _currentUser = _currentUser?.copyWith(email: value);
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                value: _currentUser?.phoneNumber ?? 'Non renseigné',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Téléphone',
                  currentValue: _currentUser?.phoneNumber ?? '',
                  keyboardType: TextInputType.phone,
                  onSave: (value) {
                    setState(() {
                      _currentUser = _currentUser?.copyWith(phoneNumber: value);
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.cake_outlined,
                title: 'Date de naissance',
                value: _currentUser?.dateOfBirth != null
                    ? '${_currentUser!.dateOfBirth!.day}/${_currentUser!.dateOfBirth!.month}/${_currentUser!.dateOfBirth!.year}'
                    : 'Non renseigné',
                onTap: () => _showDatePicker(context),
              ),
              _buildInfoTile(
                icon: Icons.wc_outlined,
                title: 'Sexe',
                value: _currentUser?.gender ?? 'Non renseigné',
                onTap: () => _showGenderDialog(context),
              ),
              _buildInfoTile(
                icon: Icons.height_outlined,
                title: 'Taille',
                value: _currentUser?.height != null
                    ? '${_currentUser!.height} cm'
                    : 'Non renseigné',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Taille (cm)',
                  currentValue: _currentUser?.height?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  onSave: (value) {
                    setState(() {
                      _currentUser =
                          _currentUser?.copyWith(height: int.tryParse(value));
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.monitor_weight_outlined,
                title: 'Poids',
                value: _currentUser?.weight != null
                    ? '${_currentUser!.weight} kg'
                    : 'Non renseigné',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Poids (kg)',
                  currentValue: _currentUser?.weight?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  onSave: (value) {
                    setState(() {
                      _currentUser =
                          _currentUser?.copyWith(weight: int.tryParse(value));
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.bloodtype_outlined,
                title: 'Groupe sanguin',
                value: _currentUser?.bloodType ?? 'Non renseigné',
                onTap: () => _showBloodTypeDialog(context),
              ),
            ],
          ),

          // Informations médicales
          _buildSection(
            title: 'Données Médicales',
            delayMs: 150,
            children: [
              _buildInfoTile(
                icon: Icons.medical_information_outlined,
                title: 'Conditions médicales',
                value: _currentUser?.medicalConditions ?? 'Aucune',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Conditions médicales',
                  currentValue: _currentUser?.medicalConditions ?? '',
                  maxLines: 3,
                  onSave: (value) {
                    setState(() {
                      _currentUser =
                          _currentUser?.copyWith(medicalConditions: value);
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.warning_amber_outlined,
                title: 'Allergies',
                value: _currentUser?.allergies ?? 'Aucune',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Allergies',
                  currentValue: _currentUser?.allergies ?? '',
                  maxLines: 2,
                  onSave: (value) {
                    setState(() {
                      _currentUser = _currentUser?.copyWith(allergies: value);
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.medication_outlined,
                title: 'Médicaments',
                value: _currentUser?.medications ?? 'Aucun',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Médicaments actuels',
                  currentValue: _currentUser?.medications ?? '',
                  maxLines: 3,
                  onSave: (value) {
                    setState(() {
                      _currentUser = _currentUser?.copyWith(medications: value);
                    });
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.phone_in_talk_outlined,
                title: 'Contact d\'urgence',
                value: _currentUser?.emergencyContact ?? 'Non renseigné',
                onTap: () => _showEditDialog(
                  context,
                  title: 'Contact d\'urgence',
                  currentValue: _currentUser?.emergencyContact ?? '',
                  keyboardType: TextInputType.phone,
                  onSave: (value) {
                    setState(() {
                      _currentUser =
                          _currentUser?.copyWith(emergencyContact: value);
                    });
                  },
                ),
              ),
            ],
          ),

          // Paramètres
          _buildSection(
            title: 'Paramètres',
            delayMs: 200,
            children: [
              _buildMenuTile(
                icon: Icons.lock_outline,
                title: 'Changer le mot de passe',
                onTap: _showChangePasswordDialog,
              ),
              _buildMenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Notifications activées'
                            : 'Notifications désactivées'),
                      ),
                    );
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              _buildMenuTile(
                icon: Icons.language_outlined,
                title: 'Langue',
                subtitle: 'Français',
                onTap: _showLanguageDialog,
              ),
              _buildMenuTile(
                icon: Icons.science_outlined,
                title: 'Contribuer à la recherche',
                subtitle: 'Partage anonymisé pour améliorer le modèle IA',
                trailing: Switch(
                  value: _currentUser?.allowResearchDataSharing ?? false,
                  onChanged: _onToggleResearchConsent,
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),

          // À propos
          _buildSection(
            title: 'Support',
            delayMs: 250,
            children: [
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Centre d\'aide',
                onTap: () => Navigator.pushNamed(context, AppRoutes.help),
              ),
              _buildMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
              ),
              _buildMenuTile(
                icon: Icons.description_outlined,
                title: 'Conditions d\'utilisation',
                onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
              ),
              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'À propos',
                subtitle: 'Version 1.0.0',
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              ),
            ],
          ),

          // Déconnexion
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo de profil
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _currentUser?.profileImageUrl != null &&
                        _currentUser!.profileImageUrl!.isNotEmpty &&
                        _currentUser!.profileImageUrl!.startsWith('http')
                    ? ClipOval(
                        child: Image.network(
                          _currentUser!.profileImageUrl!,
                          key: ValueKey(_currentUser!
                              .profileImageUrl), // Force reload on change
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person,
                                size: 50, color: AppColors.primary);
                          },
                        ),
                      )
                    : const Icon(Icons.person,
                        size: 50, color: AppColors.primary),
              ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 500.ms),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showImagePickerOptions,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Nom
          Text(
            _currentUser?.fullName ?? 'Utilisateur',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          // Email
          Text(
            _currentUser?.email ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentUser?.role == UserRole.doctor
                      ? Icons.medical_services
                      : Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentUser?.role == UserRole.doctor ? 'Médecin' : 'Patient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    int delayMs = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text(title, style: AppTextStyles.h3),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    ).animate().fadeIn(delay: delayMs.ms, duration: 350.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textLight,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            )
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  // Dialogue d'édition générique
  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $title'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.pop(context);
                // Sauvegarder dans Firebase
                await _saveUserProfile();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Sélecteur de date
  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentUser?.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentUser = _currentUser?.copyWith(dateOfBirth: picked);
      });
      // Sauvegarder dans Firebase
      await _saveUserProfile();
    }
  }

  // Édition du nom complet (prénom + nom)
  void _showFullNameEditDialog(BuildContext context) {
    final firstNameController =
        TextEditingController(text: _currentUser?.firstName ?? '');
    final lastNameController =
        TextEditingController(text: _currentUser?.lastName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isNotEmpty &&
                  lastNameController.text.isNotEmpty) {
                setState(() {
                  _currentUser = _currentUser?.copyWith(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                  );
                });
                Navigator.pop(context);
                // Sauvegarder dans Firebase
                await _saveUserProfile();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Options de sélection d'image
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Changer la photo de profil',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.secondary),
                ),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentUser?.profileImageUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  title: const Text('Supprimer la photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Sélectionner une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && _currentUser != null) {
        // Afficher loader
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text('📤 Upload en cours...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Supprimer l'ancienne photo si elle existe dans Firebase Storage
        final oldUrl = _currentUser?.profileImageUrl;
        if (oldUrl != null &&
            oldUrl.isNotEmpty &&
            oldUrl.contains('firebase')) {
          try {
            await FirebaseStorage.instance.refFromURL(oldUrl).delete();
          } catch (_) {
            // Ignorer si déjà supprimé ou URL invalide
          }
        }

        // Upload vers Firebase Storage
        final storage = FirebaseStorage.instance;
        final fileName =
            'profile_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = storage.ref().child('profile_pictures/$fileName');

        // Upload le fichier
        final bytes = await image.readAsBytes();
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Récupérer l'URL publique
        final downloadUrl = await storageRef.getDownloadURL();

        // Mettre à jour localement puis sauvegarder dans Firestore
        final updatedUser = _currentUser!.copyWith(
          profileImageUrl: downloadUrl,
          updatedAt: DateTime.now(),
        );
        setState(() => _currentUser = updatedUser);
        await _authService.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Photo de profil sauvegardée'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Supprimer la photo de profil (Storage + Firestore)
  Future<void> _removeProfileImage() async {
    final oldUrl = _currentUser?.profileImageUrl;

    // Supprimer le fichier dans Firebase Storage si c'est un fichier uploadé
    if (oldUrl != null && oldUrl.isNotEmpty && oldUrl.contains('firebase')) {
      try {
        await FirebaseStorage.instance.refFromURL(oldUrl).delete();
      } catch (_) {
        // Ignorer si déjà supprimé
      }
    }

    // Mettre à jour le profil sans photo
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        profileImageUrl: null,
        updatedAt: DateTime.now(),
      );
      setState(() => _currentUser = updatedUser);
      try {
        await _authService.updateUserProfile(updatedUser);
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil supprimée'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Changement de mot de passe
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Les mots de passe ne correspondent pas'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Le mot de passe doit contenir au moins 6 caractères'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final authService = ref.read(authServiceProvider);
                  await authService.updatePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Mot de passe modifié avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  // Changement de langue
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: 'fr',
              activeColor: AppColors.primary,
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Langue changée: Français')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'fr',
              activeColor: AppColors.primary,
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Language changed: English')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔬 CONSENTEMENT PARTAGE DE DONNÉES POUR LA RECHERCHE
  ///
  /// Activation = opt-in explicite avec dialog détaillant précisément ce qui
  /// est partagé (audio de toux pseudonymisé, pas les données nominatives).
  /// Désactivation = immédiate, sans friction (droit de retrait RGPD).
  Future<void> _onToggleResearchConsent(bool enabled) async {
    if (_currentUser == null) return;

    if (!enabled) {
      final updatedUser = _currentUser!.copyWith(
        allowResearchDataSharing: false,
        updatedAt: DateTime.now(),
      );
      await _authService.updateUserProfile(updatedUser);
      if (!mounted) return;
      setState(() => _currentUser = updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partage pour la recherche désactivé')),
      );
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Contribuer à la recherche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'RespiraBox utilise un modèle de reconnaissance de crépitements/'
                'sibilants entraîné sur un dataset clinique public, pas encore '
                'sur de vraies toux enregistrées au téléphone. Votre contribution '
                'aide à corriger ça.',
              ),
              SizedBox(height: 12),
              Text('Si vous acceptez, à chaque test de toux :',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('• Votre enregistrement audio et les résultats du test sont partagés'),
              Text('• Votre nom, email et contact ne sont JAMAIS transmis avec'),
              Text('• Un identifiant pseudonymisé (non réversible) remplace votre identité'),
              Text(
                '• ⚠️ Votre voix elle-même pourrait théoriquement permettre de vous '
                'identifier, même sans donnée nominative associée',
              ),
              SizedBox(height: 12),
              Text('Vous pouvez désactiver ce partage à tout moment ici.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('J\'accepte'),
          ),
        ],
      ),
    );

    if (accepted != true) return;

    final updatedUser = _currentUser!.copyWith(
      allowResearchDataSharing: true,
      researchConsentDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _authService.updateUserProfile(updatedUser);
    if (!mounted) return;
    setState(() => _currentUser = updatedUser);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci de contribuer à la recherche 🙏')),
    );
  }

  // Sélection du sexe
  void _showGenderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner le sexe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.male, color: AppColors.primary),
              title: const Text('Homme'),
              onTap: () async {
                setState(() {
                  _currentUser = _currentUser?.copyWith(gender: 'Homme');
                });
                Navigator.pop(context);
                await _saveUserProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.female, color: AppColors.secondary),
              title: const Text('Femme'),
              onTap: () async {
                setState(() {
                  _currentUser = _currentUser?.copyWith(gender: 'Femme');
                });
                Navigator.pop(context);
                await _saveUserProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: const Text('Autre'),
              onTap: () async {
                setState(() {
                  _currentUser = _currentUser?.copyWith(gender: 'Autre');
                });
                Navigator.pop(context);
                await _saveUserProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Sélection du groupe sanguin
  void _showBloodTypeDialog(BuildContext context) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Groupe sanguin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: bloodTypes
                .map((type) => ListTile(
                      leading:
                          const Icon(Icons.bloodtype, color: AppColors.error),
                      title: Text(type),
                      onTap: () async {
                        setState(() {
                          _currentUser =
                              _currentUser?.copyWith(bloodType: type);
                        });
                        Navigator.pop(context);
                        await _saveUserProfile();
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
