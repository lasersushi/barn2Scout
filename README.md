# Barn2Scout

**FRC Team 751 · Offline-first scouting for iOS and Android**

Barn2Scout is a custom in-house scouting app for Barn 2 Robotics. Scouts record qualitative match observations and pit data at competitions — no internet required. QR codes sync records between phones when WiFi is unavailable, and a Supabase backend syncs everything to the cloud when connectivity is restored.

---

## Features

| Tab | What it does |
|---|---|
| **My Schedule** | Team 751's upcoming matches with win-probability predictions and live Nexus queue status (queuing / on deck / on field) |
| **Schedules** | Full event schedule for all teams, upcoming matches only, 751's matches highlighted |
| **Teams** | Three sub-tabs: live TBA **Rankings** (W-L-T, OPR, RP), Nexus **Pit Map**, and **Picklist** |
| **Records** | Saved scouting records — two tabs: **Match** and **Pit**. Tap to view details, swipe to delete your own |
| **Settings** | Preferences, account, sync status |
| **Past Matches** *(optional)* | Played matches from the most recent event — enabled in Settings |

**Match scouting** captures what TBA can't: driver skill, defense effectiveness, qualitative observations per phase. TBA provides all objective metrics (OPR, DPR, CCWM, scores, rankings) — scouts never enter numbers.

**Pit scouting** captures robot hardware: drivetrain type, weight, dimensions, auto capabilities, and observations.

**QR sync** — share records peer-to-peer without WiFi:
- Tap any record → full-screen QR code
- Tap the scanner icon → scan another phone's QR → record imported instantly
- UUID deduplication prevents double imports

**Cloud sync** — automatic Supabase sync:
- Full sync on app open
- Auto-push whenever a new record is saved
- Periodic pull every 60 seconds
- Manual sync button in the Records tab

**Auth** — restricted to `@priorypanther.com` accounts:
- Sign in required on every cold start
- Automatic sign-out after 2 hours of inactivity
- Password change with re-authentication

---

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter 3.44 / Dart 3.12, Material 3 |
| State | `flutter_bloc` 9.1 — Bloc for FSMs, Cubit everywhere else |
| Local DB | `isar_community` 3.3.2 (Isar v3 API, Dart 3.12 compatible) |
| Cloud | Supabase (auth + sync) |
| HTTP | `http` + TBA API v3 + Nexus API v1 |
| QR | `qr_flutter` (generation) + `mobile_scanner` (camera) |
| Settings | `path_provider` + JSON file |

---

## Architecture

```
lib/
  main.dart              # Boots Isar + Supabase, injects repos, reads settings before runApp
  app.dart               # MaterialApp + AuthCubit — shows LoginPage or HomeShell
  core/
    config/app_config.dart       # API keys + Supabase credentials (gitignored)
    theme/                       # AppTheme — seed color 0xFF2E7D32 (Team 751 green)
    utils/                       # stats_utils (normalCdf), qr_record_codec
  data/
    models/              # Isar @collection classes (ScoutingRecord, PitScoutingRecord, ...) + value types
    services/            # IsarService, TbaService, NexusService
    repositories/        # All repos — ScheduleRepository is the most complex
  features/
    auth/                # AuthCubit + LoginPage (@priorypanther.com only)
    shell/               # HomeShell (IndexedStack tabs), NavigationCubit, inactivity observer
    scouting/            # Match form (Bloc FSM) + Pit form (Cubit) + FieldConfig system
    records/             # Match/Pit TabBar, QR export/import
    schedule/            # My Schedule, Schedules, Past Matches + ScheduleCubit
    teams/               # Rankings, Pit Map, Picklist sub-tabs
    sync/                # SyncCubit — periodic pull + auto-push on new record
    settings/            # Preferences + account section
```

**Data flow rule:** UI and Blocs talk only to repositories — never directly to Isar, Supabase, TBA, or Nexus.

**Rankings / analytics rule:** All objective metrics (OPR, DPR, CCWM, scores, W-L-T) come from TBA only. Human scouting data is qualitative and never feeds rankings or predictions.

---

## Scouting Forms

### Match form

A strict finite-state machine — phases advance and revert by index ±1 only:

```
auto → teleop → endgame → review → saved
```

Fields (qualitative only — TBA handles scores):

| Phase | Field | Type |
|---|---|---|
| Auto | Left starting line | Toggle |
| Auto | Auto observations | Text |
| Teleop | Defense effectiveness | 0–5 rating |
| Teleop | Driver skill | 0–5 rating |
| Teleop | Teleop observations | Text |
| Endgame | Climb result | Choice (None / Park / Shallow / Deep) |
| Endgame | Endgame observations | Text |

**To update fields each January:** edit only `lib/features/scouting/config/game_config.dart`. No DB migration — phase data is stored as opaque JSON.

### Pit form

Single scrollable page grouped by section (Hardware / Auto Capabilities / Observations). Uses the same `FieldConfig` + `FieldInput` system as the match form.

| Section | Field | Type |
|---|---|---|
| Hardware | Drivetrain | Choice (Swerve / Tank / Mecanum / Other) |
| Hardware | Weight (lbs) | Counter |
| Hardware | Width / Length (in) | Counter |
| Auto | Leaves line, Scores L1/L2 | Toggles |
| Observations | Notes | Text |

---

## Event Detection

`ScheduleRepository.detectCurrentEvent()` picks the active event automatically:

1. **Active today** (start ≤ now ≤ end + 1 day)
2. **Next upcoming** event for Team 751
3. Hard fallback to `AppConfig.currentEventKey`

Rankings and picklists show **upcoming/active events only** — if no upcoming event exists, the app shows "No upcoming competitions" rather than stale past-event data.

---

## Setup

### Prerequisites

- Flutter 3.44+ / Dart 3.12+
- Xcode (iOS) or Android Studio (Android)
- A Supabase project with the schema below

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
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';
}
```

### Supabase schema

```sql
-- Match scouting records
create table scouting_records (
  id uuid primary key,
  user_id uuid references auth.users not null,
  team_number int not null,
  match_number int,
  event_key text not null,
  scouter_name text,
  timestamp timestamptz,
  auto_data jsonb,
  teleop_data jsonb,
  endgame_data jsonb,
  notes text
);

alter table scouting_records enable row level security;
create policy "authenticated read" on scouting_records for select using (auth.role() = 'authenticated');
create policy "insert own" on scouting_records for insert with check (auth.uid() = user_id);

-- Pit scouting records
create table pit_scouting_records (
  id uuid primary key,
  user_id uuid references auth.users not null,
  team_number int not null,
  event_key text not null,
  scouter_name text,
  timestamp timestamptz,
  pit_data jsonb,
  notes text
);

alter table pit_scouting_records enable row level security;
create policy "authenticated read" on pit_scouting_records for select using (auth.role() = 'authenticated');
create policy "insert own" on pit_scouting_records for insert with check (auth.uid() = user_id);

-- Picklists
create table picklists (
  id text primary key,
  name text,
  picks jsonb,
  vetoes jsonb,
  updated_at timestamptz
);

alter table picklists enable row level security;
create policy "authenticated read" on picklists for select using (auth.role() = 'authenticated');
create policy "authenticated upsert" on picklists for insert with check (auth.role() = 'authenticated');
create policy "authenticated update" on picklists for update using (auth.role() = 'authenticated');
```

### Run

```bash
flutter pub get
flutter run -d <device-id>   # list devices: flutter devices
```

### Codegen (after editing any @collection class)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Security

`app_config.dart` is gitignored. TBA and Nexus keys grant read-only access to public FRC data. Supabase RLS restricts all writes to the authenticated user's own rows; reads require a valid `@priorypanther.com` session.

---

## Team

Built and maintained by **Lucas Walker** — FTC/FRC software lead, Woodside Priory School, Class of 2030.  
GitHub: [lasersushi](https://github.com/lasersushi)
