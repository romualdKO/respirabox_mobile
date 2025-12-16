import 'package:flutter/material.dart';

/// 🎨 DESIGN SYSTEM - COULEURS RESPIRABOX
/// Extrait des maquettes fournies
class AppColors {
  // ✅ Couleurs principales (vert/teal des maquettes)
  static const Color primary = Color(0xFF4DB6AC); // Teal pour icônes
  static const Color primaryDark = Color(0xFF009688);
  static const Color secondary = Color(0xFF00C853); // Vert boutons "Commencer le test"
  
  // 📄 Backgrounds
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color beige = Color(0xFFFFF3E0); // Background illustration poumons
  
  // 📝 Textes
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Aliases pour compatibilité
  static const Color textDark = textPrimary;
  static const Color textLight = textSecondary;
  
  // 🚦 Status colors (pour les résultats de tests)
  static const Color success = Color(0xFF4CAF50); // Risque faible
  static const Color warning = Color(0xFFFFC107); // Risque moyen
  static const Color error = Color(0xFFF44336); // Risque élevé
  static const Color info = Color(0xFF2196F3);
  
  // 🫁 Icônes spécifiques
  static const Color lungIcon = Color(0xFF5A9FA8); // Couleur des poumons dans l'illustration
  static const Color bluetooth = Color(0xFF4DB6AC);
  
  // 📱 Interface
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFE0E0E0);
}
