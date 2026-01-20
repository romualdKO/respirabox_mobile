import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 📦 SERVICE DE STOCKAGE LOCAL
/// Gère la sauvegarde locale de fichiers (audio, images, PDF)
/// Alternative à Firebase Storage pour le mode Spark (gratuit)
class StorageService {
  /// Obtenir le répertoire de stockage de l'app
  Future<Directory> get _appDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// 🎙️ SAUVEGARDER UN FICHIER AUDIO DE TEST (LOCAL)
  Future<String> uploadAudioFile({
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

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload audio: $e';
    }
  }

  /// 🖼️ UPLOADER UNE IMAGE DE PROFIL
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload d\'image: $e';
    }
  }

  /// 📄 UPLOADER UN PDF DE RÉSULTATS
  Future<String> uploadPdfReport({
    required String userId,
    required File pdfFile,
    required String testId,
  }) async {
    try {
      final fileName =
          'report_${testId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('pdf_reports/$userId/$testId/$fileName');

      final uploadTask = ref.putFile(
        pdfFile,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'userId': userId,
            'testId': testId,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload PDF: $e';
    }
  }

  /// 🗑️ SUPPRIMER UN FICHIER
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Erreur lors de la suppression du fichier: $e';
    }
  }

  /// 📊 OBTENIR LA TAILLE D'UN FICHIER
  Future<int> getFileSize(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      throw 'Erreur lors de la récupération de la taille: $e';
    }
  }

  /// 📥 TÉLÉCHARGER UN FICHIER LOCALEMENT
  Future<File> downloadFile({
    required String fileUrl,
    required String localPath,
  }) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final file = File(localPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw 'Erreur lors du téléchargement: $e';
    }
  }

  /// 📋 LISTER TOUS LES FICHIERS D'UN UTILISATEUR
  Future<List<String>> listUserFiles(String userId, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/$userId');
      final result = await ref.listAll();

      final urls = <String>[];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw 'Erreur lors du listage des fichiers: $e';
    }
  }

  /// 🔄 SUIVRE LA PROGRESSION D'UN UPLOAD
  Stream<double> uploadFileWithProgress({
    required File file,
    required String storagePath,
  }) {
    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putFile(file);

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
