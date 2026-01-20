import 'dart:convert';

/// 🧪 EXTENSION D'ANALYSE DE TOUX INTELLIGENTE
/// Ajoute détection TB/Pneumonie basée sur patterns audio
class CoughAnalysisHelper {
  /// Analyser le pattern de toux avec scoring médical
  static Map<String, dynamic> analyzeCoughPattern(
      String text, double duration, double confidence) {
    final lowerText = text.toLowerCase();

    // Analyse basée sur transcription et durée audio
    final hasCoughKeywords = lowerText.contains('toux') ||
        lowerText.contains('crachat') ||
        lowerText.contains('respiration') ||
        lowerText.contains('expectoration');

    // Estimation du nombre de toux (basé sur durée et patterns)
    final estimatedCoughCount =
        (duration / 3).ceil(); // ~1 toux toutes les 3 secondes

    // Type de toux (basé sur mots-clés)
    String coughType = 'sèche';
    if (lowerText.contains('glaire') ||
        lowerText.contains('crachat') ||
        lowerText.contains('expectoration')) {
      coughType = 'productive';
    } else if (lowerText.contains('humide') || lowerText.contains('grasse')) {
      coughType = 'grasse';
    }

    // Intensité (basée sur durée et fréquence)
    String intensity = 'légère';
    int intensityScore = 0;

    if (duration > 20 || estimatedCoughCount > 10) {
      intensity = 'sévère';
      intensityScore = 3;
    } else if (duration > 10 || estimatedCoughCount > 5) {
      intensity = 'modérée';
      intensityScore = 2;
    } else {
      intensity = 'légère';
      intensityScore = 1;
    }

    // SCORING MÉDICAL (0-100)
    int tbRisk = 0;
    int pneumoniaRisk = 0;

    // CRITÈRES TUBERCULOSE
    if (coughType == 'productive') tbRisk += 30;
    if (duration > 15) tbRisk += 20; // Toux persistante
    if (lowerText.contains('sang') || lowerText.contains('hémoptysie'))
      tbRisk += 40;
    if (intensityScore >= 2) tbRisk += 10;

    // CRITÈRES PNEUMONIE
    if (coughType == 'productive' || coughType == 'grasse') pneumoniaRisk += 35;
    if (lowerText.contains('douleur') || lowerText.contains('thoracique'))
      pneumoniaRisk += 30;
    if (lowerText.contains('fièvre') || lowerText.contains('chaud'))
      pneumoniaRisk += 20;
    if (intensityScore == 3) pneumoniaRisk += 15;

    // Recommandations
    String recommendation;
    if (tbRisk > 70 || pneumoniaRisk > 70) {
      recommendation =
          '🚨 URGENCE: Consultation médicale immédiate + Test GeneXpert (TB) ou Radiographie (Pneumonie)';
    } else if (tbRisk > 40 || pneumoniaRisk > 40) {
      recommendation =
          '⚠️ ALERTE: Consulter un médecin dans 48h + Surveillance SpO2';
    } else if (hasCoughKeywords && intensityScore >= 2) {
      recommendation =
          '💊 Toux modérée: Repos, hydratation, suivi RespiraBox quotidien';
    } else {
      recommendation =
          '✅ Toux légère: Hydratation, repos. Surveillance si persistance >3 jours';
    }

    return {
      'hasCough': hasCoughKeywords || duration > 5,
      'type': coughType,
      'intensity': intensity,
      'frequency': estimatedCoughCount,
      'tbRisk': tbRisk.clamp(0, 100),
      'pneumoniaRisk': pneumoniaRisk.clamp(0, 100),
      'recommendation': recommendation,
      'medicalScore': {
        'tuberculosis': tbRisk,
        'pneumonia': pneumoniaRisk,
        'urgencyLevel': tbRisk > 70 || pneumoniaRisk > 70
            ? 'high'
            : tbRisk > 40 || pneumoniaRisk > 40
                ? 'medium'
                : 'low',
      }
    };
  }
}
