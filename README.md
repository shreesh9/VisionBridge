<div align="center">

# 👁️⚡ VisionBridge — EMPOWERING VISION 🌉

**The Next-Generation AI & Peer-to-Peer Assistive Platform for the Visually Impaired**

*Experience real-time scene narration, instant WebRTC volunteer connections, and seamless multi-lingual OCR in a beautiful, glassmorphic dark-mode interface.*

<p align="center">
  <img src="https://img.shields.io/badge/FLUTTER-3.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/DART-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/FIREBASE-BACKEND-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/WEBRTC-P2P_VIDEO-333333?style=for-the-badge&logo=webrtc&logoColor=white" />
  <img src="https://img.shields.io/badge/GROQ-VISION_AI-F55036?style=for-the-badge" />
</p>
<p align="center">
  <img src="https://img.shields.io/badge/STATE-RIVERPOD-1C1E24?style=for-the-badge" />
  <img src="https://img.shields.io/badge/ARCHITECT-SHREESH_NALAWADE-E91E63?style=for-the-badge" />
</p>

[Quick Start](#-quick-start-guide) · [Architecture](#-project-architecture) · [Report Bug](https://github.com/shreesh9/VisionBridge/issues)

</div>

---

## 📖 Overview

**VisionBridge** (`v9.0.5`) redefines assistive technology by combining ultra-low-latency **WebRTC video calling** with **Universal Groq Vision AI**. It provides blind and visually impaired users with instant, 1-on-1 human volunteer assistance and rapid, age-adapted scene narration.

Designed with a **pitch-black dark mode glassmorphism UI**, fluid liquid backgrounds, and system-wide tactile haptics, VisionBridge offers a premium, accessible experience with built-in **Hindi & English bilingual support** and a **7-language TTS engine**.

---

## 🌟 Key Features

| Feature | Description |
| :--- | :--- |
| 📞 **Multi-Volunteer WebRTC** | **Live Video Broadcasting.** Blind users broadcast to all available volunteers. Features **Atomic Call Claiming** (only one volunteer can answer) and Real-Time Dismissal with audio feedback for others. |
| 🤖 **Universal Vision AI** | **Groq `llama-3.2-11b-vision` Engine.** Fast scene descriptions with **Age-Based Persona Adaptation** (Gen Z, Gen Alpha, and Adult tones) tailored to the user. |
| 🗣️ **7-Language Bilingual TTS** | **Dynamic Multi-lingual Audio.** Full Hindi & English UI toggle. Smart **OCR Auto-Detect** reads text naturally in the detected language (7 total supported voices) without accent distortion. |
| 👁️‍🗨️ **On-Device OCR & ML** | **Google MLKit Integration.** Instant text recognition and reading via full-screen gesture controls. Features smooth **Pinch-to-Zoom** camera controls across all live previews. |
| 🛡️ **Privacy & Security** | **`FLAG_SECURE` Protection.** Enforces native Android security during live calls to block volunteers from screenshotting or screen-recording the user's video feed. |
| 🆘 **Emergency SOS** | **Instant Location Escalation.** One-tap SOS fetches GPS coordinates, logs to Firestore, and forces an urgent broadcast call to all active volunteers. |

---

## 🛠️ Technology Stack

- **Core Framework:** Flutter (Dart 3.2+)
- **State Management:** Flutter Riverpod
- **Real-Time Video:** `flutter_webrtc` (P2P over Google Public STUN `stun.l.google.com:19302`)
- **Backend & Auth:** Firebase Firestore & Firebase Authentication
- **AI Processing:** Groq Cloud Vision API & Gemini
- **On-Device ML:** Google MLKit (Object Detection & OCR)
- **Aesthetics:** Glassmorphic UI, Liquid Backgrounds, System Tactile Haptics

---

## 🚀 Quick Start Guide

### 1. Repository Setup
```bash
git clone https://github.com/shreesh9/VisionBridge.git
cd VisionBridge
flutter pub get
```

### 2. Environment Configuration
Create a `.env` file in the project root to securely inject your API keys:
```env
GROQ_KEY_1=your_groq_api_key_account_1
GROQ_KEY_2=your_groq_api_key_account_2
GROQ_KEY_3=your_groq_api_key_account_3
```

### 3. Launch the Application
Run the app with compile-time environment injection:
```bash
flutter run --dart-define-from-file=.env
```

---

## 📱 Dual-Device Testing Workflow

To test the live peer-to-peer video calling infrastructure between a **Blind User** and a **Volunteer**:

```bash
# Terminal 1 — Blind User Phone (Device 1)
flutter run -d <DEVICE_1_ID> --dart-define-from-file=.env

# Terminal 2 — Volunteer Phone (Device 2)
flutter run -d <DEVICE_2_ID> --dart-define-from-file=.env
```

---

## 📂 Project Architecture

```text
lib/
├── core/               # App constants (v9.0.5), themes, typography, router
├── features/
│   ├── auth/           # Login, registration, role selection
│   ├── blind_user/     # AI assist, OCR reader, in-call screen, SOS, settings
│   └── volunteer/      # Volunteer dashboard, incoming call dialog, active calls
├── services/           # WebRTC signaling, Call Orchestration, Groq Vision, Firestore
├── shared/             # GlassContainer, action cards, haptic buttons
└── main.dart           # App entry point & author metadata
```

---

## 👤 Development Team

- **Lead Developer & Software Architect:** Shreesh Nalawade
- **Development Team:** Shravani Rane, Mrunal Shejwal, Samiksha Patil

---

<div align="center">
  <p>Copyright © 2005–2026 Shreesh Nalawade. All rights reserved.</p>
</div>
