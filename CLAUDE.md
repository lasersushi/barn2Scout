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
```

Hot reload: press `r` in the terminal running `flutter run`. Hot restart: `R`.

## Architecture

Feature-first layout under `lib/features/`. Data layer in `lib/data/`.

```
lib/
  main.dart              # Boots IsarService, injects all repositories via MultiRepositoryProvider
  app.dart               # MaterialApp, light/dark theme
  core/theme/            # AppTheme — seed color 0xFF2E7D32 (Team 751 green)
  data/
    models/              # Isar @collection classes + .g.dart codegen
    services/            # IsarService (opens the DB)
    repositories/        # ScoutingRepository, TeamRepository, MatchRepository, EventRepository
  features/
    shell/               # HomeShell (IndexedStack tabs), NavigationCubit
    scouting/            # Match scouting form (Bloc FSM + FieldConfig system)
    records/             # List of saved ScoutingRecords, RecordsCubit
    schedule/            # Placeholder (TBA integration pending)
    teams/               # Placeholder (analytics pending)
    settings/            # Placeholder
```

**Data flow rule:** UI and Blocs talk only to repositories, never directly to Isar/TBA/Supabase.

## Isar (offline database)

Uses `isar_community` v3.3.2 — **not** the official `isar` package. The official package is frozen and its bundled analyzer can't parse Dart 3.12 syntax. Import path: `package:isar_community/isar.dart`. API is identical to Isar v3.

After editing any `@collection` class, regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```

`*.g.dart` files are committed. The analyzer excludes them (see `analysis_options.yaml`) to suppress Isar's `@experimental` method warnings.

Isar cannot store `Map<String, dynamic>` directly. The pattern used everywhere is: store as a JSON string field (`xyzJson`), expose via `@ignore` typed getter/setter.

## Scouting form FSM

The form is a strict finite-state machine. `FormPhase` enum declaration order in `scouting_form_state.dart` defines the only legal transitions — the bloc advances/reverts by index ±1 only:

```
auto → teleop → endgame → review
```

Skipping phases is structurally impossible (no conditional logic to bypass). `FormStatus` (`editing / saving / saved / failure`) is a separate axis from `FormPhase`.

All field values are stored in a flat `Map<String, Object?> values` during editing, then split into per-phase JSON buckets (`autoDataJson`, `teleopDataJson`, `endgameDataJson`) only at save time inside `ScoutingFormBloc._bucketFor()`.

## Game-agnostic field config

**`lib/features/scouting/config/game_config.dart` is the only file to edit each January when the FRC game changes.** It exports `kDefaultGameConfig` — a `List<FieldConfig>`. The form UI, stored JSON keys, and analytics all derive from this list automatically. No DB migration is ever needed because phase data is stored as opaque JSON.

`FieldType` options: `counter`, `toggle`, `choice`, `rating`, `stopwatch`, `text`.

Field `key` strings are permanent — they become JSON map keys in stored `ScoutingRecord`s.

## State management

`flutter_bloc` throughout — no `setState` anywhere.

- Complex multi-phase logic → `Bloc` (e.g. `ScoutingFormBloc`)
- Simpler reactive state → `Cubit` (e.g. `NavigationCubit`, `RecordsCubit`, `StopwatchCubit`)

`StopwatchCubit` owns a `dart:async Timer` that ticks the live stopwatch — the only place a `Timer` lives.

## Sync model

Isar is the device source of truth. Supabase is sync-only (not yet implemented). `ScoutingRecord.synced` (indexed bool) marks the offline queue — `ScoutingRepository.getUnsynced()` returns records to push; `markSynced(uuids)` clears the flag after a successful Supabase write.
