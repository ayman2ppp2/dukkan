# Manual Release Checklist

Use this checklist before promoting a beta build to a stable release.

## Before Release

- Confirm `pubspec.yaml` version is the intended release version.
- Confirm `.github/workflows/main.yml` uses the intended Flutter version.
- Confirm Appwrite endpoint, project id, and bucket id are correct for production.
- Confirm no keystores, passwords, `android/key.properties`, or generated native test files are tracked.
- Run `flutter pub get`.
- Run `flutter analyze`.
- Run `flutter test -j 1 --timeout 120s`.

## Build Verification

- Push to `hot` and wait for the beta workflow to pass.
- Confirm Android APKs and AAB are uploaded to the beta release.
- Confirm Windows installer `Dukkan-Setup-<version>.exe` is uploaded.
- Confirm Linux `Dukkan-<version>-x86_64.AppImage` is uploaded.
- Confirm Linux `.deb` and `tar.gz` fallback artifacts are uploaded.
- Download at least one artifact per platform family when practical.

## Product Smoke Checks

- Launch the app and confirm the app name is Dukkan.
- Confirm Arabic-first core UI copy appears on login, register, checkout, inventory, and sync screens.
- Sign in online with a test account.
- Confirm offline login works after a successful online login.
- Add or search a product.
- Complete a sale and confirm stock updates.
- Test backup creation.
- Test LAN sync only with a trusted device and verify pairing code flow.

## Stable Release

- Open a PR from `hot` to `master`.
- Include the release version in the PR title, for example `Release v2.4.7`.
- Merge only after CI is green.
- Confirm the stable GitHub release contains Android, Windows, and Linux artifacts.

## After Release

- Update `CHANGELOG.md` if release notes changed.
- Check the release page download names and sizes.
- Keep the beta release available for the next `hot` build.
