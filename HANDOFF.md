# 🤝 AI Handoff Document

> **Instructions for the AI:** Whenever you start a new session, READ this document first to understand the current state of the project. Whenever you finish a session, UPDATE this document with what you accomplished and what the next AI needs to do.

## 📌 Current Project State
- **Project Name:** VisionBridge (Flutter app — AI assistive app for visually impaired users)
- **Current Version:** v9.0.5
- **Task at Hand:** Complete Hindi & English bilingual support (TTS, OCR reading, UI switching)
- **Code State:** ✅ All bilingual code changes DONE + 3 follow-up fixes DONE (OCR crash, Groq model swap, persona wiring) + OCR root-cause fix round 2 (bundled Devanagari ML Kit model in gradle) + **VOICE-LAYER MULTI-LANGUAGE EXPANSION DONE** (7 languages: en, hi, mr, ta, te, bn, kn) + **NARRATION ACCENT BUG FIXED** (Fix 7) + **FULL UI TRANSLATION FOR ALL 7 LANGUAGES DONE** (Fix 8 — owner requested "op" mode; every screen now renders in the selected language). `flutter analyze` passes with **0 errors** (18 pre-existing lint infos/warnings remain — see "Known Issues"). **⚠️ The gradle change requires a FULL rebuild (`flutter clean` then `flutter run`) — hot reload/restart will NOT pick it up. Device verification still pending.**
- **Security:** No hardcoded API keys. Keys load via `--dart-define` or `assets/.env` (`GROQ_KEY_1..3`, `OPENROUTER_API_KEY`).

---

## 🆕 Session of 2026-10-01 (Freebuff/Buffy) — Paper Review + One Deferred Fix

### A. Research paper reviewed (owner request) — findings NOT yet applied to the doc
Reviewed "Research Paper VisionBridge.pdf" against the codebase and live sources. Verdict: structure is solid (ACE/CFE/VEE framing, Algorithm 1, latency table internally consistent: 34.2+48.6+165.1+1.8+37.8 = 287.5 ✓) but NOT submission-ready. Issues, in priority order (owner deferred all edits):
1. **Refs [24]/[25] are wrong/fabricated** (verified live). Correct: [24] R. Yu, S. Lee, J. Xie, S. M. Billah, J. M. Carroll, "Human–AI Collaboration for Remote Sighted Assistance: Perspectives from the LLM Era," *Future Internet*, vol. 16, no. 7, art. 254, 2024. [25] S. Lee, R. Yu, J. Xie, S. M. Billah, J. M. Carroll, "Opportunities for Human-AI Collaboration in Remote Sighted Assistance," *HAI '22* (ACM), 2022, DOI 10.1145/3490099.3511113.
2. **Paper cites dead models** (`llama-3.2-11b/90b-vision-preview` + fallback chain) — same deprecation that caused app Fix 2. Update Abstract/II/IV/Table II/ref [11] to `qwen/qwen3.8-27b` or generic "Groq Vision API (multimodal LLM)".
3. **IEEE placeholder footer** `XXX-X-XXXX-XXXX-X/XX/$XX.00 ©20XX IEEE` still in.
4. **"Agentic AI" in title never substantiated** — add a short agentic-loop framing or drop the word from the title.
5. **Paper is behind the app:** says EN/HI only + Devanagari OCR as *future work*; app already ships 7 languages + bundled Devanagari OCR (Fix 6/8). Update abstract, §IV-D, Table I ("ML Kit Latin"), Table II (locales), and move Devanagari OCR out of Future Work.
6. **Data inconsistencies:** combined latency avg is 291.2 ms, not 287.5 (accuracy/autonomy rows DO average correctly); setup says corridors <100 lux but table says outdoor <100; "both outdoor conditions" garbled → "both lighting conditions"; pick ONE 68% claim (calls vs bandwidth); acknowledge single-device testing.
7. **Citation hygiene:** [1] (WHO) cited ~20× incl. own results/figures; [12]/[13] miscited for Riverpod/GoRouter; [6],[7],[14]–[19],[21],[22] never cited in body; [23] says "Realtime Database" but app uses Cloud Firestore.
8. **Threshold mismatch:** paper θ=0.75 (range 0.50–0.95) vs app default 0.70 (range 0.50–0.90) in `user_settings_service.dart`. Reconcile.
9. **Typos:** "Impairment impacts" → "Visual impairment...", dropped θ/→ glyphs, "They. Do everything" broken sentence, double periods.

### B. DEFERRED (owner decision: "later"): ringing when volunteer app is killed/closed
Full diagnosis DONE this session — implement straight from these notes, no re-investigation needed:
- **Current flow:** BU writes `call_requests` → Cloud Function `onCallRequestCreated` (`firebase/functions/index.js`) queries `users` where `role==volunteer AND isOnline==true` → data-only high-priority FCM to each `fcmToken` → **Dart** background isolate (`firebaseMessagingBackgroundHandler` in `fcm_service.dart`) calls `FlutterCallkitIncoming.showCallkitIncoming`.
- **Root cause of no-ring-when-killed:** data-only FCM requires the Flutter background isolate to spawn and execute Dart. If the app was swiped away/force-stopped/OEM-killed, Dart never runs → no ringing UI. **Verified in plugin source (flutter_callkit_incoming-2.5.8): the plugin has ZERO native FCM/Firebase integration** (grep for FirebaseMessaging/RemoteMessage = 0 hits) — nothing rings without Dart code.
- **OS-level caveat (no workaround exists):** Android NEVER delivers FCM to force-stopped apps until the user re-opens the app once. Mitigation: in-app battery-optimization exemption prompt (permission already in manifest) + OEM "autostart" guidance (Xiaomi/Oppo/Vivo).
- **DESIGNED FIX (100% free, all local):** add a native Kotlin `FirebaseMessagingService` in `android/app` (e.g. `VBFcmService.kt`): in `onMessageReceived`, for data `type==INCOMING_CALL`, build a Bundle with the plugin's keys (see `CallkitConstants.kt`: `EXTRA_CALLKIT_ID`, `EXTRA_CALLKIT_NAME_CALLER`, `EXTRA_CALLKIT_TYPE=0`, `EXTRA_CALLKIT_DURATION`, `EXTRA_CALLKIT_TEXT_ACCEPT/DECLINE`, `EXTRA_CALLKIT_EXTRA`, `EXTRA_CALLKIT_RINGTONE_PATH='system_ringtone_default'`, `EXTRA_CALLKIT_IS_SHOW_FULL_LOCKED_SCREEN=true`...) and fire the plugin's broadcast: `Intent("${packageName}.com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING")` with extra `EXTRA_CALLKIT_INCOMING_DATA` = bundle (exactly what `CallkitIncomingBroadcastReceiver.getIntentIncoming()` does) → the native full-screen ringing UI shows with NO Dart involved. Handle `CANCEL_CALL` → `ACTION_CALL_ENDED` broadcast. Register in `AndroidManifest.xml`: `<service android:name=".VBFcmService" android:exported="false">` + `<intent-filter><action android:name="com.google.firebase.MESSAGING_EVENT"/></intent-filter>`. Cloud Function: remove the `isOnline==true` filter (killed apps can't heartbeat); keep token cleanup. Dart foreground path stays; dedupe double-ring by `callRequestId` if both paths fire.
- **Test recipe:** `adb shell am force-stop <package>` → BU calls → native ring must appear on locked screen. Then reopen app once (force-stop OS rule).

Owner is now device-testing everything already in this handoff (see Next Steps 0–2). Awaiting results before any new code changes.

---

## 🛠️ What Was Just Finished Coding (session of 2026-09-28, by Freebuff/Buffy)

### 1. `lib/services/tts_stt_service.dart` — TTS language race fix (root cause of the "Hindi accent reading English" bug)
- **Bug:** `speakWithLanguage()` restored the app locale *synchronously right after* `await _tts.speak(text)`. flutter_tts returns immediately (doesn't wait for utterance end), so switching language mid-synthesis could make Android synthesize the queued OCR utterance with the wrong voice.
- **Fix:**
  - Added `_tempLangRestore` flag. It is set when `speakWithLanguage()` switches to the detected text language, and cleared + restored to app locale **only inside** the TTS `completion`/`cancel`/`error` handlers (`_restoreAppLocaleVoiceIfTemp()`).
  - `speakWithLanguage()` clears the flag **before** calling `_tts.stop()` so the interrupted utterance's cancel handler can't race the language switch.
  - `speak()` now **self-heals**: it re-applies `_ttsLocaleTag(_currentLocaleCode)` before every utterance, so a leftover OCR voice can never leak into normal app narration.
- **Also fixed in `_parseCommand()`:** bare "मदद" was matching the emergency branch first and triggered SOS. Reordered so only unambiguous distress words (आपातकाल, बचाओ, खतरा, "help me", "emergency", "sos") → `VoiceCommand.emergency`; "मदद"/"help"/"आसपास" → `VoiceCommand.help`.

### 2. `lib/features/blind_user/presentation/screens/bu_call_history_screen.dart`
- **Compile error fixed:** used `UserSettingsService.getLocaleCode()` without importing it. Added `import '../../../../services/user_settings_service.dart';`
- Removed unused `successColor` local.

### 3. `lib/features/volunteer/presentation/screens/v_home_screen.dart`
- Converted `StatefulWidget` → `ConsumerStatefulWidget` and now `ref.watch(localeProvider)` in `build()`, syncing `_localeCode` — UI **live-updates** when the language toggle is flipped in settings (previously it loaded the locale once in `initState` and never refreshed).
- Localized the hardcoded-English `Semantics` label on the availability toggle.

### 4. `lib/features/volunteer/presentation/screens/v_incoming_call_screen.dart`
- "Accept" / "Decline" button labels localized (`स्वीकार करें` / `अस्वीकार करें`). Rest of the screen already had Hindi.

### 5. Auth flow — were 100% English-only, now fully bilingual:
- `lib/features/auth/presentation/screens/splash_screen.dart` → `ConsumerStatefulWidget`, tagline localized.
- `lib/features/auth/presentation/screens/login_screen.dart` → header, subtitle, Google button, divider text, phone/OTP labels + hints, "Send Verification Code", "Change Number", "Verify Code" all localized.
- `lib/features/auth/presentation/screens/role_selection_screen.dart` → header, intro, "I am...", both role cards (labels, subtitles, TTS on tap), name field + validator, submit button, role-not-selected snackbar + TTS. `initState` TTS greeting now reads locale from `UserSettingsService` and sets TTS language first. Added imports: `flutter_riverpod`, `locale_provider`, `user_settings_service`.

### 6. `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- Split the static `_slides` list into `_slidesEn` and `_slidesHi` (full Hindi translations of all 3 slides); `_slides(BuildContext)` helper picks by locale (uses `ref.read` — build already watches). Skip/Next/Get Started buttons, Semantics labels, page dots all localized. Converted to `ConsumerStatefulWidget`.

### 7. Cleanup
- Removed unused `user_settings_service.dart` import in `bu_home_screen.dart`.

**Files NOT touched this session (verified working, per handoff rules):** `vision_ai_service.dart` (pure-Hindi prompts + `_hiLabels` fallback already correct), `read_text_screen.dart` (Latin+Devanagari parallel OCR + `_detectTextLanguage` + `speakWithLanguage` already correct), both settings screens, `bu_home_screen.dart`, `sos_screen.dart`, `bu_in_call_screen.dart`, `v_in_call_screen.dart`, `groq_client.dart`, `ai_bridge_service.dart`, all services except `tts_stt_service.dart`.

---

## 🛠️ Follow-Up Fixes (SAME session continued, 2026-09-28, by Freebuff/Buffy)

User-reported: (a) OCR "Read Text Out Loud" button crashed the app every time, (b) Describe said "AI models unavailable", (c) Gen Z/Gen Alpha/Adult persona did nothing. All three fixed:

### Fix 1 — OCR crash (app shuts off when pressing Read Text)
- **Root cause (confirmed against flutter-ml/google_ml_kit_flutter issue #519):** the ML Kit text-recognition plugin crashes NATIVELY (app killed, no Dart exception) when 2+ `TextRecognizer`s are created/used at the same time. `read_text_screen.dart` held Latin AND Devanagari recognizers as long-lived `final` fields and ran them **in parallel** via `Future.wait` → guaranteed crash on scan.
- **Fix in `read_text_screen.dart`:** removed both field recognizers. New `_runRecognition(InputImage, TextRecognitionScript)` helper creates ONE recognizer, processes, and closes it in `finally`; the two scripts now run **sequentially** (Latin first, then Devanagari). Same merged quality as before (richer result wins), null-safe when one recognizer fails. There is a long explanatory comment on the helper — do not reintroduce parallel recognizers.

### Fix 2 — Describe "AI models unavailable" (Groq model deprecation)
- **Root cause:** Groq deprecated ALL `llama-3.2-*-vision` (and later Llama 4 vision) models. The code was calling dead model IDs → every key failed → user heard "AI vision models are currently busy."
- **Verified against live docs (console.groq.com/docs/models, Sept 2026):** Groq's ONLY current multimodal model is **`qwen/qwen3.8-27b`** (text+images input, OCR & visual QA listed as use cases, multilingual → still supports pure-Hindi descriptions, max 3 input images, 20 MB/file, each image = 2048 tokens, supports `reasoning_effort`).
- **Fix in `vision_ai_service.dart`:** `groqModels` list is now `['qwen/qwen3.8-27b']` — the loop still fans out across all 3 Groq keys, so failover per key is unchanged. Added `'reasoning_effort': 'none'` (documented param → instruct mode, fast non-thinking short descriptions). OpenRouter fallback list updated to `qwen3.8-27b:free` first, then the old 2.5-VL entries. A comment documents where to check for the successor when this model eventually deprecates.
- **Hindi purity unaffected:** the same strict Devanagari-only system prompt is sent to the new model.

### Fix 3 — Persona (Gen Z / Gen Alpha / Adult) wired in
- **Finding (user was right):** the setting saved fine, but the ACTIVE service (`vision_ai_service.dart`) never read it — persona prompts existed only in dead legacy `groq_client.dart`.
- **Fix (user chose "wire it in"):** `describeScene()` now also reads `UserSettingsService.getUserAgeGroup()` and appends a persona tone instruction to the system prompt — separate English & Hindi variants (genZ = casual/friendly, genAlpha = upbeat/simple, adult = no extra instruction). Works in both app languages; nothing else touched.

### Fix 4 — OCR crash round 2: REAL root cause = missing bundled Devanagari model (gradle)
- **User re-reported:** OCR still crashes the app ~1-2s after pressing Read Text, for BOTH English and Hindi scans.
- **True root cause (verified by reading the plugin source in pub cache):** `google_mlkit_text_recognition-0.13.1/android/build.gradle` declares ONLY Latin as `implementation 'com.google.mlkit:text-recognition:16.0.1'`. Devanagari (and Chinese/Japanese/Korean) are `compileOnly` — the classes compile but the **native Devanagari model is never packaged into the APK**. Instantiating a Devanagari recognizer at runtime kills the app natively. The sequential-recognizer change (Fix 1) didn't help because the Devanagari pass still ran on every scan.
- **Fix in `android/app/build.gradle`:** added a `dependencies` block with `implementation 'com.google.mlkit:text-recognition:16.0.1'` and `implementation 'com.google.mlkit:text-recognition-devanagari:16.0.1'` (with explanatory comment). This is the standard documented pattern for this plugin.
- **IMPORTANT for the next AI / user:** gradle changes are NOT picked up by hot reload or hot restart. Must run `flutter clean` then `flutter run` (or rebuild the APK) before testing. If OCR still crashes after a full rebuild, get `adb logcat` output — the next suspect would be a device-specific native issue, not Dart code.
- Fix 1 (sequential recognizers) remains REQUIRED — running two recognizers in parallel also crashes per flutter-ml issue #519. Both fixes together are the complete solution.

### Fix 5 (assessment only, NOT implemented) — Multi-language expansion (5-6 more Indian languages)
- **User question:** how easy/safe is adding Tamil/Telugu/Marathi/Bengali/Kannada etc. with full implementation like Hindi?
- **Assessment given to owner:**
  - EASY + LOW RISK: TTS locale switch (`tts_stt_service.dart` `_ttsLocaleTag`), AI Describe per-language prompts (`vision_ai_service.dart`), OCR reading (per-script Unicode block in `_detectTextLanguage` + one gradle `implementation` line per bundled ML Kit script model — now proven). Costs: slightly slower scans (sequential passes per script) and ~5-8 MB APK growth per script model.
  - HARD + RISKY: UI translation. ~15 screens use inline `isHindi ? ... : ...` ternaries with no translation table; a third UI language forces refactoring every screen to ARB/map lookup — high regression surface.
  - **RECOMMENDED (not yet approved/implemented): "voice-layer" expansion** — add languages for everything the user HEARS (TTS, AI descriptions, OCR reading, voice-command keywords) while keeping visual UI EN/HI only. Await owner go-ahead before implementing.

### Fix 6 (IMPLEMENTED) — Voice-layer multi-language expansion (owner approved)
- **Owner decision:** implement the voice-layer option from Fix 5. Visual UI intentionally stays EN/Hindi.
- **Languages added: Marathi (mr), Tamil (ta), Telugu (te), Bengali (bn), Kannada (kn)** alongside en/hi.
- **NEW FILE `lib/core/locale/supported_voice_languages.dart` — the single source of truth:** `VBLanguage` model (code, nativeName, englishName, ttsTag, scriptFlag, aiPromptLanguage, voiceKeywords) + `VBLanguages` registry (en/hi/mr/ta/te/bn/kn) with per-language: voice-command keyword sets, on-device fallback sentences (objects/no-objects), "AI busy" + rate-limit errors, description CTAs, empty-description strings, and `scriptOfRune()` Unicode-block classifier (devanagari/bengali/dravidian/latin). To add a future language: add one `VBLanguage` constant + its strings + voice keywords, push to `VBLanguages.all` — everything else picks it up automatically.
- **`tts_stt_service.dart`:** `_ttsLocaleTag` now delegates to the registry (mr-IN/ta-IN/te-IN/bn-IN/kn-IN TTS+STT tags). `_parseCommand` REWRITTEN: iterates ALL languages' keyword sets from the registry; Latin keywords use word-boundary regex (so "no" doesn't fire inside "know"/"recall"), Indic keywords use substring match; emergency checked FIRST because some languages share distress/help words (Marathi "मदत करा" contains "मदत"); plain "मदद"/"help" still never triggers SOS. `speakWithLanguage` now maps any Devanagari OCR result ('hi') to the app's Devanagari voice language — Marathi users hear scanned Devanagari signs in Marathi.
- **`vision_ai_service.dart`:** prompts generated per language — strict "pure <language> in native script, never English words" system prompt for all Indic languages (same anti-Hindi-accent guarantee generalized); persona tone suffix applies to every language; on-device fallback + errors + CTAs now delegate to the registry; `_cleanModelResponse` takes `VBLanguage` and skips English-only heuristics for any non-Latin language.
- **`bu_settings_screen.dart` + `v_settings_screen.dart`:** EN/हि segmented buttons REPLACED by a language-picker bottom sheet listing all 7 languages (native name + English subtitle, checkmark on current). Picker title is bilingual EN/Hindi since UI stays 2-language. Selecting stores via the same `localeProvider`/`UserSettingsService` — persisted, back-compatible.
- **`read_text_screen.dart`:** `_detectTextLanguage` upgraded to classify en/hi/ta/te/bn/kn by Unicode blocks. **HARD LIMITATION discovered (checked plugin source): `google_mlkit_text_recognition` 0.13.x only ships Latin/Devanagari/CJK recognizers — NO Tamil/Telugu/Bengali/Kannada on-device OCR exists.** Scans of those scripts return "No text found". Their OCR read-aloud would require Google Cloud Vision (server-based, needs billing) — documented for future decision. Everything else for those languages is fully live.
- **What stays EN/Hindi-only (by design):** all screen text, buttons, labels. `supportedLocales` in `main.dart` stays [en, hi]. `locale_provider` now legitimately stores 7 codes; UI screens' `isHindi` ternaries still work because non-hi codes fall back to the English side — EXCEPT pure Devanagari UI nuances for mr users (acceptable: mr UI shows English, voice speaks Marathi).

### Fix 7 — Narration accent bug (owner-reported after Fix 6): English strings spoken by Indic voices
- **Owner report:** with Marathi selected, Describe spoke Marathi correctly, but UI narration and other TTS prompts were ENGLISH text spoken with a MARATHI accent. Cause: ~50 spoken strings across screens were chosen by `_localeCode == 'hi' ? hindi : english` ternaries — for any language other than hi they emit English text while the TTS engine uses the Indic voice.
- **Fix (architectural, registry-driven):** added a `VoiceKey` enum + `voiceStrings` map per language in `supported_voice_languages.dart` — REAL translations of all narration strings in all 7 languages (camera ready/permission, analyzing, connecting volunteer, scanner prompts, OCR errors, all SOS strings incl. countdown with {n} placeholder, role-selection prompts, persona confirmations, speed/pitch previews, incoming-call announcements, request-cancelled/claimed-by-other, language-changed confirmations). New helpers: `voice(key)`, `voiceN(key, n)`, `readAloudPrefix()`, `personaUpdated(group)`.
- **Rewired EVERY `speak()` call site** to the registry: `ai_assist_screen.dart` (permission, ready, analyzing, connecting/failed/sign-in, status texts), `read_text_screen.dart` (scanner ready, scanning, no-text, OCR error), `sos_screen.dart` (all 6 prompts), `role_selection_screen.dart` (profile prompt, both role taps, please-select-role), `v_incoming_call_screen.dart` (ring announcement, cancelled, claimed-by-other), `bu_settings_screen.dart` (speed/pitch previews, persona change, language-changed confirmation in the NEW language).
- **OCR prefix semantics restored:** "पढ़ा गया टेक्स्ट: " now follows the EFFECTIVE voice language of the utterance (via new `TTSSTTService.effectiveVoiceLanguageCode()`), not the app language — an English user scanning Hindi text still hears the Hindi announcement in the Hindi voice. English scans still have no prefix (original behavior).
- **`main.dart` hardening:** Material `locale` is clamped to en/hi (`supportedLocales` only has EN/Hindi ARBs). Voice-only codes (mr/ta/te/bn/kn) map to Hindi UI; previously an unsupported Material locale could cause unexpected fallbacks.
- **Deliberate scope:** visible button/label TEXT in mr/ta/te/bn/kn still shows the English string (UI is EN/Hindi by design from Fix 5). What changed is that everything SPOKEN is now genuinely in the selected language. If owner later wants full UI text, that's the ARB migration.

### Fix 8 — FULL UI translation for all 7 languages (owner: "that would actually be op... if not lets add it")
- **Owner question first (answered):** is full UI text for 5 new languages heavy for the app? NO — strings are const-map lookups (constant time), APK grows ~100 KB, Android system fonts render all Indic scripts natively, zero impact on camera/WebRTC/ML Kit. The only real cost was translation content, now written.
- **Owner's build warnings question (answered):** the `source/target value 8 is obsolete` + `uses deprecated/unchecked API` warnings come from Google's ML Kit plugin Java code (their build.gradle targets Java 8, their classes use old APIs). Not our code, zero runtime impact, seen by every Flutter app using ML Kit — safe to ignore.
- **What changed in the registry:** added `UIKey` enum (~110 keys) + per-language `uiStrings` maps for ALL 7 languages (full translations of every screen string) + `ui(key)` / `uiX(key, x)` helpers. `voice()` narration system from Fix 7 unchanged and coexists.
- **Every screen converted to the registry (no more `isHindi ? ... : ...` ternaries in any screen):** splash, login, role selection, onboarding (all 7 slide sets incl. 5 new translations), BU home, V home, BU/V call history, BU/V in-call, incoming call, SOS, AI assist status texts, read-text, BU/V settings (section headers, tiles, persona tile now takes translated title/desc params). Language picker titles also registry-driven.
- **`main.dart`:** Material `locale` is now the raw stored locale again — safe because every voice language has full UI strings; `supportedLocales` still only declares en/hi ARBs, so MaterialApp locale-resolution falls back per Flutter's algorithm (English ARB is the template; non-listed locales resolve to the closest). No visible regressions expected; if a screen ever shows English under mr/ta/te/bn/kn, check that MaterialApp locale resolution, NOT the registry.
- **Verification note for next AI:** the registry now has ~110 UI keys × 7 languages + ~35 voice keys × 7 languages. If any key is ever missing in one language, `ui()`/`voice()` throws — `flutter analyze` catches missing keys only in const contexts, so run the app through ALL screens once per language (or write a simple test iterating `VBLanguages.all` asserting every map contains every key — recommended, ~20 lines).

---

## 🐞 Errors / Bugs Currently Happening

**Known compile errors: NONE.** `flutter analyze` = 0 errors (verified, 6.8s run).

**Runtime bugs: the user-reported bugs above are FIXED in code but NOT yet device-verified.** Additionally, the NEW known limitation (not a bug in our code): Tamil/Telugu/Bengali/Kannada OCR is impossible on-device with the current ML Kit plugin (no recognizer exists) — those scans will say "No text found"; see Fix 6. Beyond that, treat the following as unverified-until-tested:
1. The TTS race fix is logic-correct by code review but has never run on hardware. Some Android TTS engines fire `completion`/`cancel` handlers unreliably — if that happens, the residual risk is: after an OCR utterance, the engine could stay on the detected language until the next `speak()` call (which self-heals). Worst case is bounded, not cascading.
2. Hindi TTS voice availability depends on the device having a Hindi voice installed (Google TTS usually does). If `setLanguage('hi-IN')` fails on a test device, that's an environment issue, not a code bug.
3. The OCR "no text found" prefix behavior: Hindi scans get a "पढ़ा गया टेक्स्ट: " prefix, English scans get none (intentional, in `read_text_screen.dart`).

**Pre-existing lint warnings (18 total, NOT from this session, do NOT block anything):**
- `login_screen.dart`: unused `_handleBypassLogin` (dev bypass helper — ask the owner before deleting).
- `ai_assist_screen.dart`: unused `_isDetecting` field, unused `callRequestId`/`surfaceColor`/`subtextColor` locals, 4× `prefer_const`.
- `v_in_call_screen.dart`: 3× `prefer_const`.
- `bu_settings_screen.dart` + `v_settings_screen.dart`: 5× `use_build_context_synchronously` infos.

**Architectural debt (not bugs):**
- `lib/l10n/app_en.arb` + `app_hi.arb` + `l10n.yaml` are **dead code**: only `main.dart` wires `AppLocalizations`; all strings now live in `supported_voice_languages.dart` (Fix 8). Either delete the l10n setup or leave as-is.
- `groq_client.dart` + `ai_bridge_service.dart` are unused legacy duplicates of `vision_ai_service.dart` (zero screen references). Safe deletion candidates — confirm with owner first.

---

## 🎯 Next Steps for the Incoming AI (pick up exactly here)

0. **Owner is currently device-testing Fixes 1–8 on hardware.** WAIT for owner's test results before changing code. If failures come back, debug per the verification checklists below.
0b. **Deferred (explicit owner decision, do NOT start unprompted):** killed-app ringing fix — full design + root cause documented in section B above; implement only when owner says go. Paper corrections (section A) also await owner go-ahead.
0c. **Verify Fix 4 with a FULL rebuild (do this first):** `flutter clean` → `flutter run` (gradle changes are invisible to hot reload!). Then OCR: press **Read Text Out Loud** repeatedly, scan English text AND a Hindi sign — app must not close, speech must match the scanned language. If it STILL crashes after a clean rebuild, capture `adb logcat` and investigate native logs (suspects: device-specific ML Kit issue, minify/R8 in release builds).
1. **Verify Fix 6+7+8 (multi-language, FULL UI) on device:** Settings → Language / भाषा → picker opens with 7 languages. Pick each of mr/ta/te/bn/kn: (a) the ENTIRE UI renders in that language (home, settings, call screens, histories — Fix 8), (b) ALL narration is in the selected language — NO English-with-accent anywhere (Fix 7), (c) the language-changed confirmation speaks in THAT language, (d) Describe Scene speaks pure <language>, (e) voice commands per language (Marathi "मदत करा" → SOS, "मदत" → help), (f) OCR: Devanagari sign with mr selected → Marathi voice; English page with mr selected → English voice with no prefix; Tamil sign → "No text found" (known limitation). Requires the device to have that Google TTS voice installed (Settings → Text-to-speech).
2. **Verify Fix 2 & 3 on device:** Describe must return a real description via `qwen/qwen3.8-27b` (not "AI models are busy") — if it fails, log the Groq response body (error string includes status + body; could be key quota, not model). Persona: switch Gen Z ↔ Adult in Settings, run Describe in EN and हि, tone should shift.
2. **Then — on-device bilingual verification (from previous part of session):**
   - `flutter run` on device, sign in, go to Settings → Language → switch to हि.
   - Confirm EVERY screen renders Hindi: onboarding, login, role selection, splash, BU home, AI assist, read text, SOS, call history, in-call, and the same on the volunteer side (home, settings, incoming call, in-call, history).
   - AI Assist → Describe: spoken description must be **pure Hindi** (no English words, no English-with-Hindi-accent).
   - Read Text: scan an English page → spoken in English voice. Scan a Hindi sign/banner → spoken in pure Hindi voice. Both must be independent of the app toggle.
   - Say "मदद" as a voice command → must NOT trigger SOS (should trigger help). Say "आपातकाल" → must trigger SOS.
   - Toggle language in settings while on other screens → UI should update live (BU home + V home watch the provider).
   - If any speech comes out with the wrong language/voice, suspect `tts_stt_service.dart` handlers first — log `setLanguage` return values (Android can report per-utterance voice issues via `setEngineHandler`/engine choice).
3. **Optional next expansion:** add Google Cloud Vision OCR for Tamil/Telugu/Bengali/Kannada signs (server-based, needs billing + API key via .env) OR keep on-device Latin/Devanagari only. Also consider verifying that mr/ta/te/bn/kn TTS voices exist on common target devices (Google TTS usually offers them via downloaded voices).
4. **If device tests pass:** fix the pre-existing lint warnings listed above (low risk, mechanical).
5. **Optional cleanup (ask owner first):** delete `groq_client.dart` + `ai_bridge_service.dart`; either migrate to ARB l10n or delete `l10n.yaml` + `lib/l10n/` + the `AppLocalizations` wiring in `main.dart` + `flutter_localizations`/`intl` deps if unused elsewhere.
6. **Safety constraint (carried over):** Do NOT break existing functionality. Only touch bilingual/TTS logic; avoid refactoring working flows (camera lifecycle, WebRTC, call orchestration).

---
**Last Updated By:** Freebuff (Buffy)
**Date/Time:** 2026-10-01
