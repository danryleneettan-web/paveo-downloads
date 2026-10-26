# Week 2 submission index

**Project:** Paveo road hazard reporting system  
**Submission date:** October 26, 2026  
**Repository:** [https://github.com/danryleneettan-web/paveo-downloads](https://github.com/danryleneettan-web/paveo-downloads) — share this link with the instructor.

## Deliverables

1. [Admin side — web system](01-ADMIN-WEB/README.md)
2. [Database / export](02-DATABASE/README.md)
3. [Hosting provider and live site](03-HOSTING/README.md)
4. [Hosting credentials](04-PRIVATE-ACCESS/README.md) — share privately; do not commit passwords.
5. [Sample user accounts](05-TEST-ACCOUNTS/README.md) — use safe test accounts; do not publish passwords.
6. [Screenshots](06-SCREENSHOTS/README.md)
7. [Resident/citizen app APK](07-RESIDENT-APK/README.md)
8. [Resident/citizen source](../README.md#repository-contents)
9. [Rescuer/respondent app](08-RESCUER-APP/README.md)

## What is included and what still needs arranging

- One Flutter source project serves the web experience and Android citizen app. The admin panel is integrated into that project.
- A release APK is included in `07-RESIDENT-APK/`.
- Use the APK in `07-RESIDENT-APK/` for this submission. The repository already had an older APK under GitHub Releases; that older release was preserved.
- The mobile design reference PDF is included next to the APK.
- Firebase is the configured hosting provider and Cloud Firestore is the database. No database export file is included; see its notes.
- Hosting passwords and administrator sign-in details are intentionally not published. Share them directly with the instructor using an appropriate private channel, or create a temporary evaluation account.
- This project does not currently contain a distinct rescuer/respondent app or APK. Confirm whether the instructor expects that role in this week's scope; do not present the resident APK as a separate rescuer build.
- Add genuine screenshots of the current web interface and app to `06-SCREENSHOTS/` before treating that item as complete.

## Sharing on GitHub

Share the repository's main page URL. The README links to every labeled section. If the APK is too large for GitHub's browser upload, attach `Paveo-Citizen-1.0.0.apk` to a GitHub Release and add the release link to [the APK page](07-RESIDENT-APK/README.md).

Keep the repository private if it contains real student data or instructor-only access information. Never put account passwords, private keys, Firebase service-account files, or personal data in the repository.
