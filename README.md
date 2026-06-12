# Personal Haven 🌿

A private, all-in-one wellness and personal management app built with Flutter. Personal Haven gives you a safe space to journal, track your mood, manage goals, budget, food diary, calendar events, and tasks — all secured behind biometric lock and backed by Firebase.

---

## Features

### 🔐 Authentication
- Sign in with **Google**, **Apple**, or **Microsoft** (via Firebase Auth)
- **Biometric lock** (Face ID / Fingerprint) — prompts on app open and resume
- Free **30-day trial** activated automatically on first sign-up

### 📓 Journal
- Unlimited journal entries with categories, emoji, and tags
- Full-text search and category filtering
- Entry statistics and streak tracking

### 😊 Mood Tracker
- Daily mood logging with emoji and notes
- Weekly and monthly mood charts
- Mood insights screen with trend analysis

### 🎯 Goals
- Create and track personal goals with progress bars
- Category filtering (fitness, finance, learning, personal)
- Deadline approaching and completion notifications

### ✅ Tasks & Rituals
- Task management with priorities (urgent / high / medium / low)
- Due today, overdue, and upcoming views
- Swipe to complete, category grouping

### 📅 Calendar
- Monthly calendar with event dots
- Add events with title, description, and time
- 1-hour-before push notification reminders
- Swipe to delete events

### 💰 Budget Tracker
- Income and expense tracking
- Category breakdown with spending summaries
- Monthly totals and weekly charts

### 🥗 Food Diary
- Log meals by type (breakfast / lunch / dinner / snack)
- Calorie and macro tracking (protein, carbs, fat)
- Daily totals and weekly averages

### 🔔 Notifications
Granular per-category controls in Settings:
| Notification | Time |
|---|---|
| Morning check-in | 8:00 AM daily |
| Evening mood log | 8:00 PM daily |
| Journal prompt | 9:00 PM daily |
| Meal reminder | 1:00 PM daily |
| Weekly mood summary | Sunday 6:00 PM |
| Task due today | On task creation |
| Task overdue | On task creation |
| Goal deadline (3d / 1d) | On progress update |
| Goal completed 🏆 | On progress update |
| Event reminder | 1 hour before |
| Subscription expiring | 3 days and 1 day before |
| Subscription expired | On expiry |

### 💳 Subscriptions
| Plan | Price |
|---|---|
| Free Trial | 30 days on sign-up |
| Weekly | KES 30 / week |
| Monthly | KES 100 / month |

**Payment methods:** M-Pesa (STK push), App Store / Play Store (in-app purchase), Card, USDT

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend / Auth | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Social Sign-In | google_sign_in, sign_in_with_apple, flutter_appauth |
| In-App Purchases | flutter_inapp_purchase |
| Notifications | flutter_local_notifications + timezone |
| Biometrics | local_auth |
| Payments | M-Pesa Daraja API (HTTP) |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/          # Colors, strings, styles, API config
│   └── utils/              # Biometrics, validators, date utils
├── data/
│   ├── models/             # User, Journal, Mood, Task, Goal, Budget, Event, Food, Subscription
│   └── repositories/       # Firestore CRUD for every model
├── providers/              # Riverpod state notifiers
├── services/
│   ├── firestore_service.dart
│   ├── social_auth_service.dart
│   ├── biometric_service.dart
│   ├── notification_service.dart
│   ├── mpesa_service.dart
│   └── iap_service.dart
└── presentation/
    ├── screens/
    │   ├── auth/           # Login, Signup
    │   ├── home/           # Home dashboard
    │   ├── journal/        # Journal screen
    │   ├── wellness/       # Mood, Goals, Budget, Food
    │   ├── rituals/        # Tasks, Calendar, Affirmations
    │   ├── profile/        # Profile, Edit, Settings, Privacy
    │   ├── subscription/   # Subscription & payment screen
    │   └── legal/          # Terms & Conditions, Privacy Policy
    └── widgets/            # Shared cards, buttons, dialogs
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.10
- Xcode 15.4+ (iOS) or Android Studio (Android)
- A Firebase project with Auth, Firestore, and Storage enabled

### 1. Clone & install dependencies
```bash
git clone https://github.com/your-org/personal_haven.git
cd personal_haven
flutter pub get
```

### 2. Firebase setup
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Run `flutterfire configure` if regenerating `firebase_options.dart`

Enable in Firebase Console:
- Authentication → Sign-in providers: Google, Apple, Microsoft
- Firestore Database (start in production mode)
- Storage

**Firestore security rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### 3. M-Pesa (optional)
Register at [developer.safaricom.co.ke](https://developer.safaricom.co.ke) and update `lib/services/mpesa_service.dart`:
```dart
static const _consumerKey    = 'YOUR_CONSUMER_KEY';
static const _consumerSecret = 'YOUR_CONSUMER_SECRET';
static const _callbackUrl    = 'https://your-backend/mpesa/callback';
```

### 4. Microsoft Sign-In (optional)
Register an app in [Azure AD](https://portal.azure.com) and update `lib/services/social_auth_service.dart`:
```dart
static const _msClientId    = 'YOUR_MICROSOFT_CLIENT_ID';
static const _msRedirectUrl = 'msauth.YOUR_BUNDLE_ID://auth';
```

### 5. In-App Purchases (optional)
Create subscription products in App Store Connect and Google Play Console with these IDs:
- `personal_haven_weekly`
- `personal_haven_monthly`

### 6. Run
```bash
# iOS simulator
flutter run -d <simulator-id>

# Android
flutter run -d <device-id>
```

> **Xcode 15.2 note:** Firebase 11.x requires Swift 5.10 (Xcode 15.4+).  
> A patch script `ios/patch_firebase.sh` is included and runs automatically via `post_install` in the Podfile to make it compile on Xcode 15.2.

---

## Docker

The project includes a `Dockerfile` for building and running the app in a containerised environment (e.g. CI pipelines or cloud build systems).

### Base image

```
ghcr.io/cirruslabs/flutter:3.38.7
```

### What it does

1. Installs system dependencies — `git`, `curl`, `unzip`, `xz-utils`, `python3`
2. Copies the full repository into `/app`
3. Disables Flutter analytics and runs `flutter pub get`

### Build & run

```bash
# Build the image
docker build -t personal_haven .

# Open a shell inside the container
docker run --rm -it personal_haven bash

# Run Flutter tests inside the container
docker run --rm personal_haven flutter test
```

> The `.git` directory is intentionally **not** excluded from the Docker build context — the build system requires full git history at runtime.

---

## Scripts

### `ios/patch_firebase.sh`

Patches Firebase CocoaPods sources so the project compiles on **Xcode 15.2 / Swift 5.9**. Firebase 11.x introduced Swift 5.10-only syntax (`nonisolated(unsafe)`, `sending`, `internal import`, `package import`) that causes build failures on older toolchains.

**Runs automatically** via the `post_install` hook in `ios/Podfile` after `pod install`. You can also run it manually:

```bash
bash ios/patch_firebase.sh
```

Files patched:
- `FirebaseSharedSwift` — `FirebaseDataEncoder.swift`
- `FirebaseCoreInternal` — `FIRAllocatedUnfairLock.swift`, `HeartbeatsPayload.swift`
- `FirebaseAuth` — multiple Swift source files
- `FirebaseFirestore` — `DocumentID.swift`
- `FirebaseStorage` — `Storage.swift`, `StorageTokenAuthorizer.swift`, `StorageUploadTask.swift`

> Only needed on Xcode 15.2. Xcode 15.4+ compiles Firebase 11.x without patching.

---

### `silver/tests/run_script.sh`

Runs the full Dart/Flutter test suite using the JSON reporter:

```bash
bash silver/tests/run_script.sh
```

Equivalent to:

```bash
flutter test --reporter json --no-pub
```

Must be run from inside the Docker container (working directory `/app`).

---

### `silver/tests/test.sh`

The Silver evaluation harness entrypoint — **do not modify**. It:

1. Applies a `test_patch` from `silver/tests/config.json` via `git apply`
2. Runs `run_script.sh` and pipes output through `silver/tests/parser.py`
3. Checks each test listed under `fail_to_pass` and `pass_to_pass` in `config.json`
4. Writes a reward score (`0` or `1`) to `/logs/verifier/reward.txt`

```bash
bash silver/tests/test.sh
```

---

## Platform Permissions

### iOS (`Info.plist`)
- `NSFaceIDUsageDescription` — biometric lock
- `UIBackgroundModes` — push notifications

### Android (`AndroidManifest.xml`)
- `USE_BIOMETRIC` — fingerprint / face unlock
- `USE_FINGERPRINT` — Android 6–8 fallback
- `POST_NOTIFICATIONS` — Android 13+ push notifications
- `RECEIVE_BOOT_COMPLETED` — reschedule notifications after reboot

---

NOTES ON SHORTCUTS
dart run build_runner build --delete-conflicting-outputs
flutter pub get
dart run flutter_launcher_icons

## License

Private — all rights reserved(2026, Meg).
