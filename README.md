# Barn2Scout

**FRC Team 751 · Offline-first match and pit scouting for iOS and Android**

Barn2Scout is a custom built in-house scouting solution for Barn 2 robotics.

---

## Features

Scouters sign in with a team email and land on a five- or six-tab shell. Admins get the same tabs plus **Manage**.

| Tab | What it does |
|---|---|
| **Schedule** | Team 751's upcoming matches with match outcome prediction and live Nexus queue status (queuing / on deck / on field) |
| **Schedules** | Full event schedule — all teams, upcoming matches only, 751's matches highlighted |
| **Teams** | Three sub-tabs: **Rankings** (W-L-T, OPR, RP from TBA), **Pit Map** (Nexus pit locations by row and slot), **Picklist** (shared, synced ordering — tap a team for a TBA dossier) |
| **Records** | Saved match and pit records in a TabBar, plus **My Tasks** — your assigned pit-scouting checklist. Tap to view QR, swipe to delete your own |
| **Manage** *(admin only)* | Assign the event's pit-scouting workload across scouts |
| **Settings** | Preferences and account |
| **Past** *(optional)* | Played matches from the most recent competition — Mine tab and All tab |

**Scouting forms**
- **Match** — a four-phase finite-state machine (`auto → teleop → endgame → review`)
- **Pit** — a single page, fields grouped into sections

**Settings**
- Scouter name (persists across sessions, pre-fills new record dialogs; kept private and stored locally on the user's phone)
- Light / Dark / System theme
- Event key override (skip auto-detection)
- Enable/disable the Past Matches tab
- Auto-logout time (60–300 minutes, default 180)

**Sync**
- Match records, pit records, and picklists sync bidirectionally with Supabase
- Records are pushed automatically as soon as they're saved, and pulled again every minute
- Anything created offline sits in a local queue until the device is back online

**QR sync**
- Lets scouters share records when they don't have wifi or cell service
- Tap any record → full-screen QR code
- Tap the scanner icon → scan another phone's QR → record imported instantly
- UUID deduplication prevents double imports

**Updates**
- **Shorebird** applies Dart-only patches automatically on launch
- **GitHub APK releases** (Android only) surface an in-app banner with download progress

---

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter 3.44 / Dart 3.12 |
| State | `flutter_bloc` 9.1 — Bloc for complex FSMs, Cubit for simple state |
| Local DB | `isar_community` 3.3.2 (Isar v3 API, Dart 3.12 compatible) |
| Backend | `supabase_flutter` — auth + Postgres sync |
| HTTP | `http` + TBA API + Nexus API + GitHub Releases API |
| QR | `qr_flutter` (generation) + `mobile_scanner` (camera) |
| Updates | `shorebird_code_push` (Dart patches) + `ota_update` (APK install) |
| Settings | `path_provider` + JSON file |

---

## Architecture

```
lib/
  main.dart              # Boots Isar + Supabase, injects repositories, reads settings before runApp
  app.dart               # MaterialApp + AuthCubit; _AuthGate routes to LoginPage / HomeShell / AdminShell
  core/
    config/app_config.dart       # API keys + team identity (gitignored)
    theme/app_theme.dart         # Barn2 blue seed color (#0060A7)
    utils/                       # qr_record_codec, stats_utils, app_version
  data/
    models/              # Isar @collection classes + TBA/Nexus/Supabase PODOs
    services/            # IsarService, TbaService, NexusService, GithubReleaseService
    repositories/        # Scouting, PitScouting, Schedule, Sync, Assignment, Picklist,
                         # Settings, Team, Match, Event, Update
  features/
    auth/                # AuthCubit (scouter / admin / super admin) + LoginPage
    shell/               # HomeShell and AdminShell — IndexedStack nav, dynamic tab list
    scouting/            # Match form (Bloc FSM) + pit form (Cubit) + FieldConfig system
    records/             # Match/pit records, QR export/import, delete
    schedule/            # Schedule, Schedules, Past Matches pages + ScheduleCubit
    teams/               # Rankings, pit map, picklist, team dossier
    management/          # Pit assignments (admin) + My Tasks (every scouter)
    sync/                # SyncCubit — periodic pull + auto-push on new record
    settings/            # Settings page + SettingsCubit
    update/              # UpdateCubit + UpdateBanner (Android APK OTA)
  prototype/             # Throwaway explorations; never imported from real code
```

**Data flow rule:** UI and Blocs talk only to repositories — never directly to Isar, TBA, Nexus, or Supabase.

**Rankings rule:** every objective metric (OPR, DPR, CCWM, scores, W-L-T, match predictions) comes from TBA. Human scouting data is qualitative only and never feeds a ranking or a prediction.

---

## Auth

Sign-in is required on every cold start. Three tiers, all checked in `AuthCubit`:

| Tier | Who |
|---|---|
| Scouter | any `@priorypanther.com` address → `HomeShell` |
| Admin | hardcoded mentor emails → `AdminShell` |
| Super admin | hardcoded emails plus any `@prioryca.org` address → `AdminShell`, can delete users |

Both shells watch the app lifecycle and sign the user out when the app resumes after more than `logoutTime` minutes of inactivity.

---

## Scouting Form

The match form is a strict finite-state machine. Phase order is defined by declaration order in `FormPhase` — the bloc advances/reverts by index ±1 only:

```
auto → teleop → endgame → review
```

All field values live in a flat `Map<String, Object?> values` during editing, then split into per-phase JSON at save time. The pit form uses the same `FieldConfig` type but has no phase FSM — one map, one submit.

**To update fields for a new season:** edit only `lib/features/scouting/config/game_config.dart` (match) and `lib/features/scouting/config/pit_config.dart` (pit). No DB migration needed — phase data is stored as opaque JSON keyed by field name. Field `key` strings are permanent, since they become the stored JSON keys.

---

## Event Detection

`ScheduleRepository.detectCurrentEvent()` resolves Team 751's event automatically:

1. **Active today** (start ≤ now ≤ end + 1 day) → title: `751 @ [event]`
2. **Next upcoming** → title: `Next: [event]`
3. **Most recently completed** (off-season fallback) → title: `Last: [event]`
4. Hard fallback to `AppConfig.currentEventKey`

The Past Matches tab always loads from `detectPastEvent()` — the most recently completed event — so between competitions it shows the last event's results even while the upcoming schedule points to the next one. Rankings, Picklist, and the assignment views suppress themselves entirely on a past event rather than showing stale data.

---

## Setup

### Prerequisites
- Flutter 3.44+ with Dart 3.12+
- Xcode (iOS) or Android Studio (Android)

### Config file (required, not committed)

Create `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  AppConfig._();
  static const int myTeamNumber = 751;
  static const String myTeamKey = 'frc751';
  static const String currentEventKey = '2026cacac'; // fallback only
  static const String tbaBaseUrl = 'https://www.thebluealliance.com/api/v3';
  static const String tbaKey = 'YOUR_TBA_KEY';
  static const String nexusBaseUrl = 'https://frc.nexus/api/v1';
  static const String nexusKey = 'YOUR_NEXUS_KEY';
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Update `currentEventKey` at the start of each competition.

### Run

```bash
flutter pub get
flutter run -d <device-id>   # list devices: flutter devices
```

### Regenerate Isar models after editing any @collection class

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Test and analyze

```bash
flutter test
flutter analyze
```

Tests use hand-written repository fakes under `test/helpers/` — there's no mocking library, and `dev_dependencies` is just `flutter_test`.

---

## Data

Isar is the source of truth on each device. Records are marked `synced = false` until pushed; `ScoutingRepository.getUnsynced()` and its pit equivalent return the offline queue. `SyncRepository` pushes that queue to Supabase and pulls the event's records back down, so the app is fully usable with no connection and reconciles when one returns.

Isar cannot store `Map<String, dynamic>` directly — the pattern everywhere is a JSON string field (`xyzJson`) with an `@ignore` typed getter/setter on top.

`MatchRepository` and `EventRepository` are separate Isar-backed caches of TBA data so the schedule works offline after the first load. They never hold user-generated data.

---

## Releasing

The `version` field in `pubspec.yaml` must match the GitHub release tag (tag `v26.2.0` → `version: 26.2.0+N`), because `UpdateCubit` compares them to decide whether to show the update banner. The `+N` build number must strictly increase with every release.

---

## Security

**Security review status:** No exploitable vulnerabilities identified (reviewed June 2026; predates the Supabase auth and sync work — worth a re-review).

### Key security properties

| Property | Implementation |
|---|---|
| **API keys** | `app_config.dart` is gitignored and never committed. The TBA and Nexus keys grant read-only access to public FRC competition data. The Supabase key is the anon key — access is enforced server-side by row-level security, not by the client. |
| **Auth** | Supabase email/password, restricted to team domains and a hardcoded admin list, re-checked on every sign-in. Sessions never survive a cold start. Both shells force a sign-out after the configured inactivity window. Destructive admin actions (user deletion) run through a Postgres RPC, so they're enforced server-side rather than client-side. |
| **Local data** | Scouting records live on-device in Isar. They leave the device only via Supabase sync or an explicit QR export. |
| **QR imports** | Scanned records are validated (UUID, match key, team number formats) before being written to Isar. Phase data maps are accepted from QR payloads; input should be validated against `kDefaultGameConfig` field keys and types before saving to guard against malformed imports. |
| **Network** | All HTTP calls go to `thebluealliance.com`, `frc.nexus`, the project's Supabase host, or the GitHub Releases API. Every host is hardcoded — user input can only affect the URL path (event key), not the host or protocol. |
| **Settings** | User preferences are stored as a plain JSON file in the app's sandboxed support directory via `SettingsRepository`. |

### Threat model

Barn2Scout is an **internal team tool** distributed via TestFlight or direct sideload to a known set of team members. It is not a public app. The main risk surfaces are the QR scan flow, where a malicious QR code constructed by someone with physical access could import a corrupt record (validate QR payloads against `kDefaultGameConfig` to close this), and the Supabase row-level security policies, which are the only thing standing between a signed-in scouter and another team's data.

---

## Team

Built and maintained by **Lucas Walker** — FTC/FRC software lead, Woodside Priory School.  
GitHub: [lasersushi](https://github.com/lasersushi)
</content>
