import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

/// Base widget pour les pages de contenu statique
class ContentPage extends StatelessWidget {
  final String title;
  final List<ContentSection> sections;

  const ContentPage({
    Key? key,
    required this.title,
    required this.sections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.h2),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.title != null) ...[
                  Text(
                    section.title!,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  section.content,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ContentSection {
  final String? title;
  final String content;

  ContentSection({this.title, required this.content});
}

// 📚 Page d'aide
class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContentPage(
      title: 'Centre d\'aide',
      sections: [
        ContentSection(
          title: 'Comment utiliser RespiraBox ?',
          content:
              'RespiraBox est une solution simple et efficace pour surveiller votre santé respiratoire. '
              'Connectez votre boîtier, suivez les instructions à l\'écran, et obtenez vos résultats en 30 secondes.',
        ),
        ContentSection(
          title: 'Comment effectuer un test ?',
          content: '1. Connectez-vous à l\'application\n'
              '2. Appuyez sur "Scanner" pour détecter votre boîtier RespiraBox\n'
              '3. Suivez les instructions de préparation\n'
              '4. Respirez normalement pendant 30 secondes\n'
              '5. Consultez vos résultats détaillés',
        ),
        ContentSection(
          title: 'Que signifient mes résultats ?',
          content: '• Score Faible: Vos paramètres respiratoires sont normaux\n'
              '• Score Moyen: Certains paramètres nécessitent une surveillance\n'
              '• Score Élevé: Consultez un professionnel de santé rapidement',
        ),
        ContentSection(
          title: 'Questions fréquentes',
          content: 'Q: À quelle fréquence dois-je faire un test ?\n'
              'R: Nous recommandons un test hebdomadaire pour un suivi optimal.\n\n'
              'Q: Mes données sont-elles sécurisées ?\n'
              'R: Oui, toutes vos données sont chiffrées et stockées de manière sécurisée.\n\n'
              'Q: Puis-je partager mes résultats avec mon médecin ?\n'
              'R: Oui, utilisez le bouton "Partager" dans les résultats du test.',
        ),
        ContentSection(
          title: 'Besoin d\'aide supplémentaire ?',
          content: 'Contactez notre équipe support:\n'
              '📧 Email: support@respirabox.ci\n'
              '📞 Téléphone: +225 XX XX XX XX XX\n'
              '🕐 Horaires: Lun-Ven 8h-18h',
        ),
      ],
    );
  }
}

// 🔒 Page de politique de confidentialité
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContentPage(
      title: 'Politique de confidentialité',
      sections: [
        ContentSection(
          content: 'Dernière mise à jour: 16 décembre 2025\n\n'
              'RespiraBox s\'engage à protéger votre vie privée et vos données personnelles. '
              'Cette politique explique comment nous collectons, utilisons et protégeons vos informations.',
        ),
        ContentSection(
          title: '1. Données collectées',
          content: 'Nous collectons les informations suivantes:\n'
              '• Informations de profil (nom, email, téléphone)\n'
              '• Données de tests respiratoires (SpO2, fréquence cardiaque, température)\n'
              '• Historique des tests et résultats\n'
              '• Données d\'utilisation de l\'application',
        ),
        ContentSection(
          title: '2. Utilisation des données',
          content: 'Vos données sont utilisées pour:\n'
              '• Fournir nos services de dépistage\n'
              '• Améliorer votre expérience utilisateur\n'
              '• Vous envoyer des notifications importantes\n'
              '• Générer des statistiques anonymisées\n'
              '• Assurer la sécurité de nos systèmes',
        ),
        ContentSection(
          title: '3. Protection des données',
          content: 'Nous mettons en œuvre des mesures de sécurité strictes:\n'
              '• Chiffrement de bout en bout\n'
              '• Serveurs sécurisés certifiés\n'
              '• Accès restreint aux données médicales\n'
              '• Conformité RGPD et normes locales',
        ),
        ContentSection(
          title: '4. Vos droits',
          content: 'Vous avez le droit de:\n'
              '• Accéder à vos données personnelles\n'
              '• Corriger ou supprimer vos informations\n'
              '• Vous opposer au traitement de vos données\n'
              '• Exporter vos données médicales\n'
              '• Retirer votre consentement à tout moment',
        ),
        ContentSection(
          title: '5. Partage des données',
          content:
              'Nous ne vendons jamais vos données. Elles peuvent être partagées uniquement:\n'
              '• Avec votre consentement explicite\n'
              '• Avec des professionnels de santé autorisés\n'
              '• En cas d\'obligation légale\n'
              '• Avec nos partenaires techniques (données anonymisées)',
        ),
        ContentSection(
          title: '6. Contact',
          content: 'Pour toute question sur cette politique:\n'
              'Email: privacy@respirabox.ci\n'
              'Adresse: Abidjan, Côte d\'Ivoire',
        ),
      ],
    );
  }
}

// 📜 Page des conditions d'utilisation
class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContentPage(
      title: 'Conditions d\'utilisation',
      sections: [
        ContentSection(
          content: 'Dernière mise à jour: 16 décembre 2025\n\n'
              'En utilisant RespiraBox, vous acceptez les présentes conditions d\'utilisation.',
        ),
        ContentSection(
          title: '1. Objet du service',
          content:
              'RespiraBox est un dispositif médical de dépistage des maladies respiratoires. '
              'Il ne remplace pas une consultation médicale et ne permet pas d\'établir un diagnostic.',
        ),
        ContentSection(
          title: '2. Utilisation du service',
          content: 'Vous vous engagez à:\n'
              '• Fournir des informations exactes lors de l\'inscription\n'
              '• Garder vos identifiants confidentiels\n'
              '• Utiliser le service conformément aux instructions\n'
              '• Ne pas partager votre compte\n'
              '• Respecter les autres utilisateurs et le personnel',
        ),
        ContentSection(
          title: '3. Responsabilités',
          content: 'RespiraBox s\'engage à:\n'
              '• Fournir un service de qualité\n'
              '• Protéger vos données personnelles\n'
              '• Maintenir la disponibilité du service\n'
              '• Assurer la précision des mesures\n\n'
              'RespiraBox ne peut être tenu responsable de:\n'
              '• L\'utilisation incorrecte du dispositif\n'
              '• Les décisions médicales prises sur la base des résultats\n'
              '• Les interruptions techniques temporaires',
        ),
        ContentSection(
          title: '4. Avertissement médical',
          content: '⚠️ IMPORTANT:\n'
              '• RespiraBox est un outil de dépistage, pas de diagnostic\n'
              '• Consultez toujours un médecin en cas de symptômes\n'
              '• Ne modifiez pas votre traitement sans avis médical\n'
              '• En cas d\'urgence, composez le 185 ou 111',
        ),
        ContentSection(
          title: '5. Propriété intellectuelle',
          content:
              'Tous les éléments de RespiraBox (logos, textes, designs, algorithmes) '
              'sont la propriété exclusive de RespiraBox et protégés par les lois sur la propriété intellectuelle.',
        ),
        ContentSection(
          title: '6. Modification des conditions',
          content:
              'Nous nous réservons le droit de modifier ces conditions à tout moment. '
              'Les modifications seront notifiées via l\'application et prendront effet immédiatement.',
        ),
        ContentSection(
          title: '7. Résiliation',
          content:
              'Vous pouvez supprimer votre compte à tout moment depuis l\'application. '
              'Nous pouvons suspendre votre accès en cas de violation de ces conditions.',
        ),
        ContentSection(
          title: '8. Droit applicable',
          content: 'Ces conditions sont régies par le droit ivoirien. '
              'Tout litige sera soumis aux tribunaux compétents d\'Abidjan.',
        ),
      ],
    );
  }
}

// ℹ️ Page à propos
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('À propos', style: AppTextStyles.h2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo et nom
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('RespiraBox', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0 (Dev)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dépistage des maladies respiratoires',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mission
            _buildInfoCard(
              icon: Icons.favorite,
              title: 'Notre mission',
              content:
                  'Rendre le dépistage des maladies respiratoires accessible à tous en Côte d\'Ivoire grâce à une technologie innovante et abordable.',
            ),
            const SizedBox(height: 16),

            // Équipe
            _buildInfoCard(
              icon: Icons.people,
              title: 'L\'équipe',
              content:
                  'RespiraBox est développé par une équipe passionnée de médecins, ingénieurs et designers basée à Abidjan.',
            ),
            const SizedBox(height: 16),

            // Contact
            _buildInfoCard(
              icon: Icons.email,
              title: 'Contact',
              content: '📧 support@respirabox.ci\n'
                  '📞 +225 XX XX XX XX XX\n'
                  '🌐 www.respirabox.ci\n'
                  '📍 Abidjan, Côte d\'Ivoire',
            ),
            const SizedBox(height: 24),

            // Crédits
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Fait avec ❤️ pour la santé respiratoire',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2025 RespiraBox. Tous droits réservés.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                    height: 1.6,
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
