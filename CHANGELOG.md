# Changelog

All notable production-readiness changes are tracked here.

## 2.4.7

- Added production GitHub release builds for Android, Windows, and Linux.
- Added Android release signing through GitHub secrets.
- Added Windows Inno Setup installer with `Golden` as publisher.
- Added Linux AppImage, `.deb`, and `tar.gz` release outputs.
- Hardened Appwrite configuration by moving production values to build-time defines.
- Reworked auth to avoid plaintext offline credentials and support intentional offline login.
- Hardened database initialization, checkout failures, validation, and backup restore safety.
- Hardened LAN sync with pairing codes, file allowlisting, transfer timeouts, and hash verification.
- Added real tests for checkout, inventory, loans, expenses, backup/restore, auth policy, widgets, and smoke integration.
- Started Phase 11 documentation, Arabic-first copy, accessibility, and icon polish.

## Earlier Releases

- Initial Flutter implementation for shop sales, inventory, expenses, loans, reports, backups, and sync.
