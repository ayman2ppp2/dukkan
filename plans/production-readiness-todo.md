# Production Readiness Todo

This file tracks the work needed to make Dukkan production ready in small, safe chunks.

## Decisions

- Target platforms now: Android, Windows, Linux.
- iOS: skipped until an Apple Developer account is available.
- Backend: Appwrite remains the production backend.
- Offline login: full login, not read-only mode.
- GitHub Releases: required.
- Windows publisher/company: Golden.
- Windows distribution: installer preferred.
- Linux distribution: AppImage preferred, with tar.gz fallback.

## Phase 1: Repository And Build Hygiene

- [x] Remove tracked generated artifacts from git, especially `android/app/.cxx`.
- [x] Remove scratch/demo files that are not part of the app, such as `test3.dart`.
- [x] Remove unused root Gradle init files that are separate from the Flutter Android project.
- [x] Update `.gitignore` so generated Flutter, Gradle, CMake, local SDK, signing, and release output files stay untracked.
- [x] Decide whether Firebase client config files are intentionally tracked. Keep them for now and audit Firebase separately.
- [x] Fix `pubspec.yaml` so `flutter_lints` is under `dev_dependencies`, not `flutter_launcher_icons` config.
- [x] Run `flutter pub get` after dependency config changes.
- [ ] Run mutating Dart formatting after code cleanup. Non-mutating format check currently reports existing formatting drift in 18 files.

## Phase 2: Analysis And CI Gates

- [x] Enable Flutter lints in `analysis_options.yaml` with `include: package:flutter_lints/flutter.yaml`.
- [x] Run `flutter analyze` locally and record current failures. Initial rollout found 663 legacy issues before staged rule suppression.
- [x] Fix analyzer errors first, then high-risk warnings. Current `flutter analyze` passes with a staged lint rollout.
- [x] Keep generated Isar files excluded from manual style cleanup unless generation requires updates.
- [x] Add GitHub Actions quality job with `flutter pub get`, `flutter analyze`, and `flutter test`.
- [x] Make release builds depend on the quality job.
- [x] Pin GitHub Actions Flutter version to a real stable Flutter version used by the project: `3.41.9`.
- [ ] Gradually re-enable currently suppressed legacy lint rules in future cleanup PRs.

## Phase 3: Android Production Release

- [ ] Replace release debug signing in `android/app/build.gradle` with real release signing.
- [ ] Add GitHub Secrets for Android signing: keystore base64, key alias, key password, store password.
- [ ] Add CI step to decode the keystore only inside the workflow.
- [ ] Build split APKs for GitHub Releases.
- [ ] Build AAB for future Play Store distribution.
- [ ] Upload APKs and AAB as release artifacts.
- [ ] Verify Android `applicationId` remains `com.golden.dukkan`.
- [ ] Review Android permissions and remove unused dangerous permissions.
- [ ] Avoid `MANAGE_EXTERNAL_STORAGE` unless there is no scoped-storage alternative.

## Phase 4: Windows Production Release

- [ ] Build Windows with `flutter build windows --release` in GitHub Actions.
- [ ] Add Inno Setup script under a packaging directory.
- [ ] Set installer publisher/company to `Golden`.
- [ ] Set installer app name to `Dukkan`.
- [ ] Generate installer artifact named `Dukkan-Setup-<version>.exe`.
- [ ] Upload installer to GitHub Releases.
- [ ] Keep Windows zip artifact as a fallback.
- [ ] Add Windows code signing later if a signing certificate becomes available.

## Phase 5: Linux Production Release

- [ ] Build Linux with `flutter build linux --release` in GitHub Actions.
- [ ] Install required Linux build dependencies in CI.
- [ ] Package release bundle as tar.gz fallback.
- [ ] Package AppImage as the primary Linux artifact.
- [ ] Set Linux application id away from `com.example.dukkan`.
- [ ] Upload AppImage and tar.gz to GitHub Releases.
- [ ] Consider `.deb` later if most users are on Ubuntu/Debian.

## Phase 6: Appwrite And Auth Hardening

- [ ] Move Appwrite endpoint, project id, bucket id, and other environment config to build-time configuration.
- [ ] Remove `setSelfSigned()` for Appwrite Cloud production clients.
- [ ] Remove hardcoded mail credentials from client code.
- [ ] Replace client-side Gmail verification with Appwrite or server-side verification.
- [ ] Stop logging user email, user id, backup paths, and sensitive auth details in production logs.
- [ ] Define the offline full-login policy, including expiration and revalidation behavior.
- [ ] Store offline login state in secure storage instead of plain `SharedPreferences`.
- [ ] Keep enough local auth state for offline login without storing plaintext passwords.
- [ ] Add UI messaging when the app is running offline but fully logged in.

## Phase 7: Database And Data Integrity

- [ ] Fix `DB.getInstance()` so it awaits Isar initialization before returning.
- [ ] Expose provider readiness/error states instead of using late fields immediately after async init.
- [ ] Make checkout return a real success/failure result through provider and UI layers.
- [ ] Do not show checkout success dialog if database write fails.
- [ ] Add validation for product name, owner, barcode, prices, count, discount, offer count, and offer price.
- [ ] Prevent unintended negative stock or make negative stock an explicit setting.
- [ ] Validate loaner and expense selections before checkout.
- [ ] Ensure sale, stock update, owner due money, loan update, expense update, and log write stay transactionally consistent.
- [ ] Review offer pricing calculations and add tests for bundle and remainder cases.
- [ ] Make backup restore atomic: verify, copy to temp, close DB, swap, reopen, rollback on failure.
- [ ] Keep the previous database until restore succeeds.

## Phase 8: LAN Sync Hardening

- [ ] Keep LAN sync only if it has an explicit trust boundary.
- [ ] Add a short pairing code or token before serving/downloading backups.
- [ ] Whitelist allowed file names instead of serving arbitrary document-directory path segments.
- [ ] Add request timeouts and cancel controls.
- [ ] Verify backup hash before restore.
- [ ] Show clear sync progress and failure states.
- [ ] Avoid app restart as the normal restore strategy unless no safer approach works.
- [ ] Add tests for version negotiation, hash mismatch, transfer failure, and restore rollback.

## Phase 9: Tests

- [ ] Replace placeholder tests with tests that exercise real app logic.
- [ ] Add checkout tests for normal sale, discount, offer, loan, expense, and insufficient stock.
- [ ] Add product insert/update validation tests.
- [ ] Add low-stock calculation tests.
- [ ] Add loan payment and account statement tests.
- [ ] Add backup create/restore tests with temporary files.
- [ ] Add offline login policy tests.
- [ ] Add widget tests for login, product insert, checkout, inventory search, and settings.
- [ ] Add one smoke integration test for app startup and core sale flow.

## Phase 10: Observability And Production Logging

- [ ] Replace raw `print()` calls with a logging wrapper or structured logger.
- [ ] Disable verbose debug logs in release builds.
- [ ] Add crash reporting for Android, Windows, and Linux, likely Sentry for cross-platform coverage.
- [ ] Capture errors around auth, checkout, backup, restore, and sync.
- [ ] Add user-safe error messages without exposing stack traces or internal paths.

## Phase 11: Product Polish And Documentation

- [ ] Update `README.md` with setup, supported platforms, release process, and backup/sync notes.
- [ ] Add `CHANGELOG.md` for release notes.
- [ ] Add privacy policy text covering local database, Appwrite auth, backup upload, and LAN sync.
- [ ] Finalize app icons and launcher assets for Android, Windows, and Linux.
- [ ] Review Arabic/English text consistency.
- [ ] Review accessibility basics: text scaling, contrast, tap target sizes, keyboard navigation for desktop.
- [ ] Add a simple manual release checklist.

## Recommended Execution Order

1. Phase 1: repository cleanup.
2. Phase 2: analysis and CI gates.
3. Phase 3: Android release builds.
4. Phase 4: Windows installer.
5. Phase 5: Linux AppImage.
6. Phase 7: database and checkout safety.
7. Phase 6: auth hardening.
8. Phase 8: LAN sync hardening.
9. Phase 9: meaningful tests.
10. Phase 10: observability.
11. Phase 11: documentation and polish.

## Done Criteria For Production v1

- [ ] CI blocks releases when analyze or tests fail.
- [ ] GitHub Releases publish Android APK/AAB, Windows installer, and Linux AppImage/tar.gz.
- [ ] Android release is not signed with the debug key.
- [ ] Windows installer identifies publisher as Golden.
- [ ] Appwrite production config has no hardcoded secrets or self-signed cloud setting.
- [ ] Offline full login is implemented intentionally and documented.
- [ ] Checkout failures cannot be reported as success.
- [ ] Backup restore cannot destroy the current database without a verified replacement.
- [ ] LAN sync does not serve arbitrary local files.
- [ ] Core sales, inventory, loan, expense, backup, and auth behavior has real tests.
