# Barn2Scout

**FRC Team 751 · Offline-first match scouting for iOS and Android**

Barn2Scout is a custom built in-house scouting solution for Barn 2 robotics.

---

## Features

| Tab | What it does |
|---|---|
| **My Schedule** | Team 751's upcoming matches with match outcome prediction and live Nexus queue status (queuing / on deck / on field) |
| **Schedules** | Full event schedule — all teams, upcoming matches only, 751's matches highlighted |
| **Teams** | Nexus pit map — team pit locations by row and slot |
| **Records** | Saved scouting records — tap to view QR, swipe to delete your own |
| **Past Matches** *(optional)* | Played matches from the most recent competition — Mine tab and All tab |

**Settings**
- Scouter name (persists across sessions, pre-fills new record dialogs; this is kept private and locally stored on the users phone)
- Light / Dark / System theme
- Event key override (skip auto-detection)
- Enable/disable the Past Matches tab

**QR sync**
- The QR sync feature allows scouters to share intformation when they don't have access to wifi or cell service,
- Tap any record → full-screen QR code
- Tap the scanner icon → scan another phone's QR → record imported instantly
- UUID deduplication prevents double imports

---

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter 3.44 / Dart 3.12 |
| State | `flutter_bloc` 9.1 — Bloc for complex FSMs, Cubit for simple state |
| Local DB | `isar_community` 3.3.2 (Isar v3 API, Dart 3.12 compatible) |
| HTTP | `http` + TBA API + Nexus API |
| QR | `qr_flutter` (generation) + `mobile_scanner` (camera) |
| Settings | `path_provider` + JSON file |

---

## Architecture

```
lib/
  main.dart              # Boots Isar, injects repositories, reads settings before runApp
  app.dart               # MaterialApp — rebuilds only on themeMode change
  core/
    config/app_config.dart       # API keys + team identity (gitignored)
    theme/app_theme.dart         # Barn2 blue seed color (#0060A7)
    utils/qr_record_codec.dart   # QR encode/decode
  data/
    models/              # Isar @collection classes + TBA/Nexus PODOs
    services/            # TbaService, NexusService (HTTP clients)
    repositories/        # ScoutingRepository, ScheduleRepository, SettingsRepository, TeamRepository
  features/
    shell/               # HomeShell — IndexedStack nav, dynamic tab list
    scouting/            # Match scouting form (strict FSM: auto → teleop → endgame → review)
    records/             # Saved records list, QR export/import, delete
    schedule/            # My Schedule, Schedules, Past Matches pages + ScheduleCubit
    teams/               # Pit map (Nexus)
    settings/            # Settings page + SettingsCubit
```

**Data flow rule:** UI and Blocs talk only to repositories — never directly to Isar, TBA, or Nexus.

---

## Scouting Form

The form is a strict finite-state machine. Phase order is defined by declaration order in `FormPhase` — the bloc advances/reverts by index ±1 only:

```
auto → teleop → endgame → review → saved
```

All field values live in a flat `Map<String, Object?> values` during editing, then split into per-phase JSON at save time.

**To update fields for a new season:** edit only `lib/features/scouting/config/game_config.dart`. No DB migration needed — phase data is stored as opaque JSON keyed by field name.

---

## Event Detection

`ScheduleRepository.detectCurrentEvent()` resolves Team 751's event automatically:

1. **Active today** (start ≤ now ≤ end + 1 day) → title: `751 @ [event]`
2. **Next upcoming** → title: `Next: [event]`
3. **Most recently completed** (off-season fallback) → title: `Last: [event]`
4. Hard fallback to `AppConfig.currentEventKey`

The Past Matches tab always loads from `detectPastEvent()` — the most recently completed event — so between competitions it shows Contra Costa results even while the upcoming schedule points to the next event.

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
}
```

### Run

```bash
flutter pub get
flutter run -d <device-id>   # list devices: flutter devices
```

### Regenerate Isar models after editing any @collection class

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Data

Isar is the source of truth on each device. Records are marked `synced = false` until pushed. `ScoutingRepository.getUnsynced()` returns the offline queue; Supabase sync is planned but not yet implemented.

Isar cannot store `Map<String, dynamic>` directly — the pattern everywhere is a JSON string field (`xyzDataJson`) with an `@ignore` typed getter/setter on top.

---

## Security

**Security review status:** No exploitable vulnerabilities identified (reviewed June 2026).

### Key security properties

| Property | Implementation |
|---|---|
| **API keys** | `app_config.dart` is gitignored and never committed. Both keys (TBA, Nexus) grant read-only access to public FRC competition data — no PII, no write access. |
| **Local data** | All scouting records stay on-device in Isar. No data leaves the device without an explicit QR export or future Supabase sync. |
| **QR imports** | Scanned records are validated (UUID, match key, team number formats) before being written to Isar. Phase data maps are accepted from QR payloads; input should be validated against `kDefaultGameConfig` field keys and types before saving to guard against malformed imports. |
| **No auth surface** | The app has no login, no server, and no multi-user backend. There is no authentication or session management to exploit. |
| **Network** | All HTTP calls go to `thebluealliance.com` (TBA API v3) or `frc.nexus` (Nexus API v1). Both hosts are hardcoded — user input can only affect the URL path (event key), not the host or protocol. |
| **Settings** | User preferences are stored as a plain JSON file in the app's sandboxed support directory via `SettingsRepository`. |

### Threat model

Barn2Scout is an **internal team tool** distributed via TestFlight or direct sideload to a known set of team members. It is not a public app. The primary risk surface is the QR scan flow, where a malicious QR code constructed by someone with physical access could import a corrupt record — validate QR payloads against `kDefaultGameConfig` to close this.

---

## Team

Built and maintained by **Lucas Walker** — FTC/FRC software lead, Woodside Priory School.  
GitHub: [lasersushi](https://github.com/lasersushi)
