/// VisionBridge — Firebase Options
///
/// Generated configuration matching android/app/google-services.json.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not a target for VisionBridge.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyBeUYvbLZ8dxAb8IiCQZ-MIxB3hTS74Bqs',
    appId: '1:912287025345:android:6bbb9fc6d7ad7f95a5ec40',
    messagingSenderId: '912287025345',
    projectId: 'visionbridge-ddaa4',
    storageBucket: 'visionbridge-ddaa4.firebasestorage.app',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyBeUYvbLZ8dxAb8IiCQZ-MIxB3hTS74Bqs',
    appId: '1:912287025345:ios:6bbb9fc6d7ad7f95a5ec40',
    messagingSenderId: '912287025345',
    projectId: 'visionbridge-ddaa4',
    storageBucket: 'visionbridge-ddaa4.firebasestorage.app',
    iosBundleId: 'com.example.visionBridge',
  );
}
