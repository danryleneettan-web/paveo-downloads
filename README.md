# Paveo — System Development Submission

**Week 2 progress submission · October 26, 2026**

**GitHub repository:** [danryleneettan-web/paveo-downloads](https://github.com/danryleneettan-web/paveo-downloads)

Paveo lets residents report and follow road hazards, while authorized administrators review reports and update their status. This GitHub repository contains the **single Flutter project** used for the web experience and Android application. The admin panel is part of that same project; the resident and admin experiences are not separate repositories.

## Start here

Open the [submission checklist](SUBMISSION/README.md) for the instructor-facing index, deliverables, setup notes, and items that must be shared privately.

| Component | Where to look |
| --- | --- |
| Admin web system and source | [Admin web deliverable](SUBMISSION/01-ADMIN-WEB/README.md) · source: [`lib/`](lib/) and [`web/`](web/) |
| Database / export | [Database details](SUBMISSION/02-DATABASE/README.md) |
| Hosting | [Hosting details](SUBMISSION/03-HOSTING/README.md) · [Live website](https://paveo-47e82.web.app) |
| Hosting credentials | [Private sharing instructions](SUBMISSION/04-PRIVATE-ACCESS/README.md) |
| Sample test accounts | [Account instructions](SUBMISSION/05-TEST-ACCOUNTS/README.md) |
| Screenshots | [`SUBMISSION/06-SCREENSHOTS/`](SUBMISSION/06-SCREENSHOTS/README.md) |
| Resident/citizen Android APK | [`SUBMISSION/07-RESIDENT-APK/`](SUBMISSION/07-RESIDENT-APK/README.md) |
| Resident/citizen source | This repository: [`lib/`](lib/), [`android/`](android/), and [`assets/`](assets/) |
| Rescuer/respondent app | [Status and clarification](SUBMISSION/08-RESCUER-APP/README.md) |

For this Week 2 submission, use the APK linked in `SUBMISSION/07-RESIDENT-APK/`. The repository's older GitHub Release is a previous build.

## Build locally

Install Flutter and Android SDK, then from the repository root run:

```sh
flutter pub get
flutter run
```

To build the Android APK:

```sh
flutter build apk --release
```

For web:

```sh
flutter build web
```

The project uses Firebase Authentication and Cloud Firestore. See the [database notes](SUBMISSION/02-DATABASE/README.md) before configuring a test project. Do not put passwords, service-account JSON, or other private credentials in this public repository.

## Repository contents

- `lib/` — Flutter UI, citizen reporting/map experience, login, and admin panel.
- `android/` — Android project source.
- `web/` — Flutter web entry point and assets.
- `assets/` — Brand and interface assets.
- `firestore.rules`, `firebase.json`, `.firebaserc` — Firestore rules and Firebase Hosting configuration.
- `SUBMISSION/` — Labeled instructor-facing deliverables and notes.

See the submission checklist for anything still needing private delivery or a separate build.
