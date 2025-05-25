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
    apiKey: 'AIzaSyBYYvWtMs_g5Esqp7d_H4et8KnTmH2ak7k',
    appId: '1:467558598138:web:75cac6aef5b7171ed01043',
    messagingSenderId: '467558598138',
    projectId: 'umtrack-fa72e',
    authDomain: 'umtrack-fa72e.firebaseapp.com',
    storageBucket: 'umtrack-fa72e.firebasestorage.app',
    measurementId: 'G-0B3GSTYNWE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnrG9uq2BJO4PMPamg-tjVFFQ0gbeYL24',
    appId: '1:467558598138:android:6ec349226c517610d01043',
    messagingSenderId: '467558598138',
    projectId: 'umtrack-fa72e',
    storageBucket: 'umtrack-fa72e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqZ5eTA5rkzbY8Ldf003y8he_7sPmppfY',
    appId: '1:467558598138:ios:ce3a69e466444159d01043',
    messagingSenderId: '467558598138',
    projectId: 'umtrack-fa72e',
    storageBucket: 'umtrack-fa72e.firebasestorage.app',
    iosClientId: '467558598138-eadf86ra7en2p3hjhl2i3hl6j3vs8k3b.apps.googleusercontent.com',
    iosBundleId: 'com.example.umtrack',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqZ5eTA5rkzbY8Ldf003y8he_7sPmppfY',
    appId: '1:467558598138:ios:ce3a69e466444159d01043',
    messagingSenderId: '467558598138',
    projectId: 'umtrack-fa72e',
    storageBucket: 'umtrack-fa72e.firebasestorage.app',
    iosClientId: '467558598138-eadf86ra7en2p3hjhl2i3hl6j3vs8k3b.apps.googleusercontent.com',
    iosBundleId: 'com.example.umtrack',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYYvWtMs_g5Esqp7d_H4et8KnTmH2ak7k',
    appId: '1:467558598138:web:ae97db002c45b7e0d01043',
    messagingSenderId: '467558598138',
    projectId: 'umtrack-fa72e',
    authDomain: 'umtrack-fa72e.firebaseapp.com',
    storageBucket: 'umtrack-fa72e.firebasestorage.app',
    measurementId: 'G-DQWPS9ZCG9',
  );
}
