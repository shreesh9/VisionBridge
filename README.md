# VisionBridge 👁️⚡🌉

**VisionBridge** (`v9.09.05`) is a state-of-the-art, voice-first assistive mobile application designed to empower visually impaired and blind users with real-time AI computer vision and instant 1-on-1 human volunteer assistance.

Built with **Flutter**, **Groq Vision AI (Llama 3.2 / Qwen 3.6)**, **Google MLKit**, **WebRTC Peer-to-Peer**, and **Firebase**, VisionBridge delivers fast, natural, human companion scene narration and low-latency video calling capabilities wrapped in a dark-mode glassmorphic interface.

---

### 👤 Author & Team Credits
- **Lead Developer & Software Architect:** Shreesh Nalawade
- **Development Team:** Shravani Rane
- **Development Team:** Mrunal Shejwal
- **Development Team:** Samiksha Patil

- **Application Version:** `9.09.05`

---

## ✨ Key Features & Capability Matrix

### 📞 WebRTC 1-on-1 & Multi-Volunteer Video Calling
- **Multi-Volunteer Broadcast**: When a Blind User requests help, all active volunteers receive incoming call alerts simultaneously.
- **Atomic Call Claiming**: Firestore transactions ensure only one volunteer claims a call (`claimCallRequest`).
- **Real-Time Claim Dismissal**: When Volunteer A accepts first, all other volunteers hear *"This request was picked up by another volunteer"* with haptic feedback, and the screen automatically dismisses after 2 seconds.
- **Real-Time Cancel Handling**: If the Blind User cancels the call before connection, volunteers' phones stop ringing immediately, announce *"The call was cancelled by the user"*, and dismiss cleanly.
- **Auto-Disconnect Fix**: Active calls stay connected indefinitely until manually ended (ICE timeout timer cancelled on SDP answer).

### 🤖 Universal Vision AI & Age-Based Persona Adaptation
- **Groq Vision Engine**: Fast scene descriptions using `llama-3.2-11b-vision-instruct` with failover handling.
- **Age-Based Persona Adaptation**:
  - **Gen Z**: Casual, friendly, concise, energetic tone.
  - **Gen Alpha**: Upbeat, simple, enthusiastic explanations.
  - **Adult**: Structured, detailed, objective descriptions.
- **On-Device OCR & Object Detection**: Instant text reading via Google MLKit with full-screen gesture controls.

### 🛡️ Privacy & Security Controls
- **`FLAG_SECURE` Privacy Protection**: Native Android MethodChannel enforces `FLAG_SECURE` during live video calls to block volunteers from screenshotting or screen-recording the blind user's video feed.
- **Volunteer Notification Toggle**: Allows volunteers to opt out of incoming call popups via Settings.

### 🔍 Pinch-to-Zoom Camera Controls
- **Universal Pinch-to-Zoom**: Pinch in/out gesture scaling across `AI Assist`, `Read Text / OCR`, and `WebRTC Live Call` previews with safe max-zoom fallbacks.

### 🆘 Emergency SOS Broadcast
- **Location Sharing & Call Escalation**: One-tap SOS fetches GPS coordinates, creates an emergency record in Firestore, and broadcasts an urgent video call request to all available volunteers.

### 📳 System-Wide Tactile Haptics
- Tactile feedback (`HapticFeedback.mediumImpact()`, `selectionClick()`) across buttons, cards, camera gestures, and status transitions for accessibility.

---

## 🛠️ Technology Stack & 0-Cost Infrastructure

- **Framework**: Flutter (Dart 3.2+)
- **State Management**: Flutter Riverpod
- **Real-Time Calling**: `flutter_webrtc` (Peer-to-Peer video/audio over Google Public STUN `stun.l.google.com:19302`)
- **Backend & Signaling**: Firebase Firestore & Firebase Auth (Spark Free Tier)
- **AI Computer Vision**: Groq Cloud Vision API (Free Developer Tier)
- **On-Device ML**: Google MLKit (Object Detection & OCR)
- **Typography & Theme**: Google Fonts (Montserrat & Inter), Custom Glassmorphic Aesthetics

---

## 🚀 Quick Start Guide

### 1. Repository Setup
```bash
git clone https://github.com/shreesh-nalawade/VisionBridge.git
cd VisionBridge
flutter pub get
```

### 2. Environment Configuration (.env)
Create a `.env` file in the project root:
```env
GROQ_KEY_1=your_groq_api_key_account_1
GROQ_KEY_2=your_groq_api_key_account_2
GROQ_KEY_3=your_groq_api_key_account_3
```

### 3. Running the Application
Launch with compile-time environment injection:
```bash
flutter run --dart-define-from-file=.env
```

---

## 📱 Dual-Device Volunteer Call Testing

To test live video calls between **Blind User** (Device 1) and **Volunteer** (Device 2):

```bash
# Terminal 1 — Blind User Phone
flutter run -d <DEVICE_1_ID> --dart-define-from-file=.env

# Terminal 2 — Volunteer Phone
flutter run -d <DEVICE_2_ID> --dart-define-from-file=.env
```

---

## 📂 Project Architecture

```text
lib/
├── core/               # App constants (v9.09.05), themes, typography, router
├── features/
│   ├── auth/           # Login, registration, role selection
│   ├── blind_user/     # AI assist, OCR reader, in-call screen, SOS, settings
│   └── volunteer/      # Volunteer dashboard, incoming call dialog, active calls
├── services/           # WebRTC signaling, Call Orchestration, Groq Vision, Firestore
├── shared/             # GlassContainer, action cards, haptic buttons
└── main.dart           # App entry point & author metadata
```

---

## 📄 License & Intellectual Property
Copyright (c) 2005–2026 Shreesh Nalawade (`SN09092005`). All rights reserved. Refer to `COPYRIGHT.md` and `AUTHORS.md` for complete legal documentation.
