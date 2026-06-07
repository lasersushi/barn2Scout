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
flutter run -t lib/prototype/picklist_prototype.dart
```

Hot reload: press `r` in the terminal running `flutter run`. Hot restart: `R`.

## Architecture

Feature-first layout under `lib/features/`. Data layer in `lib/data/`.

```
lib/
  main.dart              # Boots IsarService + SettingsRepository, injects all repos
  app.dart               # MaterialApp, light/dark theme
  core/
    config/app_config.dart  # Team identity + API keys (gitignored — update each event)
    theme/               # AppTheme — seed color 0xFF2E7D32 (Team 751 green)
    utils/               # stats_utils (normalCdf), qr_record_codec
  data/
    models/              # Isar @collection classes + plain value types
    services/            # IsarService, TbaService, NexusService
    repositories/        # All repo classes; ScheduleRepository is the most complex
  features/
    shell/               # HomeShell (IndexedStack tabs), NavigationCubit
    scouting/            # Match scouting form (Bloc FSM + FieldConfig system)
    records/             # List of saved ScoutingRecords, QR share/scan
    schedule/            # My Schedule, All Schedules, Past Matches tabs
    teams/               # Rankings + team dossier sheet (analytics)
    settings/            # Preferences backed by JSON file (not Isar)
  prototype/             # Throwaway explorations; never imported from real code
```

**Data flow rule:** UI and Blocs talk only to repositories, never directly to Isar/TBA/Supabase.

## AppConfig — update each event

`lib/core/config/app_config.dart` is **gitignored** and holds API keys plus `currentEventKey`. Update `currentEventKey` at the start of each competition (e.g. `'2026cacac'`). The schedule auto-detects the active event from TBA, but this serves as the hard fallback.

## Isar (offline database)

Uses `isar_community` v3.3.2 — **not** the official `isar` package. The official package is frozen and its bundled analyzer can't parse Dart 3.12 syntax. Import path: `package:isar_community/isar.dart`. API is identical to Isar v3.

After editing any `@collection` class, regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```

`*.g.dart` files are committed. The analyzer excludes them (see `analysis_options.yaml`) to suppress Isar's `@experimental` method warnings.

Isar cannot store `Map<String, dynamic>` directly. The pattern used everywhere is: store as a JSON string field (`xyzJson`), expose via `@ignore` typed getter/setter.

## Settings persistence

`SettingsRepository` reads and writes a plain JSON file (`settings.json` in the app support directory). It is **not** Isar-backed. Call `init()` before `runApp` (already done in `main.dart`) so the first frame has the correct theme. Key settings: `scouterName`, `themeMode`, `eventKeyOverride` (overrides TBA event auto-detect), `showPastMatchesTab` (toggles the Past Matches tab in `HomeShell`).

## Schedule feature

`ScheduleCubit` is provided in `HomeShell` (not `main.dart`) — it only lives while the shell is mounted. The feature has three views behind a single cubit:

- **My Schedule** (`Barn2SchedulePage`) — Team 751's upcoming matches + Nexus queue chips
- **Schedules** (`OtherTeamSchedulesPage`) — All teams' upcoming matches
- **Past Matches** (`PastMatchesPage`) — hidden by default; enabled in Settings → Tabs

`ScheduleRepository` combines two APIs:
- **TBA** (`/event/{key}/matches/simple`, `/oprs`, `/rankings`) — match schedule, results, OPR data
- **Nexus** (`/event/{key}`) — live queue status (Now queuing / On deck / On field)

Event auto-detection priority: active today → next upcoming → most recent past → `AppConfig.currentEventKey`. The cubit detects the "current" event (for the schedule tabs) and the "past" event (for the Past Matches tab) concurrently; they can differ between competitions.

## Match prediction system

`MatchPrediction.compute(match, ratings)` builds a win-probability prediction purely from TBA data (no scouting). Model: alliance expected score = Σ OPR; P(red wins) derived from margin / spread via `normalCdf`. Weights are tunable in `PredictionConfig` / `kPredictionConfig`. Predictions are suppressed (no bar rendered) when OPRs aren't available yet. `MatchPredictionBar` renders the result as a color-split bar below each upcoming `MatchTile`.

## Scouting form FSM

The form is a strict finite-state machine. `FormPhase` enum declaration order in `scouting_form_state.dart` defines the only legal transitions — the bloc advances/reverts by index ±1 only:

```
auto → teleop → endgame → review
```

Skipping phases is structurally impossible (no conditional logic to bypass). `FormStatus` (`editing / saving / saved / failure`) is a separate axis from `FormPhase`.

All field values are stored in a flat `Map<String, Object?> values` during editing, then split into per-phase JSON buckets (`autoDataJson`, `teleopDataJson`, `endgameDataJson`) only at save time inside `ScoutingFormBloc._bucketFor()`.

## Game-agnostic field config

**`lib/features/scouting/config/game_config.dart` is the only file to edit each January when the FRC game changes.** It exports `kDefaultGameConfig` — a `List<FieldConfig>`. The form UI, stored JSON keys, analytics (`TeamAnalytics`), and prediction weights all derive from this list automatically. No DB migration is ever needed because phase data is stored as opaque JSON.

`FieldType` options: `counter`, `toggle`, `choice`, `rating`, `stopwatch`, `text`.

Field `key` strings are permanent — they become JSON map keys in stored `ScoutingRecords`.

## Teams / analytics feature

`AnalyticsCubit` subscribes to `ScoutingRepository.watchAll()` — rankings update live whenever a record is saved or deleted, no manual reload. `TeamAnalytics.aggregate()` iterates `kDefaultGameConfig` to compute per-field stats (avg, pct, dist) and a `composite` score. Displayed in `TeamsPage` as a ranked list; tapping opens `TeamDossierSheet`.

## State management

`flutter_bloc` throughout — no `setState` anywhere.

- Complex multi-phase logic → `Bloc` (e.g. `ScoutingFormBloc`)
- Simpler reactive state → `Cubit` (e.g. `NavigationCubit`, `RecordsCubit`, `ScheduleCubit`, `AnalyticsCubit`)

`StopwatchCubit` owns a `dart:async Timer` that ticks the live stopwatch — the only place a `Timer` lives.

## Sync model

Isar is the device source of truth. Supabase is sync-only (not yet implemented). `ScoutingRecord.synced` (indexed bool) marks the offline queue — `ScoutingRepository.getUnsynced()` returns records to push; `markSynced(uuids)` clears the flag after a successful Supabase write.

Records can also be shared peer-to-peer via QR code (`qr_record_codec.dart` / `QrScanPage`).
