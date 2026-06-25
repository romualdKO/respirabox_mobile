import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/test_result_model.dart';
import '../../../routes/app_routes.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/health_score_widget.dart';

/// 🏠 ÉCRAN D'ACCUEIL PRINCIPAL AVEC BOTTOM NAVIGATION
class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        DashboardPage(
            onTabChange: (index) => setState(() => _currentIndex = index)),
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
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.valueOrNull?.id ?? '';

    final testsAsync = ref.watch(recentTestsProvider(userId));
    final recentTests = testsAsync.valueOrNull ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, userAsync.valueOrNull, userId),
            const SizedBox(height: 30),
            _buildWelcomeCard(context, recentTests),
            const SizedBox(height: 25),
            Text('Actions rapides', style: AppTextStyles.h3),
            const SizedBox(height: 15),
            _buildQuickActions(context),
            const SizedBox(height: 30),
            _buildLastTests(context, userId),
            const SizedBox(height: 30),
            _buildStatistics(context, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, String userId) {
    final unreadCount =
        ref.watch(unreadCountProvider(userId)).valueOrNull ?? 0;

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.primary),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, List<TestResultModel> tests) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.deviceScan);
                  },
                  icon: const Icon(Icons.bluetooth_searching, size: 18),
                  label: const Text('Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (tests.isNotEmpty)
            HealthScoreWidget(tests: tests)
          else
            const Icon(Icons.medical_services, size: 70, color: Colors.white24),
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

  Widget _buildLastTests(BuildContext context, String userId) {
    final testsAsync = ref.watch(recentTestsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Derniers tests', style: AppTextStyles.h3),
            TextButton(
              onPressed: () => widget.onTabChange(1),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        testsAsync.when(
          data: (tests) {
            if (tests.isEmpty) {
              return _buildEmptyTestsCard();
            }
            return Column(
              children: tests.take(2).map((test) {
                final riskColor = test.riskLevel == RiskLevel.low
                    ? AppColors.success
                    : test.riskLevel == RiskLevel.medium
                        ? AppColors.warning
                        : AppColors.error;
                final riskText = test.riskLevel == RiskLevel.low
                    ? 'Faible'
                    : test.riskLevel == RiskLevel.medium
                        ? 'Moyen'
                        : 'Élevé';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildEnrichedTestCard(
                    context: context,
                    test: test,
                    riskText: riskText,
                    riskColor: riskColor,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Text('Erreur: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTestsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 15),
          Text(
            'Aucun test effectué',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par scanner votre RespiraBox pour effectuer votre premier test',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
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

  String _getRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day} ${_getMonthName(date.month)}';
  }

  Widget _buildEnrichedTestCard({
    required BuildContext context,
    required TestResultModel test,
    required String riskText,
    required Color riskColor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.testResults,
        arguments: {
          'spo2': test.spo2,
          'heartRate': test.heartRate,
          'temperature': test.temperature,
          'riskLevel': riskText,
          'riskScore': test.riskScore,
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: riskColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.monitor_heart, color: riskColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRelativeTime(test.testDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _vitaChip(Icons.air, '${test.spo2.round()}%', AppColors.info),
                      const SizedBox(width: 6),
                      _vitaChip(Icons.favorite, '${test.heartRate} bpm', AppColors.error),
                      const SizedBox(width: 6),
                      _vitaChip(Icons.thermostat, '${test.temperature.toStringAsFixed(1)}°', AppColors.warning),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                riskText,
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitaChip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context, String userId) {
    final testsAsync = ref.watch(recentTestsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques', style: AppTextStyles.h3),
        const SizedBox(height: 15),
        testsAsync.when(
          data: (tests) {
            final totalTests = tests.length;
            final avgSpo2 = tests.isEmpty
                ? 0
                : (tests.map((t) => t.spo2 ?? 0).reduce((a, b) => a + b) /
                        tests.length)
                    .round();

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tests effectués',
                    value: '$totalTests',
                    icon: Icons.assignment_turned_in,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: 'SpO2 moyen',
                    value: tests.isEmpty ? '--' : '$avgSpo2%',
                    icon: Icons.water_drop,
                    color: AppColors.info,
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tests effectués',
                  value: '--',
                  icon: Icons.assignment_turned_in,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: 'SpO2 moyen',
                  value: '--',
                  icon: Icons.water_drop,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tests effectués',
                  value: '--',
                  icon: Icons.assignment_turned_in,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: 'SpO2 moyen',
                  value: '--',
                  icon: Icons.water_drop,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
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
