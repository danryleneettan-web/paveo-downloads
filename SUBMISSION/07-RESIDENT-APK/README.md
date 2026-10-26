# 07 — Resident/citizen mobile application

## Design reference

The app's existing mobile source screens follow the supplied Paveo mobile design: onboarding and sign-in, a citizen home with recent reports and bottom navigation, a multi-step report flow, a map, and a profile screen. The APK below was built from the current mobile source after the latest mobile source edits. The design PDF is a reference, not a screenshot of the running app.

Included copy: [`Paveo-Mobile-design-reference.pdf`](Paveo-Mobile-design-reference.pdf).

## Installable APK

[`Paveo-Citizen-1.0.0.apk`](Paveo-Citizen-1.0.0.apk) is the prebuilt Android release APK found in the project build outputs and copied here for submission.

## Source code

The complete Flutter source is in the repository root: [`lib/`](../../lib/), [`android/`](../../android/), and [`assets/`](../../assets/). The same codebase includes the admin panel and web build.

To rebuild: `flutter build apk --release`.
