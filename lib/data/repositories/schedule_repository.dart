import 'dart:math' as math;

import '../../core/config/app_config.dart';
import '../models/event.dart';
import '../models/nexus_match.dart';
import '../models/nexus_pit.dart';
import '../models/nexus_pit_map.dart';
import '../models/rating_model.dart';
import '../models/tba_match.dart';
import '../models/team.dart';
import '../models/team_rating.dart';
import '../services/nexus_service.dart';
import '../services/tba_service.dart';
import 'event_repository.dart';
import 'settings_repository.dart';
import 'team_repository.dart';

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
    required this.events,
    required this.teams,
  });

  final TbaService tba;
  final NexusService nexus;
  final SettingsRepository settings;

  final EventRepository events;
  final TeamRepository teams;

  /// In-memory cache of this year's and next year's events. Fetched once,
  /// shared by both detect methods so we only hit TBA once even if both are
  /// called.
  List<Map<String, dynamic>>? _cachedEvents;

  String? _cachedEventKey;
  EventStatus _cachedStatus = EventStatus.past;
  String? _cachedPastEventKey;

  /// The resolved event key if already detected, otherwise the config fallback.
  String get resolvedEventKey => _cachedEventKey ?? AppConfig.currentEventKey;

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    if (_cachedEvents != null) return _cachedEvents!;
    final year = DateTime.now().year;

    // Next year too: from the end of the fall off-season until January, the
    // next comp is already registered under next season's year (Oct 2026 →
    // 2027casnf), and this year alone would only offer past events.
    Future<List<Map<String, dynamic>>> eventsIn(int y) async =>
        (await tba.get('/team/${AppConfig.myTeamKey}/events/$y/simple')
                as List)
            .cast<Map<String, dynamic>>();

    final results = await Future.wait([
      eventsIn(year),
      // Optional — failing it must not hide this year's events.
      eventsIn(year + 1).catchError((_) => <Map<String, dynamic>>[]),
    ]);
    return _cachedEvents = [...results[0], ...results[1]];
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

    final List<Map<String, dynamic>> events;
    try {
      events = await _fetchEvents();
    } catch (_) {
      // Offline — fall back to the comp from the last time we were online.
      // Deliberately not cached so the next call retries real detection.
      final lastKey = settings.lastDetectedEventKey;
      if (lastKey != null && lastKey.isNotEmpty) {
        final status = EventStatus.values.asNameMap()[
                settings.lastDetectedEventStatus ?? ''] ??
            EventStatus.past;
        return (key: lastKey, status: status);
      }
      return (key: AppConfig.currentEventKey, status: EventStatus.past);
    }
    final now = DateTime.now();

    ({String key, EventStatus status}) result(String key, EventStatus status) {
      _cachedEventKey = key;
      _cachedStatus = status;
      // Remember this detection so offline cold starts can reuse it.
      settings.setLastDetectedEvent(key, status.name);
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

  Future<List<Team>> getTeams(String eventKey) async {
    try {
      final data = await tba.get('/event/$eventKey/teams/simple') as List;
      final existing = {
        for (final team in await teams.getAll()) team.teamNumber: team,
      };

      final roster = <Team>[];
      for (final row in data.cast<Map<String, dynamic>>()) {
        final number = row['team_number'] as int;
        final nickname = (row['nickname'] as String?)?.trim();
        final label =
            (nickname == null || nickname.isEmpty) ? 'Team $number' : nickname;

        final cached = existing[number];
        if (cached == null) {
          roster.add(Team.create(teamNumber: number, nickname: label));
        } else {
          cached.nickname = label;
          roster.add(cached);
        }
      }
      roster.sort((a, b) => a.teamNumber.compareTo(b.teamNumber));

      await teams.upsertAll(roster);
      await _cacheRoster(eventKey, roster);
      return roster;
    } catch (_) {
      return _cachedTeams(eventKey);
    }
  }

  Future<void> _cacheRoster(String eventKey, List<Team> roster) async {
    final cached = await events.getByKey(eventKey);
    var name = cached?.name;
    if (name == null) {
      try {
        name = await getEventName(eventKey);
      } catch (_) {
        name = eventKey;
      }
    }

    final event = cached ?? Event.create(eventKey: eventKey, name: name);
    event.name = name;
    event.teams = [for (final team in roster) team.teamNumber];
    await events.upsert(event);
  }

  Future<List<Team>> _cachedTeams(String eventKey) async {
    final event = await events.getByKey(eventKey);
    if (event == null) return const [];

    final roster = <Team>[];
    for (final number in event.teams) {
      final team = await teams.getByNumber(number);
      if (team != null) roster.add(team);
    }
    return roster;
  }

  /// Per-event memo of [_priorRatings]. Holds the Future rather than the
  /// result, so the schedule and rankings tabs loading at the same moment share
  /// one fetch instead of each starting their own.
  final Map<String, Future<Map<int, TeamRating>>> _priorCache = {};

  /// The ratings used for match prediction and the picklist, entirely from
  /// TBA (no scouting): TBA's per-team numbers plus a [RatingModel] fit to
  /// [matches]' scored quals.
  ///
  /// Uses [eventKey]'s own ratings once a qual is scored and TBA has OPRs for
  /// it. Until then, falls back to each roster team's most recent completed
  /// event this season (see [_priorRatings]), with
  /// [TeamRating.sourceEventKey] marking every borrowed rating and their OPRs
  /// as the model's priors. Returns [EventRatings.empty] (→ no predictions
  /// shown) only when neither source has data.
  Future<EventRatings> fetchTeamRatings(
    String eventKey,
    List<TbaMatch> matches,
  ) async {
    // TBA serves an OPR of 0 for every team as soon as the qual schedule is
    // posted, so OPRs alone don't mean anything has been played.
    final current = matches.any(RatingModel.isScoredQual)
        ? await _eventRatings(eventKey, matches)
        : const <int, TeamRating>{};
    if (current.isNotEmpty) {
      return EventRatings(teams: current, model: RatingModel.fit(matches));
    }

    final pending = _priorCache[eventKey] ??= _priorRatings(eventKey);
    final Map<int, TeamRating> borrowed;
    try {
      borrowed = await pending;
    } catch (_) {
      // Offline or TBA down — forget the failure so the next load retries.
      _priorCache.remove(eventKey);
      return EventRatings.empty;
    }
    // Usually nothing is scored here yet, so the fit is just the priors: each
    // team's OPR from the event it was borrowed from. If /oprs failed or lags
    // the first results, the quals already scored still pull it from there.
    return EventRatings(
      teams: borrowed,
      model: RatingModel.fit(
        matches,
        priors: {for (final r in borrowed.values) r.team: r.opr},
      ),
    );
  }

  /// Pre-comp ratings for [eventKey]'s roster: each team's rating from its
  /// newest completed event this season that TBA rated it at, tagged with
  /// that event's key.
  ///
  /// Same season only — OPRs from a different year's game are in different
  /// points, so a team with no events yet this season is simply left out
  /// (and treated as event-average by [MatchPrediction.compute]).
  Future<Map<int, TeamRating>> _priorRatings(String eventKey) async {
    final roster = (await tba.get('/event/$eventKey/teams/keys') as List)
        .cast<String>();
    final numbers = [
      for (final k in roster) int.tryParse(TbaMatch.displayNumber(k)),
    ];
    // The season comes from the key ("2027casj"), not the clock, so a January
    // week-0 lookup still reads the right year.
    final year = eventKey.substring(0, 4);
    final now = DateTime.now();

    // 1 — each team's completed events this season, newest first. One team
    //     failing shouldn't sink the rest; all of them failing means we're
    //     offline, which is thrown so the result isn't cached.
    var failures = 0;
    final history = await Future.wait(roster.map((teamKey) async {
      try {
        final data =
            await tba.get('/team/$teamKey/events/$year/simple') as List;
        final done = data
            .cast<Map<String, dynamic>>()
            .where((e) =>
                e['key'] != eventKey &&
                DateTime.parse(e['end_date'] as String).isBefore(now))
            .toList()
          ..sort((a, b) => DateTime.parse(b['end_date'] as String)
              .compareTo(DateTime.parse(a['end_date'] as String)));
        return [for (final e in done) e['key'] as String];
      } catch (_) {
        failures++;
        return const <String>[];
      }
    }));
    if (roster.isNotEmpty && failures == roster.length) {
      throw TbaException('no team history reachable for $eventKey');
    }

    // 2 — rate events in rounds. Each round rates the next-newest untried
    //     event of every team still unrated; teams share events, so each one
    //     is fetched once. Nearly every team is rated at its latest event, so
    //     this usually finishes in a single round.
    final rated = <String, Map<int, TeamRating>>{};
    final cursor = List.filled(roster.length, 0);
    final out = <int, TeamRating>{};
    while (true) {
      final wanted = <String>{};
      for (var i = 0; i < roster.length; i++) {
        final n = numbers[i];
        if (n == null || out.containsKey(n)) continue;
        while (cursor[i] < history[i].length) {
          final key = history[i][cursor[i]];
          final r = rated[key]?[n];
          if (r != null) {
            out[n] = r.withSource(key);
            break;
          }
          if (rated.containsKey(key)) {
            cursor[i]++; // rated already, but without this team — go older
            continue;
          }
          wanted.add(key);
          break;
        }
      }
      if (wanted.isEmpty) return out;

      await Future.wait(wanted.map((key) async {
        try {
          rated[key] = await _eventRatings(key, await getMatches(key));
        } catch (_) {
          rated[key] = const {};
        }
      }));
    }
  }

  /// One event's ratings, built from TBA alone. Combines:
  ///   - `/oprs`      → OPR / DPR / CCWM
  ///   - `/rankings`  → rank, avg ranking points, W-L-T record
  ///   - [matches]    → each team's real alliance-score mean + std (already
  ///                    loaded for the schedule, so no extra calls)
  ///
  /// Returns an empty map if TBA has no OPRs yet, e.g. before the event's
  /// first matches are played.
  Future<Map<int, TeamRating>> _eventRatings(
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

    // 3 — per-team samples from played matches. Two of them: the raw alliance
    //     score (its mean ± std is only displayed; predictions take σ from
    //     RatingModel) and the implied contribution (robust, per-robot — see
    //     [TeamRating]).
    final meanOpr = oprs.isEmpty
        ? 0.0
        : oprs.values.map((v) => (v as num).toDouble()).reduce((a, b) => a + b) /
            oprs.length;
    double oprOf(String teamKey) =>
        (oprs[teamKey] as num?)?.toDouble() ?? meanOpr;

    final samples = <int, List<double>>{};
    final contribs = <int, List<double>>{};
    void collect(List<String> keys, int? score) {
      if (score == null) return;
      for (final k in keys) {
        final n = int.tryParse(TbaMatch.displayNumber(k));
        if (n == null) continue;
        (samples[n] ??= []).add(score.toDouble());
        // Strip out what the partners were expected to score; the remainder is
        // this robot's apparent output. Unrated partners fall back to the event
        // mean, so a team TBA hasn't rated never produces a wild value.
        var partners = 0.0;
        for (final other in keys) {
          if (other != k) partners += oprOf(other);
        }
        (contribs[n] ??= []).add(score.toDouble() - partners);
      }
    }

    for (final m in matches) {
      if (!m.isPlayed) continue;
      collect(m.redTeams, m.redScore);
      collect(m.blueTeams, m.blueScore);
    }

    // 4 — per-team contribution median/std, then the event's own noise floor.
    //     The floor has to be event-wide, so it's computed before the merge.
    final contribStats = <int, ({double? median, double? std})>{};
    for (final e in contribs.entries) {
      contribStats[e.key] =
          (median: _median(e.value), std: _meanStd(e.value).std);
    }
    final allStds =
        contribStats.values.map((s) => s.std).whereType<double>().toList();
    final eventStd = allStds.isEmpty ? 0.0 : _median(allStds);

    // 5 — merge into one rating per TBA-rated team.
    final out = <int, TeamRating>{};
    for (final entry in oprs.entries) {
      final n = int.tryParse(TbaMatch.displayNumber(entry.key));
      if (n == null) continue;
      final xs = samples[n] ?? const <double>[];
      final stats = _meanStd(xs);
      final contrib = contribStats[n];
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
        contribMedian: contrib?.median,
        contribStd: contrib?.std,
        lowMatchCount: _lowCount(
            contribs[n] ?? const <double>[], contrib?.median, eventStd),
      );
    }
    return out;
  }

  /// How many typical swings a robot has to lose before the match counts as
  /// "it wasn't working".
  static const double _lowSwings = 2.0;

  /// Matches where a robot's output collapsed: more than [_lowSwings] × the
  /// *event's* median contribution std below its own median.
  ///
  /// The yardstick is deliberately event-wide rather than per-team. Scaling by
  /// a team's own sigma fails twice over: that sigma is inflated by the very
  /// matches being hunted, and it ranges 48-133 points across a field for
  /// reasons (partner-OPR estimation error) that have nothing to do with
  /// reliability, so identical collapses register differently team to team.
  ///
  /// Sizing, from 2026 NorCal DCMP: median contribution std 75.4, so the
  /// threshold is a 151-point drop. 1678 (median 228) flags exactly its two
  /// dead matches at 71 and 73 and leaves the next one up at 137 alone, while
  /// a team whose median is below 151 can never flag — correctly, since it has
  /// no room to fall that far.
  int? _lowCount(List<double> xs, double? median, double eventStd) {
    if (xs.length < 2 || median == null || eventStd <= 1e-9) return null;
    final floor = median - _lowSwings * eventStd;
    return xs.where((x) => x < floor).length;
  }

  /// Median of a non-empty [xs].
  double _median(List<double> xs) {
    final sorted = [...xs]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
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
  ///
  /// Nexus only supplements TBA with queue status, so any failure here
  /// (network, unexpected JSON shape) degrades to no status chips rather than
  /// failing the whole schedule load.
  Future<List<NexusMatch>> getNexusMatches(String eventKey) async {
    try {
      final event = await nexus.getEvent(eventKey);
      if (event == null) return [];
      final raw = event['matches'] as List? ?? [];
      return raw
          .cast<Map<String, dynamic>>()
          .map(NexusMatch.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
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

  /// Returns the drawn venue pit map for [eventKey], or null if volunteers
  /// haven't drawn one (Nexus sends "No map.") or it can't be fetched.
  Future<NexusPitMap?> getPitMap(String eventKey) async {
    try {
      return NexusPitMap.parse(await nexus.getRaw('/event/$eventKey/map'));
    } catch (_) {
      return null;
    }
  }
}
