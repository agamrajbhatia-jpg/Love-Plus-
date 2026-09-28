import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// 
/// TO THE USER: You need to replace this file by running `flutterfire configure` 
/// in your terminal, which will generate the real credentials for your project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Temporarily use the web configuration for all platforms so that 
    // Email/Password and Firestore work on Android without proper native setup.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAYgugXS6qg69jlqt0PKE7liVDflqo5ehU',
    appId: '1:446572633895:web:6e900e3e13d80513a99302',
    messagingSenderId: '446572633895',
    projectId: 'love-plus-8b84d',
    authDomain: 'love-plus-8b84d.firebaseapp.com',
    storageBucket: 'love-plus-8b84d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'couple-app-demo',
    storageBucket: 'couple-app-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'couple-app-demo',
    storageBucket: 'couple-app-demo.appspot.com',
    iosBundleId: 'com.example.coupleApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'couple-app-demo',
    storageBucket: 'couple-app-demo.appspot.com',
    iosBundleId: 'com.example.coupleApp.RunnerTests',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'couple-app-demo',
    authDomain: 'couple-app-demo.firebaseapp.com',
    storageBucket: 'couple-app-demo.appspot.com',
    measurementId: 'REPLACE_ME',
  );
}
