# 01 — Admin side: web-based system

## Source code

The admin panel is part of the shared Flutter application, not a standalone web project. Browse [`lib/admin_page.dart`](../../lib/admin_page.dart), [`lib/login_page.dart`](../../lib/login_page.dart), [`lib/member_page.dart`](../../lib/member_page.dart), and [`web/`](../../web/). Build the web app from the repository root with `flutter build web`.

## Access

Live site: [https://paveo-47e82.web.app](https://paveo-47e82.web.app)

Administrator access requires an account whose Firestore `users/{uid}` profile has `role: admin`. Account details must be delivered privately. See [private access](../04-PRIVATE-ACCESS/README.md).

## Current functions

- Citizen sign-in/sign-up and road hazard reporting.
- Interactive report map and live report data.
- Admin report review, status and severity updates, notes, search, and deletion controls.
- Web hosting configuration in [`firebase.json`](../../firebase.json).

The codebase documents a single web/mobile Flutter project. It does not include a distinct responder app.
