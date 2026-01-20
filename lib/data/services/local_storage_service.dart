import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 💾 SERVICE DE STOCKAGE LOCAL
/// Alternative à Firebase Storage pour le mode Spark (gratuit)
/// Gère la sauvegarde locale de fichiers (audio, images, PDF)
class LocalStorageService {
  /// Obtenir le répertoire de stockage de l'app
  Future<Directory> get _appDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// 🎙️ SAUVEGARDER UN FICHIER AUDIO DE TEST (LOCAL)
  Future<String> saveAudioFile({
    required String userId,
    required File audioFile,
    required String testId,
  }) async {
    try {
      final appDir = await _appDirectory;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final testDir = Directory('${appDir.path}/audio_tests/$userId/$testId');

      // Créer le dossier si nécessaire
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }

      // Copier le fichier audio
      final savedFile = File('${testDir.path}/$fileName');
      await audioFile.copy(savedFile.path);

      print('✅ Audio sauvegardé localement: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      throw 'Erreur lors de la sauvegarde audio: $e';
    }
  }

  /// 🖼️ SAUVEGARDER UNE IMAGE DE PROFIL (LOCAL)
  Future<String> saveProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final appDir = await _appDirectory;
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final profileDir = Directory('${appDir.path}/profile_images/$userId');

      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final savedFile = File('${profileDir.path}/$fileName');
      await imageFile.copy(savedFile.path);

      print('✅ Photo de profil sauvegardée: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      throw 'Erreur lors de la sauvegarde d\'image: $e';
    }
  }

  /// 📄 SAUVEGARDER UN PDF DE RÉSULTATS (LOCAL)
  Future<String> savePdfReport({
    required String userId,
    required File pdfFile,
    required String testId,
  }) async {
    try {
      final appDir = await _appDirectory;
      final fileName =
          'report_${testId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final reportsDir = Directory('${appDir.path}/pdf_reports/$userId');

      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final savedFile = File('${reportsDir.path}/$fileName');
      await pdfFile.copy(savedFile.path);

      print('✅ PDF sauvegardé: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      throw 'Erreur lors de la sauvegarde PDF: $e';
    }
  }

  /// 🗑️ SUPPRIMER UN FICHIER
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ Fichier supprimé: $filePath');
      }
    } catch (e) {
      throw 'Erreur lors de la suppression: $e';
    }
  }

  /// 📂 LISTER LES FICHIERS D'UN TEST
  Future<List<String>> getTestFiles(String userId, String testId) async {
    try {
      final appDir = await _appDirectory;
      final testDir = Directory('${appDir.path}/audio_tests/$userId/$testId');

      if (!await testDir.exists()) {
        return [];
      }

      final files = testDir.listSync();
      return files.map((file) => file.path).toList();
    } catch (e) {
      throw 'Erreur lors du listage des fichiers: $e';
    }
  }

  /// 🗑️ SUPPRIMER TOUS LES FICHIERS D'UN TEST
  Future<void> deleteTestFiles(String userId, String testId) async {
    try {
      final appDir = await _appDirectory;
      final testDir = Directory('${appDir.path}/audio_tests/$userId/$testId');

      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
        print('✅ Tous les fichiers du test supprimés');
      }
    } catch (e) {
      throw 'Erreur lors de la suppression des fichiers: $e';
    }
  }

  /// 📊 OBTENIR LA TAILLE D'UN FICHIER
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw 'Erreur lors de la récupération de la taille: $e';
    }
  }

  /// 🧹 NETTOYER LES FICHIERS TEMPORAIRES
  Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
        print('✅ Fichiers temporaires nettoyés');
      }
    } catch (e) {
      throw 'Erreur lors du nettoyage: $e';
    }
  }

  /// 📁 OBTENIR LE CHEMIN DU RÉPERTOIRE DE L'APP
  Future<String> getAppDirectoryPath() async {
    final dir = await _appDirectory;
    return dir.path;
  }

  /// 📸 OBTENIR LE CHEMIN DE LA PHOTO DE PROFIL
  Future<String?> getProfileImagePath(String userId) async {
    try {
      final appDir = await _appDirectory;
      final profileDir = Directory('${appDir.path}/profile_images/$userId');

      if (!await profileDir.exists()) {
        return null;
      }

      final files = profileDir.listSync();
      if (files.isEmpty) {
        return null;
      }

      // Retourner le fichier le plus récent
      files.sort((a, b) => b.path.compareTo(a.path));
      return files.first.path;
    } catch (e) {
      return null;
    }
  }
}
