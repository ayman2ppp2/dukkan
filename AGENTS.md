# Agent Instructions for Dukkan

A retail shop management app built with Flutter.

---

## Project Conventions

- **Stack**: Flutter, Isar DB (isar_community), Provider (ChangeNotifier), isolate_pool_2
- **Branch**: work on `hot`, PRs to `master`
- **Version format**: `major.minor.patch+build` in `pubspec.yaml`

### Directory structure

| Path | Purpose |
|---|---|
| `lib/core/db.dart` | DB class with all pooled jobs (`Cget*` methods) |
| `lib/providers/list.dart` | Central `Lists` provider, delegates DB calls |
| `lib/util/models/` | Data models (`Product`, `Log`, `Loaner`, `Emap`, `prodStats`) |
| `lib/util/charts.dart` | Chart widgets |
| `lib/pages/` | UI screens |
| `test/unit/` | Unit tests |
| `test/widget/` | Widget tests |

### Patterns

- **DB methods**: named `Cget*`, scheduled via `pool.schedule()` in `list.dart`
- **Models**: `Emap` for key-value pairs (e.g. priceHistory); `Product.named2()` constructor used in tests
- **Naming**: camelCase Dart, Arabic-first UI labels
- **Checks**: always run `flutter analyze --no-fatal-infos --no-fatal-warnings` before finishing any work

---

## Commit Workflow

When told `"commit"` or `"commit changes"`:

1. Run `flutter analyze --no-fatal-infos --no-fatal-warnings` — fix any issues
2. Run `flutter test` — fix any failures
3. `git add -A`
4. `git commit -m "{type}: {short description}"`

Types: `fix:`, `feat:`, `chore:`, `refactor:`, `test:`, `docs:`

---

## Push Workflow

When told `"push"`:

1. Run `flutter analyze --no-fatal-infos --no-fatal-warnings`
2. Run `flutter test`
3. Bump **patch** in `pubspec.yaml` (e.g. `2.4.15+1` → `2.4.16+1`)
4. Insert new `## {version}` section at top of `CHANGELOG.md` with bullet points of changes
5. `git add -A`
6. `git commit -m "v{version}: {short summary}"`
7. `git push origin hot`

> CI automatically builds all platforms and creates a beta pre-release on push to `hot`. No need to tag.

---

## PR / Release Workflow

When told `"create PR"` or `"release"`:

1. Ensure version in `pubspec.yaml` differs from last stable release
2. If unpushed commits exist, push first: `git push origin hot`
3. Create a PR from `hot` → `master` with title containing the version:
   - `v2.4.16: Short description of changes`

> CI parses the version from the PR title, creates a git tag, and publishes a stable GitHub release when the PR is merged.
