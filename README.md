# Dukkan

Dukkan is a Flutter retail shop management app for sales, inventory, loans, expenses, backups, and LAN data sharing.

## Supported Platforms

- Android: split release APKs and AAB.
- Windows: Inno Setup installer and zip fallback.
- Linux: AppImage primary artifact, with `.deb` and `tar.gz` fallbacks.
- iOS: not part of the current production target until an Apple Developer account is available.

## Production Backend

- Backend: Appwrite Cloud.
- Build-time configuration is passed with Dart defines.
- Secrets, keystores, and local signing files must not be committed.
- Offline login is supported from cached secure auth state after a successful online login.

Required build defines:

```bash
--dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
--dart-define=APPWRITE_PROJECT_ID=<appwrite-project-id>
--dart-define=APPWRITE_BUCKET_ID=<appwrite-bucket-id>
```

## Local Setup

1. Install Flutter `3.41.9` or the version pinned in `.github/workflows/main.yml`.
2. Run `flutter pub get`.
3. Run `flutter analyze`.
4. Run `flutter test -j 1 --timeout 120s` when tests need Isar native initialization.

## Local Release Builds

Android APK:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<appwrite-project-id> \
  --dart-define=APPWRITE_BUCKET_ID=<appwrite-bucket-id>
```

Android AAB:

```bash
flutter build appbundle --release \
  --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<appwrite-project-id> \
  --dart-define=APPWRITE_BUCKET_ID=<appwrite-bucket-id>
```

Linux:

```bash
flutter build linux --release \
  --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<appwrite-project-id> \
  --dart-define=APPWRITE_BUCKET_ID=<appwrite-bucket-id>
```

Windows:

```powershell
flutter build windows --release `
  --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 `
  --dart-define=APPWRITE_PROJECT_ID=<appwrite-project-id> `
  --dart-define=APPWRITE_BUCKET_ID=<appwrite-bucket-id>
```

## GitHub Releases

- Pushes to `hot` publish the moving beta pre-release tag named `beta`.
- Stable releases are created when a PR is merged into `master` and the PR title contains a version such as `v2.4.7`.
- Release artifacts are uploaded by `.github/workflows/main.yml` after analyze and tests pass.

Current beta release:

```text
https://github.com/ayman2ppp2/dukkan/releases/tag/beta
```

## Backup And LAN Sync

- Database backups are created locally before upload or sharing.
- Restore verifies the replacement before swapping the active database.
- LAN sync uses an explicit pairing address and short pairing code.
- LAN sync only serves allowed backup files and verifies the backup hash before restore.
- Pairing codes are session-scoped and should only be shared with trusted devices on the same network.

## Product Language

- The product UI is Arabic-first for now.
- Developer documentation and release automation remain English-first.
- New user-facing strings should be Arabic unless a specific integration requires English.

## Related Docs

- `CHANGELOG.md`: release notes.
- `PRIVACY.md`: privacy and data handling notes.
- `RELEASE_CHECKLIST.md`: manual release checklist.
- `plans/production-readiness-todo.md`: production hardening roadmap.
