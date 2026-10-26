# 02 — Database file or export

## Database provider

The configured database is **Cloud Firestore** in Firebase project `paveo-47e82`. This is a hosted database; there is no local database file in the project and no database export is included in this submission.

## Data model

- `users/{uid}` — profile name and role (`citizen` or `admin`).
- `reports/{id}` — owner, coordinates, photo data, description, severity, status, duplicate reference, confirmations, admin note, and creation time.

Firestore access rules are in [`firestore.rules`](../../firestore.rules). Firebase configuration is in [`firebase.json`](../../firebase.json) and [`.firebaserc`](../../.firebaserc).

## Export status

**Not included:** a Firestore data export. Exporting the live project requires authorized Firebase project access. Do not include real user or incident data in a public repository. If the instructor requires an export, create a sanitized test-only export and share it through an approved private location.
