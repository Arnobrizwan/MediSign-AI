// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0IiGaut3AeCV0c3PsFlmRRymqsC-sJzc',
    appId: '1:831291062644:web:9daa0f206abea11c625421',
    messagingSenderId: '831291062644',
    projectId: 'medisignai',
    authDomain: 'medisignai.firebaseapp.com',
    storageBucket: 'medisignai.firebasestorage.app',
    measurementId: 'G-GFRS48XBK4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAC872iqbSQR8dBbnGn4sr8acYTnrYENHw',
    appId: '1:831291062644:android:effd1886334f3c71625421',
    messagingSenderId: '831291062644',
    projectId: 'medisignai',
    storageBucket: 'medisignai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDL39pCbA5sdtx1V3S7SCfq2cGMbohIOe8',
    appId: '1:831291062644:ios:31176a4262b568ff625421',
    messagingSenderId: '831291062644',
    projectId: 'medisignai',
    storageBucket: 'medisignai.firebasestorage.app',
    iosClientId: '831291062644-1mqh1fdacthqkvei20tmfg75if2odnko.apps.googleusercontent.com',
    iosBundleId: 'com.example.medisignAi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDL39pCbA5sdtx1V3S7SCfq2cGMbohIOe8',
    appId: '1:831291062644:ios:31176a4262b568ff625421',
    messagingSenderId: '831291062644',
    projectId: 'medisignai',
    storageBucket: 'medisignai.firebasestorage.app',
    iosClientId: '831291062644-1mqh1fdacthqkvei20tmfg75if2odnko.apps.googleusercontent.com',
    iosBundleId: 'com.example.medisignAi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0IiGaut3AeCV0c3PsFlmRRymqsC-sJzc',
    appId: '1:831291062644:web:f8a44b64039d8726625421',
    messagingSenderId: '831291062644',
    projectId: 'medisignai',
    authDomain: 'medisignai.firebaseapp.com',
    storageBucket: 'medisignai.firebasestorage.app',
    measurementId: 'G-B3X67HSJJR',
  );
}
