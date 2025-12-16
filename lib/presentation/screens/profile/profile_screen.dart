import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/mock_auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';

/// 👤 ÉCRAN DE PROFIL UTILISATEUR
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = MockAuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

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
          _buildProfileHeader(),
          const SizedBox(height: 20),

          // Informations personnelles
          _buildSection(
            title: 'Informations personnelles',
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Nom complet',
                value: _currentUser?.fullName ?? 'Non renseigné',
                onTap: () {
                  // TODO: Modifier le nom
                },
              ),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: _currentUser?.email ?? 'Non renseigné',
                onTap: () {
                  // TODO: Modifier l'email
                },
              ),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                value: _currentUser?.phoneNumber ?? 'Non renseigné',
                onTap: () {
                  // TODO: Modifier le téléphone
                },
              ),
              _buildInfoTile(
                icon: Icons.cake_outlined,
                title: 'Date de naissance',
                value: _currentUser?.dateOfBirth != null
                    ? '${_currentUser!.dateOfBirth!.day}/${_currentUser!.dateOfBirth!.month}/${_currentUser!.dateOfBirth!.year}'
                    : 'Non renseigné',
                onTap: () {
                  // TODO: Modifier la date
                },
              ),
            ],
          ),

          // Paramètres
          _buildSection(
            title: 'Paramètres',
            children: [
              _buildMenuTile(
                icon: Icons.lock_outline,
                title: 'Changer le mot de passe',
                onTap: () {
                  // TODO: Navigation vers changement de mot de passe
                },
              ),
              _buildMenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Gérer les notifications
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              _buildMenuTile(
                icon: Icons.language_outlined,
                title: 'Langue',
                subtitle: 'Français',
                onTap: () {
                  // TODO: Changer la langue
                },
              ),
            ],
          ),

          // À propos
          _buildSection(
            title: 'Support',
            children: [
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Centre d\'aide',
                onTap: () {
                  // TODO: Navigation vers aide
                },
              ),
              _buildMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                onTap: () {
                  // TODO: Afficher politique
                },
              ),
              _buildMenuTile(
                icon: Icons.description_outlined,
                title: 'Conditions d\'utilisation',
                onTap: () {
                  // TODO: Afficher conditions
                },
              ),
              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'À propos',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  // TODO: Afficher à propos
                },
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
          ),
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
                child: _currentUser?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _currentUser!.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 50, color: AppColors.primary);
                          },
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () {
                    // TODO: Changer la photo
                  },
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
                    child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
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
    );
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
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}
