import 'dart:math' as math;

import '../../core/config/app_config.dart';
import '../models/nexus_match.dart';
import '../models/nexus_pit.dart';
import '../models/tba_match.dart';
import '../models/team_rating.dart';
import '../services/nexus_service.dart';
import '../services/tba_service.dart';
import 'settings_repository.dart';

/// Where the detected "current" event sits relative to today.
///   - [active]   — happening right now
///   - [upcoming] — registered but hasn't started yet
///   - [past]     — already finished (the season is over / between seasons)
enum EventStatus { active, upcoming, past }

/// Combines TBA (full schedule + results) with Nexus (live queue status).
///
/// TBA is the authority on match data. Nexus supplements with real-time status
/// only when Team 751's event is currently active in Nexus.
class ScheduleRepository {
  ScheduleRepository({
    required this.tba,
    required this.nexus,
    required this.settings,
  });

  final TbaService tba;
  final NexusService nexus;
  final SettingsRepository settings;

  /// In-memory cache of the year's events. Fetched once, shared by both detect
  /// methods so we only hit TBA once even if both are called.
  List<Map<String, dynamic>>? _cachedEvents;

  String? _cachedEventKey;
  EventStatus _cachedStatus = EventStatus.past;
  String? _cachedPastEventKey;

  /// The resolved event key if already detected, otherwise the config fallback.
  String get resolvedEventKey => _cachedEventKey ?? AppConfig.currentEventKey;

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    if (_cachedEvents != null) return _cachedEvents!;
    final year = DateTime.now().year;
    final data = await tba.get(
      '/team/${AppConfig.myTeamKey}/events/$year/simple',
    ) as List;
    return _cachedEvents = data.cast<Map<String, dynamic>>();
  }

  /// Finds Team 751's relevant event for the UPCOMING schedule:
  ///   1. Active today (start ≤ now ≤ end+1d)  → [EventStatus.active]
  ///   2. Next upcoming                        → [EventStatus.upcoming]
  ///   3. Most recently completed (off-season) → [EventStatus.past]
  ///   4. Hard fallback to AppConfig.currentEventKey → [EventStatus.past]
  ///
  /// Returns `(key, status)` — callers use [status] to label the title:
  /// "751 @ X" (active), "Next: X" (upcoming), or "Last: X" (past).
  Future<({String key, EventStatus status})> detectCurrentEvent() async {
    // A manual event override (Settings → Event Key Override) always wins over
    // TBA auto-detection. Read fresh every call so changing it takes effect
    // without an app restart, and never cached so clearing it falls straight
    // back to auto-detection. Reported as `active` so the rankings / pit-map
    // tabs populate even when the override points at a finished event (e.g.
    // testing against a past competition).
    final override = settings.eventKeyOverride;
    if (override != null && override.isNotEmpty) {
      return (key: override, status: EventStatus.active);
    }

    if (_cachedEventKey != null) {
      return (key: _cachedEventKey!, status: _cachedStatus);
    }

    final events = await _fetchEvents();
    final now = DateTime.now();

    ({String key, EventStatus status}) result(String key, EventStatus status) {
      _cachedEventKey = key;
      _cachedStatus = status;
      return (key: key, status: status);
    }

    // 1 — currently active
    for (final e in events) {
      final start = DateTime.parse(e['start_date'] as String);
      final end =
          DateTime.parse(e['end_date'] as String).add(const Duration(days: 1));
      if (now.isAfter(start) && now.isBefore(end)) {
        return result(e['key'] as String, EventStatus.active);
      }
    }

    // 2 — next upcoming (preferred over past — scouts want to prepare)
    final future = events
        .where((e) => DateTime.parse(e['start_date'] as String).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(a['start_date'] as String)
          .compareTo(DateTime.parse(b['start_date'] as String)));
    if (future.isNotEmpty) {
      return result(future.first['key'] as String, EventStatus.upcoming);
    }

    // 3 — most recently completed (season's over, no upcoming events)
    final past = events
        .where((e) => DateTime.parse(e['end_date'] as String).isBefore(now))
        .toList()
      ..sort((a, b) => DateTime.parse(b['end_date'] as String)
          .compareTo(DateTime.parse(a['end_date'] as String)));
    if (past.isNotEmpty) {
      return result(past.first['key'] as String, EventStatus.past);
    }

    // 4 — hardcoded fallback
    return result(AppConfig.currentEventKey, EventStatus.past);
  }

  /// Always returns the most recently completed event — used by the Past
  /// Matches tab so it shows results from the last competition even when the
  /// upcoming schedule is pointing at the next (future) event.
  Future<String> detectPastEvent() async {
    // Honour the manual override here too, so the Past Matches tab shows the
    // overridden event's results instead of auto-detecting independently.
    final override = settings.eventKeyOverride;
    if (override != null && override.isNotEmpty) return override;

    if (_cachedPastEventKey != null) return _cachedPastEventKey!;

    final events = await _fetchEvents();
    final now = DateTime.now();

    // Check if currently active — in that case, past = same event
    for (final e in events) {
      final start = DateTime.parse(e['start_date'] as String);
      final end =
          DateTime.parse(e['end_date'] as String).add(const Duration(days: 1));
      if (now.isAfter(start) && now.isBefore(end)) {
        return _cachedPastEventKey = e['key'] as String;
      }
    }

    // Most recently completed
    final past = events
        .where((e) => DateTime.parse(e['end_date'] as String).isBefore(now))
        .toList()
      ..sort((a, b) => DateTime.parse(b['end_date'] as String)
          .compareTo(DateTime.parse(a['end_date'] as String)));
    if (past.isNotEmpty) return _cachedPastEventKey = past.first['key'] as String;

    return _cachedPastEventKey = AppConfig.currentEventKey;
  }

  /// Fetches all matches for [eventKey] from TBA, sorted in competition order.
  Future<List<TbaMatch>> getMatches(String eventKey) async {
    final data = await tba.get('/event/$eventKey/matches/simple') as List;
    final matches = data
        .cast<Map<String, dynamic>>()
        .map(TbaMatch.fromJson)
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return matches;
  }

  /// Builds the per-team strength map used for match prediction, entirely from
  /// TBA (no scouting). Combines:
  ///   - `/oprs`      → OPR / DPR / CCWM
  ///   - `/rankings`  → rank, avg ranking points, W-L-T record
  ///   - [matches]    → each team's real alliance-score mean + std (already
  ///                    loaded for the schedule, so no extra calls)
  ///
  /// Returns an empty map (→ no predictions shown) if TBA has no OPRs yet,
  /// e.g. before the event's first matches are played.
  Future<Map<int, TeamRating>> fetchTeamRatings(
    String eventKey,
    List<TbaMatch> matches,
  ) async {
    // 1 — OPR/DPR/CCWM. Required; absent until a few matches are played.
    Map<String, dynamic> oprData;
    try {
      oprData = await tba.get('/event/$eventKey/oprs') as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
    final oprs = (oprData['oprs'] as Map?)?.cast<String, dynamic>() ?? {};
    if (oprs.isEmpty) return {};
    final dprs = (oprData['dprs'] as Map?)?.cast<String, dynamic>() ?? {};
    final ccwms = (oprData['ccwms'] as Map?)?.cast<String, dynamic>() ?? {};

    // 2 — rankings (optional; OPR-only prediction still works without it).
    final ranks = <int, ({int rank, double? avgRp, double? winRate, int? wins, int? losses, int? ties})>{};
    try {
      final rData =
          await tba.get('/event/$eventKey/rankings') as Map<String, dynamic>;
      for (final raw in ((rData['rankings'] as List?) ?? [])
          .cast<Map<String, dynamic>>()) {
        final n = int.tryParse(TbaMatch.displayNumber(raw['team_key'] as String));
        if (n == null) continue;
        // sort_orders[0] is the "Ranking Score" (avg RP) in recent games.
        final sortOrders = (raw['sort_orders'] as List?) ?? [];
        final avgRp =
            sortOrders.isNotEmpty ? (sortOrders.first as num?)?.toDouble() : null;
        final record = (raw['record'] as Map?)?.cast<String, dynamic>();
        double? winRate;
        if (record != null) {
          final w = (record['wins'] as num?)?.toInt() ?? 0;
          final l = (record['losses'] as num?)?.toInt() ?? 0;
          final t = (record['ties'] as num?)?.toInt() ?? 0;
          if (w + l + t > 0) winRate = w / (w + l + t);
        }
        ranks[n] = (
          rank: (raw['rank'] as num?)?.toInt() ?? 0,
          avgRp: avgRp,
          winRate: winRate,
          wins: (record?['wins'] as num?)?.toInt(),
          losses: (record?['losses'] as num?)?.toInt(),
          ties: (record?['ties'] as num?)?.toInt(),
        );
      }
    } catch (_) {
      // rankings unavailable — leave avgRp/winRate/rank null.
    }

    // 3 — per-team alliance-score samples from played matches.
    final samples = <int, List<double>>{};
    void collect(List<String> keys, int? score) {
      if (score == null) return;
      for (final k in keys) {
        final n = int.tryParse(TbaMatch.displayNumber(k));
        if (n != null) (samples[n] ??= []).add(score.toDouble());
      }
    }

    for (final m in matches) {
      if (!m.isPlayed) continue;
      collect(m.redTeams, m.redScore);
      collect(m.blueTeams, m.blueScore);
    }

    // 4 — merge into one rating per TBA-rated team.
    final out = <int, TeamRating>{};
    for (final entry in oprs.entries) {
      final n = int.tryParse(TbaMatch.displayNumber(entry.key));
      if (n == null) continue;
      final xs = samples[n] ?? const <double>[];
      final stats = _meanStd(xs);
      final r = ranks[n];
      out[n] = TeamRating(
        team: n,
        opr: (entry.value as num).toDouble(),
        dpr: (dprs[entry.key] as num?)?.toDouble() ?? 0,
        ccwm: (ccwms[entry.key] as num?)?.toDouble() ?? 0,
        avgRp: r?.avgRp,
        winRate: r?.winRate,
        wins: r?.wins,
        losses: r?.losses,
        ties: r?.ties,
        rank: r?.rank,
        scoreMean: stats.mean,
        scoreStd: stats.std,
        matchesPlayed: xs.length,
      );
    }
    return out;
  }

  /// Sample mean + std (Bessel-corrected) of [xs]. std is null below 2 samples.
  ({double? mean, double? std}) _meanStd(List<double> xs) {
    if (xs.isEmpty) return (mean: null, std: null);
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    if (xs.length < 2) return (mean: mean, std: null);
    final variance =
        xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
            (xs.length - 1);
    return (mean: mean, std: math.sqrt(variance));
  }

  /// Fetches the event name from TBA.
  Future<String> getEventName(String eventKey) async {
    final data =
        await tba.get('/event/$eventKey/simple') as Map<String, dynamic>;
    return data['name'] as String? ?? eventKey;
  }

  /// Returns live Nexus matches for [eventKey], or an empty list if the event
  /// isn't currently active in Nexus (e.g. off-season, between events).
  Future<List<NexusMatch>> getNexusMatches(String eventKey) async {
    final event = await nexus.getEvent(eventKey);
    if (event == null) return [];
    final raw = event['matches'] as List? ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(NexusMatch.fromJson)
        .toList();
  }

  /// Returns pit assignments for [eventKey], or an empty list if Nexus
  /// volunteers haven't configured the pit map yet.
  Future<List<NexusPit>> getPits(String eventKey) async {
    try {
      final data = await nexus.getRaw('/event/$eventKey/pits');
      // Nexus returns a plain string when no pits are configured.
      if (data is String) return [];
      return NexusPit.parseResponse(data);
    } catch (_) {
      return [];
    }
  }
}
