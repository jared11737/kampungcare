<p align="center">
  <img src="https://img.shields.io/badge/KitaHack_2026-GDG_Malaysia-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="KitaHack 2026"/>
  <img src="https://img.shields.io/badge/SDG_3-Good_Health_&_Well--Being-4C9F38?style=for-the-badge" alt="SDG 3"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

<h1 align="center">KampungCare</h1>

<p align="center">
  <strong>AI-Powered Elderly Care Companion for Malaysia</strong><br/>
  <em>"Sayang jaga, kampung lindungi"</em> — Sayang cares, the kampung protects
</p>

<p align="center">
  <a href="https://kampung-care-app.web.app/">Live Demo</a> ·
  <a href="#technical-architecture">Architecture</a> ·
  <a href="#implementation-details">Implementation</a> ·
  <a href="#challenges-faced">Challenges</a> ·
  <a href="#future-roadmap">Roadmap</a>
</p>

---

## The Problem

**80+ solitary elderly deaths** were reported in Malaysia between 2022–2024. With 2.6 million seniors aged 65+ — many living alone in kampungs — the gap between family presence and actual care is widening.

- **Medication non-adherence** — 50% of elderly patients forget or incorrectly take medications
- **Delayed emergency response** — elderly living alone cannot call for help during falls or health crises
- **Social isolation** — loneliness accelerates cognitive decline and depression
- **Caregiver burden** — families living far away have no visibility into daily well-being

## Our Solution

**KampungCare** is an AI-powered mobile companion that brings the warmth of kampung community care into the digital age. At its heart is **Sayang** — a conversational AI companion that speaks Bahasa Melayu and builds genuine emotional connections with elderly users.

### Voice-First, Screen-Second

Elderly users shouldn't feel like they're using an app. Sayang speaks to them like a caring grandchild — conducting morning check-ins, reminding about medications, and simply being there to listen. The screen is a fallback, not the primary interface.

### Key Features

| Feature | Description |
|---------|-------------|
| **AI Voice Companion** | Natural Bahasa Melayu conversations powered by Gemini; remembers personal context (family, hobbies, medical history) |
| **Morning Check-Ins** | Full-screen call-like notification; Sayang assesses mood, pain, and sleep through natural conversation |
| **Medication Management** | Voice reminders + photo verification via Gemini Vision; tracks adherence and missed doses |
| **SOS Emergency** | 120dp red button on home screen; broadcasts GPS + health data to care network; auto-escalates to 999 |
| **Community Alerts** | Missed check-ins trigger escalation: buddy → caregiver → emergency services (60–90 second flow) |
| **Caregiver Dashboard** | Real-time green/yellow/red status for each elder; weekly AI-generated health summaries |
| **Health Monitoring** | 14-day health logs (mood, pain, sleep); AI pattern analysis detects anomalies early |

### Three User Roles

| Role | Who | What They See |
|------|-----|---------------|
| **Warga Emas** (Elderly) | The primary user | Voice companion, medication reminders, SOS button, daily check-ins |
| **Penjaga** (Caregiver) | Family member / professional | Dashboard with health status, alerts, weekly AI reports |
| **Buddy** | Neighbour / community volunteer | Simple alert notifications, check-in confirmations |

---

## Technical Architecture

### System Overview

```
┌──────────────────────────────────────────────────────┐
│                    Flutter App                        │
│  ┌─────────┐  ┌──────────┐  ┌───────────────────┐   │
│  │ Screens  │  │ Widgets  │  │  GoRouter (RBAC)  │   │
│  └────┬─────┘  └────┬─────┘  └────────┬──────────┘   │
│       └──────────────┼─────────────────┘              │
│                      ▼                                │
│              ┌──────────────┐                         │
│              │   Riverpod   │  State Management       │
│              │  Providers   │  & Dependency Injection  │
│              └──────┬───────┘                         │
│                     ▼                                 │
│          ┌─────────────────────┐                      │
│          │   Service Locator   │  Mock ↔ Real swap    │
│          └──┬──┬──┬──┬──┬──┬──┘                      │
│             │  │  │  │  │  │                          │
│             ▼  ▼  ▼  ▼  ▼  ▼                         │
│  ┌─────┬─────┬────┬───────┬────────┬──────────┐      │
│  │Auth │ DB  │ AI │ Voice │Notif.  │ Location │      │
│  │     │     │    │(STT/  │(Local) │          │      │
│  │     │     │    │ TTS)  │        │          │      │
│  └─────┴─────┴────┴───────┴────────┴──────────┘      │
└──────────────────────────────────────────────────────┘
         │           │           │
         ▼           ▼           ▼
   ┌──────────┐ ┌──────────┐ ┌──────────────┐
   │ Firebase │ │ Gemini   │ │ Device APIs  │
   │ Auth +   │ │ API      │ │ (Speech,     │
   │Firestore │ │ (Chat +  │ │  Camera,     │
   │ + FCM    │ │  Vision) │ │  GPS)        │
   └──────────┘ └──────────┘ └──────────────┘
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x + Material 3 | Cross-platform UI with elderly-accessible design |
| **State Management** | Riverpod 2.6 | Reactive state + dependency injection bridge |
| **Routing** | GoRouter 14 | Declarative routing with RBAC guards |
| **AI** | Google Gemini API | Conversational AI + medication photo verification |
| **Voice** | `speech_to_text` + `flutter_tts` | On-device STT/TTS (works offline) |
| **Backend** | Firebase (Auth, Firestore, FCM, Functions) | Authentication, real-time data, push notifications |
| **Notifications** | `flutter_local_notifications` | Full-screen lock-screen alerts for check-ins |
| **Location** | `geolocator` | GPS coordinates for SOS emergency broadcasts |
| **Charts** | `fl_chart` | Health trend visualization |

### Mock-First Service Layer

KampungCare uses a **mock-first architecture** that allows the app to run fully offline without any cloud dependencies:

```dart
// Abstract interface — defines the contract
abstract class AuthServiceBase {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> signInWithPhone(String phone);
}

// Mock implementation — works offline with demo data
class MockAuthService extends AuthServiceBase { ... }

// Real implementation — connects to Firebase
class FirebaseAuthService extends AuthServiceBase { ... }

// ServiceLocator swaps between mock ↔ real at runtime
class ServiceLocator {
  static bool useMocks = true;  // flip to false for production
  static AuthServiceBase get auth =>
      useMocks ? MockAuthService() : FirebaseAuthService();
}
```

Judges can explore the full app at [kampung-care-app.web.app](https://kampung-care-app.web.app/) — all features are functional with realistic mock data, no API key needed.

### Riverpod Provider Architecture

```
service_providers.dart (DI Bridge)
    ├── authServiceProvider      → AuthServiceBase
    ├── databaseServiceProvider  → DatabaseServiceBase
    ├── aiServiceProvider        → AiServiceBase
    └── voiceServiceProvider     → VoiceServiceBase

Data Providers (consume DI bridge — never call ServiceLocator directly)
    ├── authStateProvider        → Stream<UserModel?>
    ├── currentUserProvider      → UserModel
    ├── medicationsProvider      → List<Medication>
    ├── healthLogsProvider       → List<HealthLog> (14 days)
    ├── alertsProvider           → List<Alert>
    ├── careNetworkProvider      → List<CareNetworkMember>
    ├── conversationsProvider    → List<Conversation>
    └── voiceChatProvider        → VoiceChatNotifier (state machine)
```

### Security

- **Route guards:** GoRouter redirect enforces role-based access (`/elderly/*`, `/caregiver/*`, `/buddy/*`)
- **Input validation:** Phone `^\+60[1-9]\d{8,9}$`, OTP `^\d{6}$`, chat type whitelist, medication ID sanitization
- **SOS protection:** UID verification + 60-second rate limiting prevents unauthorized or accidental triggers
- **Privacy:** PII-free logging, camera images auto-deleted on screen dispose
- **Demo safety:** Debug FAB only renders when `kDebugMode == true`

---

## Implementation Details

### Voice Conversation Engine

The `VoiceChatNotifier` manages the entire voice interaction lifecycle as a state machine:

```
initializing → aiSpeaking → listening → processing → aiSpeaking → ... → ended
```

Each conversation type uses a specialized Gemini prompt:
- **Check-in** — structured health assessment (mood, pain, sleep extraction)
- **Cerita (Story)** — warm, open-ended storytelling with higher temperature (0.7)
- **Casual** — everyday conversation, remembers personal context
- **Concerning** — triggered by anomaly detection, gently probes health issues

The screen (`VoiceChatScreen`) is a thin UI shell — holds only the `AnimationController` and text fallback. All business logic lives in the notifier.

### Medication Photo Verification

```
Camera Capture → Gemini Vision API → JSON Response → Verification
     │                  │                    │
     ▼                  ▼                    ▼
 Image file      Content.multi([       { "verified": true,
 (auto-deleted    TextPart(prompt),      "medication": "Metformin",
  on dispose)     DataPart(bytes)        "dosage": "500mg" }
                 ])
```

Temperature set to `0.3` for reliable data extraction. All `jsonDecode` calls wrapped in try/catch.

### SOS Emergency Flow

```
User taps SOS → Auth check (uid == currentUser) → Rate limit (60s)
     │
     ├── Broadcast GPS + health packet to care network
     ├── Push notification to all buddies
     ├── Push notification + SMS to all caregivers
     └── Auto-call 999 after 60 seconds (if not cancelled)
```

### Elderly-First UI Design

| Principle | Implementation |
|-----------|---------------|
| **Touch targets** | Minimum 64dp (50% larger than Material default) |
| **Text size** | Minimum 20sp (legible without reading glasses) |
| **SOS button** | 120dp — impossible to miss |
| **Gestures** | Single-tap only — no swipe, long-press, or double-tap |
| **Contrast** | WCAG AA compliant color palette |
| **Haptics** | `HapticFeedback.mediumImpact()` on every primary action |
| **Wakelock** | Screen stays on during voice conversations |
| **Accessibility** | Every tappable element has `Semantics(button: true, label: '...')` |

### Project Structure

```
lib/
├── config/           # Theme, routes (GoRouter + RBAC), constants
├── data/             # Mock data seed (3 demo users)
├── models/           # 13 data models (@JsonSerializable)
├── providers/        # 9 Riverpod providers (DI bridge + data)
├── screens/          # 15+ screens organized by role
│   ├── onboarding/   #   Login, OTP, role selection
│   ├── elderly/      #   Home, voice chat, medication, health
│   ├── caregiver/    #   Dashboard, alerts, care network
│   └── buddy/        #   Simplified notification interface
├── services/         # 10 service modules (abstract + mock + real)
├── widgets/          # 10 reusable components
└── main.dart         # Entry point — 62+ Dart files total
```

---

## Challenges Faced

### 1. Voice-First UX for Non-Tech-Savvy Users

**Challenge:** Designing an interface where the primary interaction is voice — for users who may never have used a smartphone app.

**Solution:** We modeled the voice interaction after a phone call — the most familiar voice interface for elderly Malaysians. Check-in notifications mimic an incoming call with a full-screen green "answer" button. Sayang uses kampung dialect and familiar phrases. The screen exists only as a visual fallback.

### 2. Offline-First in Rural Malaysia

**Challenge:** Many elderly in kampung areas have unreliable internet. Core features cannot fail when connectivity drops.

**Solution:** The mock-first architecture means critical features (voice STT/TTS, local notifications, medication reminders) use on-device APIs that work completely offline. `speech_to_text` and `flutter_tts` use the device's built-in speech engines — no internet required. Firebase syncs when connectivity returns.

### 3. Balancing AI Safety with Warmth

**Challenge:** Gemini needs to feel like a caring family member, not a clinical chatbot — while still detecting health concerns and escalating appropriately.

**Solution:** Separate conversation modes with tailored prompts — casual chat uses higher temperature (0.7) for natural warmth, while health check-ins use structured prompts that extract specific data points (mood 1-5, pain level, sleep quality). A persistent AI memory system (personal facts, recent topics, conversation patterns) makes interactions genuinely personal.

### 4. Emergency SOS Reliability

**Challenge:** SOS is life-critical — it must work instantly without false triggers or being blocked at the wrong moment.

**Solution:** UID-verified triggers prevent unauthorized SOS calls. A 60-second rate limit prevents accidental repeats while allowing legitimate emergencies. The escalation chain (buddy → caregiver → 999) ensures help arrives even if one contact is unavailable.

### 5. Hackathon Timeline vs. Production Quality

**Challenge:** Building a full-featured elderly care platform in 6 weeks while maintaining code quality for a health-critical application.

**Solution:** The mock-first architecture was the key enabler — we could build and demo all features without waiting for backend setup. Features were prioritized by impact: voice companion → medication management → SOS → caregiver dashboard. Robust error handling was reserved for safety-critical paths only.

---

## Future Roadmap

### Phase 1: Production Launch (Q2 2026)
- [ ] Complete Firebase migration (Auth, Firestore, FCM, Cloud Functions)
- [ ] Real Gemini API integration with production keys
- [ ] Phone OTP authentication via Firebase Auth
- [ ] Publish to Google Play Store

### Phase 2: Health Integration (Q3 2026)
- [ ] Wearable device integration (heart rate, step count, fall detection)
- [ ] Integration with Malaysian health systems (MySejahtera, KPJ)
- [ ] Blood pressure and glucose tracking via Bluetooth devices
- [ ] Automated medication refill reminders linked to pharmacies

### Phase 3: Community Expansion (Q4 2026)
- [ ] Multi-language support (Tamil, Mandarin, English)
- [ ] Community volunteer matching — connect buddies with nearby elders
- [ ] Government agency integration (JKM — Jabatan Kebajikan Masyarakat)
- [ ] Telehealth video consultations with geriatric specialists

### Phase 4: AI Enhancement (2027)
- [ ] Predictive health analytics — detect decline patterns weeks before crisis
- [ ] Cognitive assessment through conversation analysis
- [ ] Emotion recognition from voice tone and speech patterns
- [ ] Personalized medication optimization suggestions

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android SDK (minSdk 23, targetSdk 34)
- Gemini API key (optional — app works fully with mock data)

### Run Locally

```bash
# Clone the repository
git clone https://github.com/jared11737/kampungcare.git
cd kampungcare

# Install dependencies
flutter pub get

# Run with mock data (no API key needed)
flutter run

# Run with real Gemini AI
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### Demo Users (Mock Mode)

| User | Role | Phone |
|------|------|-------|
| Mak Cik Siti | Warga Emas (Elderly) | +60123456789 |
| Aisyah | Penjaga (Caregiver) | +60198765432 |
| Kak Zainab | Buddy | +60167891234 |

---

## Live Demo

**[kampung-care-app.web.app](https://kampung-care-app.web.app/)**

---

## Team

Built for **KitaHack 2026** by GDG Malaysia participants.

**Target SDGs:** SDG 3 (Good Health & Well-Being) · SDG 9 (Industry, Innovation & Infrastructure) · SDG 10 (Reduced Inequalities) · SDG 11 (Sustainable Cities & Communities)

---

<p align="center">
  <em>"Dalam kampung, tiada siapa yang keseorangan."</em><br/>
  In a kampung, no one is alone.
</p>
