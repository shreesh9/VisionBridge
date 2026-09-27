# VisionBridge — Native Setup & Deployment Guide
==================================================
Version: 9.09.05
Author: Shreesh Nalawade (shreeshnalawade9@gmail.com)
Reference: SN09092005

-------------------------------------------------------
1. ANDROID CONFIGURATION
-------------------------------------------------------
File: android/app/src/main/AndroidManifest.xml

Add the required permissions inside <manifest> before <application>:

  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
  <uses-permission android:name="android.permission.VIBRATE"/>
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

In android/app/build.gradle:
  defaultConfig {
      minSdkVersion 24
      targetSdkVersion 34
  }

Native Privacy Channel:
  MainActivity.kt implements the `com.visionbridge.app/privacy` MethodChannel
  which sets `FLAG_SECURE` to prevent volunteer screenshotting or screen-recording.

-------------------------------------------------------
2. iOS CONFIGURATION
-------------------------------------------------------
File: ios/Runner/Info.plist

Add permissions inside <dict>:

  <key>NSCameraUsageDescription</key>
  <string>VisionBridge needs camera access for AI-powered visual assistance and live volunteer video calls.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>VisionBridge needs microphone access for voice commands and volunteer audio calling.</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>VisionBridge uses your location for SOS emergency alerts to share with contacts.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>VisionBridge requires location access during SOS emergency alerts.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>VisionBridge uses speech recognition for hands-free voice commands.</string>

In ios/Podfile:
  platform :ios, '16.0'

-------------------------------------------------------
3. FIREBASE INFRASTRUCTURE SETUP
-------------------------------------------------------
1. Create a Firebase Project at https://console.firebase.google.com
2. Enable Authentication (Email/Password & Google Sign-In).
3. Create Firestore Database (Collection: `call_requests`, `users`, `sos_alerts`).
4. Run FlutterFire CLI:
     dart pub global activate flutterfire_cli
     flutterfire configure

-------------------------------------------------------
4. ENVIRONMENT VARIABLES (.env)
-------------------------------------------------------
Create `.env` in root:
  GROQ_KEY_1=gsk_your_groq_api_key_1
  GROQ_KEY_2=gsk_your_groq_api_key_2
  GROQ_KEY_3=gsk_your_groq_api_key_3

-------------------------------------------------------
5. EXECUTION COMMANDS
-------------------------------------------------------
Single Device:
  flutter run --dart-define-from-file=.env

Dual Device Testing:
  flutter run -d <DEVICE_1_ID> --dart-define-from-file=.env
  flutter run -d <DEVICE_2_ID> --dart-define-from-file=.env
