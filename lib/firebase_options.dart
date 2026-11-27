// Firebase settings for the app, written from android/app/google-services.json
// in the layout `flutterfire configure` produces. Not secret: these values
// ship inside every APK. Rerun `flutterfire configure` to add platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase is only configured for Android. Run flutterfire configure '
      'to add other platforms.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXjF6po0U_NehsEcDoyMn-gtiSM6CATrs',
    appId: '1:279169014429:android:138bd4dd4e7fe1d5b59274',
    messagingSenderId: '279169014429',
    projectId: 'roommate-finder-group42-4ee95',
    storageBucket: 'roommate-finder-group42-4ee95.firebasestorage.app',
  );
}
