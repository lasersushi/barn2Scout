import '../../core/config/app_config.dart';
import '../models/nexus_match.dart';
import '../models/nexus_pit.dart';
import '../models/tba_match.dart';
import '../services/nexus_service.dart';
import '../services/tba_service.dart';

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
  ScheduleRepository({required this.tba, required this.nexus});

  final TbaService tba;
  final NexusService nexus;

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
