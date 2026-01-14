import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_screen.dart';

/// 🏠 ÉCRAN D'ACCUEIL PRINCIPAL AVEC BOTTOM NAVIGATION
class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    DashboardPage(onTabChange: (index) => setState(() => _currentIndex = index)),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Écouter le provider utilisateur
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: userAsync.when(
        data: (user) => _pages[_currentIndex],
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// 📊 PAGE DASHBOARD (ONGLET ACCUEIL)
class DashboardPage extends ConsumerStatefulWidget {
  final Function(int) onTabChange;
  
  const DashboardPage({Key? key, required this.onTabChange}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur depuis le provider
    final userAsync = ref.watch(currentUserProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec données utilisateur
            userAsync.when(
              data: (user) => _buildHeader(context, user),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _buildHeader(context, null),
            ),
            const SizedBox(height: 30),

            // Carte de bienvenue
            _buildWelcomeCard(context),
            const SizedBox(height: 25),

            // Actions rapides
            Text('Actions rapides', style: AppTextStyles.h3),
            const SizedBox(height: 15),
            _buildQuickActions(context),
            const SizedBox(height: 30),

            // Derniers tests
            _buildLastTests(context),
            const SizedBox(height: 30),

            // Statistiques
            _buildStatistics(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour 👋', style: AppTextStyles.bodyText),
            const SizedBox(height: 4),
            Text(
              user?.fullName ?? 'Utilisateur',
              style: AppTextStyles.h2,
            ),
          ],
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prêt pour un test ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez votre RespiraBox',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.deviceScan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Commencer'),
                ),
              ],
            ),
          ),
          const Icon(Icons.medical_services, size: 80, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.bluetooth_searching,
            title: 'Scanner',
            subtitle: 'Appareil',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.deviceScan),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Chatbot',
            subtitle: 'Assistance IA',
            color: AppColors.secondary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.chatbot),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastTests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Derniers tests', style: AppTextStyles.h3),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildTestCard(
          date: '14 Déc 2025',
          time: '14:30',
          riskLevel: 'Faible',
          spo2: 98,
          heartRate: 75,
          riskColor: AppColors.success,
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          date: '10 Déc 2025',
          time: '09:15',
          riskLevel: 'Moyen',
          spo2: 94,
          heartRate: 82,
          riskColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String date,
    required String time,
    required String riskLevel,
    required int spo2,
    required int heartRate,
    required Color riskColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.favorite, color: riskColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date - $time',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SpO2: $spo2% • FC: $heartRate bpm',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques', style: AppTextStyles.h3),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tests effectués',
                value: '24',
                icon: Icons.assignment_turned_in,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                title: 'SpO2 moyen',
                value: '96%',
                icon: Icons.water_drop,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
