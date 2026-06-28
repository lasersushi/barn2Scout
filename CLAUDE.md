# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run app on a simulator (list devices first)
flutter devices
flutter run -d <device-id>

# Run all tests
flutter test

# Run a single test file
flutter test test/scouting_form_bloc_test.dart

# Analyze (no issues should remain)
flutter analyze

# Regenerate Isar model code after editing any @collection class
dart run build_runner build --delete-conflicting-outputs

# Build for iOS simulator
flutter build ios --simulator

# Run a prototype entry point directly
flutter run -t lib/prototype/pit_prototype.dart
```

Hot reload: press `r` in the terminal running `flutter run`. Hot restart: `R`.

## Architecture

Feature-first layout under `lib/features/`. Data layer in `lib/data/`.

```
lib/
  main.dart              # Boots Isar + Supabase, injects all repos, reads settings before runApp
  app.dart               # MaterialApp + AuthCubit; shows LoginPage or HomeShell via _AuthGate
  core/
    config/app_config.dart  # Team identity + API keys (gitignored — update each event)
    theme/               # AppTheme — seed color 0xFF0060A7 (Barn2 Robotics blue)
    utils/               # stats_utils (normalCdf), qr_record_codec, app_version (version comparison)
  data/
    models/              # Isar @collection classes + plain value types
    services/            # IsarService, TbaService, NexusService
    repositories/        # All repo classes; ScheduleRepository is the most complex
  features/
    auth/                # AuthCubit + LoginPage (@priorypanther.com email/password)
    shell/               # HomeShell (IndexedStack tabs), NavigationCubit, inactivity observer
    scouting/            # Match form (Bloc FSM) + Pit form (Cubit) + FieldConfig system
    records/             # Match/Pit TabBar, QR share/scan
    schedule/            # My Schedule, All Schedules, Past Matches tabs
    sync/                # SyncCubit — periodic pull + auto-push on new record
    teams/               # Rankings + Pit Map + Picklist sub-tabs; TeamDossierSheet (TBA-only)
    settings/            # Preferences + account section backed by JSON file (not Isar)
    update/              # UpdateCubit + UpdateBanner — GitHub APK OTA (Android only)
  prototype/             # Throwaway explorations; never imported from real code
```

**Data flow rule:** UI and Blocs talk only to repositories, never directly to Isar/TBA/Supabase.

**Rankings / analytics rule:** All objective metrics (OPR, DPR, CCWM, scores, W-L-T) come from TBA only. Human scouting data is qualitative only and must never feed rankings, predictions, or any objective metric.

## AppConfig — update each event

`lib/core/config/app_config.dart` is **gitignored** and holds API keys, Supabase credentials, and `currentEventKey`. Update `currentEventKey` at the start of each competition (e.g. `'2026cacac'`). The schedule auto-detects the active event from TBA; this is the hard fallback.

## Isar (offline database)

Uses `isar_community` v3.3.2 — **not** the official `isar` package. The official package is frozen and its bundled analyzer can't parse Dart 3.12 syntax. Import path: `package:isar_community/isar.dart`. API is identical to Isar v3.

After editing any `@collection` class, regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```

`*.g.dart` files are committed. The analyzer excludes them (see `analysis_options.yaml`).

Isar cannot store `Map<String, dynamic>` directly. The pattern used everywhere: store as a JSON string field (`xyzJson`), expose via `@ignore` typed getter/setter.

## Auth

`AuthCubit` wraps Supabase auth. Sign-in is always required on cold start (`_checkSession()` emits `AuthUnauthenticated` unconditionally). Only `@priorypanther.com` emails are accepted — enforced in `AuthCubit._isAllowedEmail()` before any Supabase call.

`HomeShell` is a `StatefulWidget` with `WidgetsBindingObserver`. When the app resumes after ≥2 hours of inactivity, it calls `AuthCubit.signOutDueToInactivity()`, which returns the user to `LoginPage`.

## Sync model

Isar is the device source of truth. `ScoutingRecord.synced` and `PitScoutingRecord.synced` (indexed bools) mark the offline queue.

`SyncRepository` handles bidirectional sync for three things:
- **Match records** (`scouting_records` Supabase table) — push unsynced, pull by event key
- **Pit records** (`pit_scouting_records` Supabase table) — same pattern
- **Picklists** (`picklists` table) — upsert all local; remote wins on `updatedAt` conflict

`SyncCubit` (provided in `HomeShell`):
- Calls `syncNow()` on mount (full push + pull)
- `Timer.periodic(1 min)` pulls records and picklists silently
- `StreamSubscription` on `ScoutingRepository.watchAll()` and `PitScoutingRepository.watchAll()` auto-pushes when unsynced count increases

Records are also shareable peer-to-peer via QR code (`qr_record_codec.dart` / `QrScanPage`).

## Scouting forms

### Match form — FSM

`FormPhase` enum declaration order defines the only legal transitions (index ±1):

```
auto → teleop → endgame → review
```

`FormStatus` (`editing / saving / saved / failure`) is a separate axis. All field values live in a flat `Map<String, Object?> values`; split into per-phase JSON at save time inside `ScoutingFormBloc._bucketFor()`.

### Pit form — single-page Cubit

`PitFormCubit` — no phase FSM. One `Map<String, Object?> values` → `PitScoutingRecord` on submit. Fields are grouped by `FieldConfig.section` for the section-header UI in `PitFormPage`.

### Game-agnostic field config

**`lib/features/scouting/config/game_config.dart` is the only file to edit each January.** It exports `kDefaultGameConfig` — a `List<FieldConfig>`. The form UI, stored JSON keys, and analytics all derive from this list. No DB migration is ever needed.

`lib/features/scouting/config/pit_config.dart` exports `kPitScoutingConfig` — same `FieldConfig` type. Pit fields use `ScoutPhase.auto` as a placeholder; the pit form ignores phase entirely.

`FieldType` options: `counter`, `toggle`, `choice`, `rating`, `stopwatch`, `text`.

Field `key` strings are permanent — they become JSON map keys in stored records.

## Settings persistence

`SettingsRepository` reads and writes a plain JSON file (`settings.json` in the app support directory). Not Isar-backed. Call `init()` before `runApp` (already done). Key settings: `scouterName`, `themeMode`, `eventKeyOverride`, `showPastMatchesTab`.

## Schedule feature

`ScheduleCubit` is provided in `HomeShell` (not `main.dart`) — it only lives while the shell is mounted.

`ScheduleRepository` combines:
- **TBA** (`/event/{key}/matches/simple`, `/oprs`, `/rankings`) — schedule, results, OPR/ranking data
- **Nexus** (`/event/{key}`) — live queue status (Now queuing / On deck / On field)

Event auto-detection priority: active today → next upcoming → most recent past → `AppConfig.currentEventKey`. The Past Matches tab uses `detectPastEvent()` independently of the main schedule event.

## Teams feature

Three sub-tabs in `TeamsPage`:

1. **Rankings** (`RatingsCubit`) — pulls TBA `/rankings` for W-L-T, OPR, RP. Emits `RatingsNoEvent` if no upcoming/active event exists, showing "No upcoming competitions" instead of stale data. Bail path: if `detectCurrentEvent()` returns `EventStatus.past`, emit `RatingsNoEvent` and return early.
2. **Pit Map** (`TeamsCubit`) — Nexus pit location data. Separate from `RatingsCubit`.
3. **Picklist** (`PicklistCubit`) — also suppressed on past events via the same `EventStatus` check. Tapping a team row opens `TeamDossierSheet` — a bottom sheet showing OPR/DPR/CCWM, ranking, and real match score spread. Entirely TBA-derived; no human scouting feeds it.

## Match prediction system

`MatchPrediction.compute(match, ratings)` is TBA-data-only. Alliance expected score = Σ OPR; P(red wins) via `normalCdf` over margin / spread. Suppressed when OPRs aren't available. `MatchPredictionBar` renders as a color-split bar under each upcoming `MatchTile`.

## Update system

Two separate update paths — both are transparent to scouters:

- **Shorebird patches** (Dart-only changes) — applied automatically by the Shorebird SDK on launch. No cubit involved; `shorebird.yaml` configures the app ID.
- **GitHub APK releases** (native or large changes, Android only) — `UpdateCubit` calls `UpdateRepository.checkForUpdate()` once per launch, comparing `pubspec.yaml`'s `version` against the latest GitHub release tag via `GithubReleaseService`. If newer, `UpdateBanner` appears and `downloadAndInstall()` streams `InstallStep` progress to the cubit, ending with the system install prompt.

**Versioning rule:** The `version` field in `pubspec.yaml` must match the GitHub release tag (e.g. tag `v26.2.0` → `version: 26.2.0+N`). The build number `+N` must strictly increase per release. `lib/core/utils/app_version.dart` contains the pure version-comparison helpers.

`UpdateCubit` is dormant on iOS — APK self-update is Android-only.

## Offline caching

`MatchRepository` and `EventRepository` are Isar-backed caches so the schedule works offline after first load. `ScheduleRepository` writes through to them and reads from them when the network is unavailable. They are distinct from the scouting record repositories and never contain user-generated data.

## State management

`flutter_bloc` throughout — no `setState` anywhere in production code.

- Complex multi-phase logic → `Bloc` (`ScoutingFormBloc`)
- Simpler reactive state → `Cubit` (everything else)

`StopwatchCubit` owns the only `dart:async Timer` in the scouting form widgets. `SyncCubit` owns the only `Timer.periodic` in the app.
