import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCCSydAGDIfKlk8pYQAHCN-bOVe55QWCr0',
    appId: '1:631101559036:web:80e24ebd5341c2650e0779',
    messagingSenderId: '631101559036',
    projectId: 'app-ansar',
    authDomain: 'app-ansar.firebaseapp.com',
    storageBucket: 'app-ansar.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCCSydAGDIfKlk8pYQAHCN-bOVe55QWCr0',
    appId: '1:631101559036:android:80e24ebd5341c2650e0779',
    messagingSenderId: '631101559036',
    projectId: 'app-ansar',
    storageBucket: 'app-ansar.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCCSydAGDIfKlk8pYQAHCN-bOVe55QWCr0',
    appId: '1:631101559036:ios:80e24ebd5341c2650e0779',
    messagingSenderId: '631101559036',
    projectId: 'app-ansar',
    storageBucket: 'app-ansar.firebasestorage.app',
    iosClientId: '631101559036-ios-client-id',
    iosBundleId: 'com.ansar.ansarTeam',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCCSydAGDIfKlk8pYQAHCN-bOVe55QWCr0',
    appId: '1:631101559036:macos:80e24ebd5341c2650e0779',
    messagingSenderId: '631101559036',
    projectId: 'app-ansar',
    storageBucket: 'app-ansar.firebasestorage.app',
    iosClientId: '631101559036-macos-client-id',
    iosBundleId: 'com.ansar.ansarTeam',
  );
} 