# Paveo handoff

Project: IT 305 Advanced Web Development final output (BulSU). Group of 4-5, one live web and mobile system. Work period Oct 12-30, 2026, submission Nov 2, 2026.
Concept: citizens photograph potholes via app or website. Locations appear live on OpenStreetMap (Leaflet) for citizens and government workers. Only one report is accepted per pothole, even from different people or angles.
Required stack: Flutter, with Firebase as the database. One Flutter codebase builds both the Android app and the website.
Live Website URL: https://paveo-47e82.web.app
Brand (Paveo-Brandsheet.pdf): Poppins headings, Inter body. Primary green #426B58, sage #92AD9A, light green #E5EDE4, ivory #F7F8F3, accent peach #E7C3BA, charcoal #263E33, gray #6B6B6B, light gray #D9D9D9. Status colors: pending #FAD6BB, in progress #FEC9C7, resolved #9EC0B8, flagged #E7C3BA. Tagline: Report. Respond. Restore.
Developer preferences: minimal code, no comments, no unnecessary error handling or styling, never use !important in CSS.

## Administrator access
Administrator sign-in details are not stored in the public handoff. Use an authorized, temporary evaluation account and share its credentials privately. If an earlier default password is still active, change it before publishing this repository.

## Member (Citizen) vs Admin Role Separation
- Citizen / Member Side:
  - Can ONLY view the interactive live map.
  - Can upload/report a pothole with camera, GPS, description, and severity.
  - Can confirm nearby existing reports if prompted.
  - Read-only on map markers: cannot edit status, cannot delete, cannot see flagged duplicate reports.
- Government Admin Side:
  - Access to full Government Admin Panel via the AppBar dashboard button.
  - Verification & Moderation Suite:
    - Status verification dropdown (Pending, In progress, Resolved, Flagged).
    - AI duplicate resolution: inspect flagged reports, view reference ID, and approve as distinct pothole or keep flagged.
    - Severity adjustments (Low, Medium, High).
    - Maintenance crew work notes (stored under `adminNote`).
    - Delete spam/inappropriate reports with confirmation dialog.
    - Search reports by description.
    - Status count summary chips (Total, Flagged, Pending, In Repair, Resolved).

## Stack and data model
Flutter 3.44+ (Dart 3.12+), Firebase Auth, Cloud Firestore, flutter_map (Leaflet / OpenStreetMap), latlong2, geolocator, image_picker, google_fonts.
- Firebase Project ID: paveo-47e82
- users/{uid}: name, role ('citizen' or 'admin').
- reports/{id}: userId, lat, lng, photo (base64 string, resized to 800 px at quality 40), description, severity ('low', 'medium', 'high'), status ('pending', 'in_progress', 'resolved', 'flagged'), duplicateOf, confirmedBy (list of uids), adminNote (string), createdAt (server timestamp).

## Project structure
- lib/main.dart: App entry point, brand theme configuration.
- lib/brand.dart: Complete brand color palette and status colors.
- lib/login_page.dart: Authentication screen with role-based access.
- lib/map_page.dart: Live interactive OpenStreetMap (Leaflet), real-time Firestore stream, 2-layer duplicate detection (location + visual photo matching), custom brand status markers.
- lib/admin_page.dart: Full Government Admin verification portal with inspection dialog, status updates, maintenance notes, search, and delete tools.
- lib/similarity.dart: Zero-dependency client-side visual similarity engine (dart:ui RGBA block difference).
- lib/firebase_options.dart: Live Firebase credentials for paveo-47e82.
- android/app/src/main/AndroidManifest.xml: Configured with ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, and CAMERA.
- web/index.html: Brand title and Leaflet OSM setup.
- firebase.json & .firebaserc: Configured for Firebase Hosting deploy (rewrites to /index.html).
- firestore.rules: Production security rules enforcing citizen vs admin role permissions.

## Deployed & Ready
- Website: Live at https://paveo-47e82.web.app
- Android APK: Ready at build/app/outputs/flutter-apk/app-release.apk (52 MB)
- Verified with dart analyze: 0 errors, 0 warnings, 0 lints.
