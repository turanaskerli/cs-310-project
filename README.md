<div align="center">

# 🏠 Roommate Finder

**Find a roommate you'll actually get along with, before dorm applications open.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

CS 310 Mobile Application Development · Sabancı University · **Group 42**

</div>

---

## 📖 About the project

At Sabancı University, as at many universities in Turkey and Europe, students who apply for the dorms without a roommate are paired **at random**. New students usually don't know anyone on campus yet, so they end up living with a stranger. Differences in sleep schedule, cleanliness, noise, guests and personal boundaries are one of the most common sources of stress in the first year.

The dorm application already lets two students request each other as roommates using their **student IDs**. **Roommate Finder** helps students make good use of that option: it matches them by compatibility, gives them time to get to know each other, and lets them apply for the dorm together.

**Intended users:** Sabancı students planning to live in the dorms, especially first-year and exchange students who don't yet know anyone on campus.

## ⚙️ How it works

```mermaid
flowchart LR
    A[Sign up with<br/>@sabanciuniv.edu] --> B[Create<br/>profile]
    B --> C[Answer the<br/>questionnaire]
    C --> D[Get ranked<br/>matches]
    D --> E[Send request<br/>& chat]
    E --> F[Both confirm<br/>roommate]
    F --> G[Student IDs shared,<br/>apply together]
```

1. **Sign up** with a verified university email.
2. **Answer a questionnaire** about sleep, cleanliness, noise, guests, studying and lifestyle, plus dealbreakers like smoking.
3. **Get matches**, each with a compatibility score and the reasons behind it, e.g. *"You both sleep before midnight and prefer a quiet room."*
4. **Send a request.** If the other student accepts, a chat opens so you can get to know each other.
5. **Confirm.** When both students confirm, each sees the other's student ID for the dorm application.

> 💡 **Honest answers by design.** The questionnaire asks about concrete behavior (*"How long do dishes usually sit before you wash them?"*) instead of self-ratings. The app matches similar people rather than judging them, so an untrue answer only leads to a worse match for the user.

## ✨ Features

### Core features

- [ ] 🔐 **Verified sign-up:** only `@sabanciuniv.edu` emails, with email verification
- [ ] 👤 **Student profile:** name, photo, program, year, gender and a short bio
- [ ] 📝 **Compatibility questionnaire:** grouped sections plus dealbreakers
- [ ] 🎯 **Matching:** ranked list with a % score and the main reasons for each match
- [ ] 🤝 **Roommate requests:** send, accept or decline; contact details stay hidden until both accept
- [ ] 💬 **In-app chat:** real-time messaging between matched students
- [ ] ✅ **Roommate confirmation:** student IDs revealed only after both confirm

### Optional features (if time allows)

- [ ] 🔔 Push notifications for new requests and messages
- [ ] 🚫 Block and report users
- [ ] 🙈 Hide profile once a roommate is found
- [ ] ✏️ Edit questionnaire answers later
- [ ] 🧩 Detect contradictory answers
- [ ] 🔍 Filters on the match list
- [ ] ⏰ Reminder before the dorm application deadline
- [ ] 🌙 Dark mode

## 🛠️ Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart), Android |
| State management | Provider |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| File storage | Firebase Storage (profile photos) |
| Server logic | Cloud Functions (matching, notifications) |
| Notifications | Firebase Cloud Messaging |

No external API is needed: the matching algorithm is our own code.

## 🏗️ Architecture

```mermaid
flowchart TB
    UI[Screens & Widgets] --> P[Providers<br/>state management]
    P --> S[Services]
    S --> AUTH[Firebase Auth]
    S --> DB[(Cloud Firestore)]
    S --> ST[Firebase Storage]
    DB -- triggers --> CF[Cloud Functions<br/>matching engine, notifications]
    CF --> DB
    CF --> FCM[Cloud Messaging]
```

Screens never talk to Firebase directly. They read state from **providers**, providers call **services**, and only services touch Firebase. Matching and other sensitive logic runs in **Cloud Functions** on the server.

### Planned project structure

```
lib/
├── models/      # User, Question, Answer, Match, Connection, Message
├── services/    # All Firebase access (auth, users, questionnaire, matching, chat)
├── providers/   # App state for each feature
├── screens/     # auth, onboarding, matches, requests, chat, profile, settings
├── widgets/     # Reusable UI components
└── utils/       # Theme, constants, validators
```

## 🔒 Privacy

- Only verified university students can use the app.
- Student IDs and contact details are shown **only** after both students confirm each other.
- No questions about sensitive topics such as religion or health (in line with KVKK).
- Users can edit their answers, hide their profile, or delete their account at any time.

## 🚀 Getting started

### Requirements

| Tool | Version |
|---|---|
| Flutter | **3.47.x** (stable channel; developed and tested with 3.47.9) |
| Dart | 3.8 or newer (bundled with Flutter) |
| Android Studio | with the **Flutter** and **Dart** plugins, plus an Android emulator or an Android phone with USB debugging |

Check your setup with `flutter --version` and `flutter doctor`. In Step 2 the app runs entirely on mock data, so no Firebase access is needed yet.

### Run the app

```bash
# 1. Clone the repository
git clone https://github.com/turanaskerli/cs-310-project.git
cd cs-310-project

# 2. Install dependencies
flutter pub get

# 3. Start an emulator (or plug in a phone), then run
flutter devices
flutter run
```

In Android Studio: **File → Open** the `cs-310-project` folder (the one that contains `pubspec.yaml`), run **Pub get**, choose a device in the toolbar and press ▶ on `lib/main.dart`.

### Run the tests

```bash
flutter analyze
flutter test
```

### Try the screens

- **Sign up flow:** Welcome → Sign up (use an `@sabanciuniv.edu` email, a password of 8+ characters and tick the terms) → Verify email → Consent → Basic profile → Honesty intro → Questionnaire → Dealbreakers → Review and submit → main tabs.
- **Log in flow:** Welcome → Log in → main tabs (Matches, Requests, Chats, Profile). Log in is UI only in Step 2.

### Troubleshooting

- **"Dart SDK is not configured" / "Dart support is not enabled":** set the Flutter SDK path in **Settings → Languages & Frameworks → Flutter**, and make sure you opened the folder that contains `pubspec.yaml`, not a parent folder.
- **Android license errors:** run `flutter doctor --android-licenses` and accept them.

## 👥 Team

| Member | Student ID | Responsibility |
|---|---|---|
| **Turan Asgarli** | 36689 | Backend: questionnaire and matching algorithm |
| **Murad Mammadov** | 36688 | Frontend: screens, navigation and UI |
| **Bassam Khoja** | 36035 | Backend: sign-up, profiles and security |
| **Mustafa Arda Terzi** | 35266 | Backend: roommate requests, chat and notifications |

## 📌 Project status

🚧 **Step 2: User interface.** All screens are built with Flutter and run on mock services (fake data in Dart). In Step 3 each mock is swapped for its Firebase version in `lib/services/app_services.dart`.

---

<div align="center">
Made by Group 42 for CS 310 at Sabancı University
</div>
