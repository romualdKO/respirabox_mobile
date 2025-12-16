import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

/// 🔥 CONFIGURATION FIREBASE RESPIRABOX
/// Utilise les fichiers google-services.json (Android) et GoogleService-Info.plist (iOS)
class FirebaseConfig {
  /// Retourne les options Firebase selon la plateforme (iOS ou Android)
  static FirebaseOptions get firebaseOptions {
    if (Platform.isIOS) {
      // 🍎 Configuration iOS (GoogleService-Info.plist)
      return const FirebaseOptions(
        apiKey: 'AIzaSyAeh056bhrg7TXC-cep8SfJ-GMXTAcU15E',
        appId: '1:674993570782:ios:9c0d669475dac6bd3f134f',
        messagingSenderId: '674993570782',
        projectId: 'respirabox-production',
        storageBucket: 'respirabox-production.firebasestorage.app',
        iosBundleId: 'com.respirabox.app',
      );
    } else {
      // 🤖 Configuration Android (google-services.json)
      return const FirebaseOptions(
        apiKey: 'AIzaSyCH0-5uoEifeGZLRlNYsMwd29FmwFFttm0',
        appId: '1:674993570782:android:5cc6186f91dad41a3f134f',
        messagingSenderId: '674993570782',
        projectId: 'respirabox-production',
        storageBucket: 'respirabox-production.firebasestorage.app',
      );
    }
  }
}
