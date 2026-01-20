import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

/// 📋 ÉCRAN DE PRÉPARATION AU TEST RESPIRATOIRE
/// Instructions avant de commencer le test
class TestPreparationScreen extends StatelessWidget {
  const TestPreparationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Préparation au test', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image d'illustration
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Titre
                    Text(
                      'Avant de commencer',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Suivez ces instructions pour un test précis',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Instructions
                    _buildInstructionCard(
                      number: '1',
                      title: 'Position assise',
                      description:
                          'Asseyez-vous confortablement, le dos droit et détendu',
                      icon: Icons.chair_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 15),

                    _buildInstructionCard(
                      number: '2',
                      title: 'Calme et respiration',
                      description:
                          'Respirez normalement pendant 2-3 minutes avant le test',
                      icon: Icons.air_outlined,
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 15),

                    _buildInstructionCard(
                      number: '3',
                      title: 'Capteur au doigt',
                      description:
                          'Placez correctement le capteur d\'oxymétrie sur votre index',
                      icon: Icons.fingerprint_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 15),

                    _buildInstructionCard(
                      number: '4',
                      title: 'Ne bougez pas',
                      description:
                          'Restez immobile pendant toute la durée du test (30 secondes)',
                      icon: Icons.do_not_disturb_alt_outlined,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 30),

                    // Avertissement
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ce test ne remplace pas un diagnostic médical. Consultez un professionnel de santé en cas de symptômes.',
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton Commencer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.testExecution);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Commencer le test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required String number,
    required String title,
    required String description,
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
      child: Row(
        children: [
          // Numéro
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
