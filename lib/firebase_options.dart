import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB77ZCWBV9z51LMQfMqR3dntJGz-lPZBhE',
    appId: '1:735978148430:web:d83cfb1aae98919231e91f',
    messagingSenderId: '735978148430',
    projectId: 'paveo-47e82',
    authDomain: 'paveo-47e82.firebaseapp.com',
    storageBucket: 'paveo-47e82.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB77ZCWBV9z51LMQfMqR3dntJGz-lPZBhE',
    appId: '1:735978148430:android:d83cfb1aae98919231e91f',
    messagingSenderId: '735978148430',
    projectId: 'paveo-47e82',
    storageBucket: 'paveo-47e82.firebasestorage.app',
  );
}
