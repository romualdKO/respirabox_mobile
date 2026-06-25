import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// SERVICE DE STOCKAGE FIREBASE
/// Gère l'upload de fichiers (audio, images, PDF) vers Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Répertoire local de l'application
  Future<Directory> get _appDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// SAUVEGARDER UN FICHIER AUDIO DE TEST
  Future<String> uploadAudioFile({
    required String userId,
    required File audioFile,
    required String testId,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final storagePath = 'audio_tests/$userId/$testId/$fileName';
      final ref = _storage.ref().child(storagePath);

      final uploadTask = ref.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/aac',
          customMetadata: {'userId': userId, 'testId': testId},
        ),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Erreur upload audio: $e';
    }
  }

  /// UPLOADER UNE IMAGE DE PROFIL
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
          customMetadata: {'userId': userId},
        ),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Erreur upload image: $e';
    }
  }

  /// UPLOADER UN PDF DE RÉSULTATS
  Future<String> uploadPdfReport({
    required String userId,
    required File pdfFile,
    required String testId,
  }) async {
    try {
      final fileName =
          'report_${testId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref =
          _storage.ref().child('pdf_reports/$userId/$testId/$fileName');

      final uploadTask = ref.putFile(
        pdfFile,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {'userId': userId, 'testId': testId},
        ),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Erreur upload PDF: $e';
    }
  }

  /// SUPPRIMER UN FICHIER
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Erreur suppression fichier: $e';
    }
  }

  /// OBTENIR LA TAILLE D'UN FICHIER
  Future<int> getFileSize(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      throw 'Erreur récupération taille: $e';
    }
  }

  /// TÉLÉCHARGER UN FICHIER LOCALEMENT
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
      throw 'Erreur téléchargement: $e';
    }
  }

  /// LISTER TOUS LES FICHIERS D'UN UTILISATEUR
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
      throw 'Erreur listage fichiers: $e';
    }
  }

  /// SUIVRE LA PROGRESSION D'UN UPLOAD
  Stream<double> uploadFileWithProgress({
    required File file,
    required String storagePath,
  }) {
    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putFile(file);

    return uploadTask.snapshotEvents.map((snapshot) {
      if (snapshot.totalBytes == 0) return 0.0;
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// SAUVEGARDER UN FICHIER AUDIO LOCALEMENT (FALLBACK HORS LIGNE)
  Future<String> saveAudioLocally({
    required String userId,
    required File audioFile,
    required String testId,
  }) async {
    try {
      final appDir = await _appDirectory;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final testDir =
          Directory('${appDir.path}/audio_tests/$userId/$testId');

      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }

      final savedFile = File('${testDir.path}/$fileName');
      await audioFile.copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      throw 'Erreur sauvegarde locale audio: $e';
    }
  }
}
