import '../../core/config/app_config.dart';
import '../models/nexus_match.dart';
import '../models/nexus_pit.dart';
import '../models/tba_match.dart';
import '../services/nexus_service.dart';
import '../services/tba_service.dart';

/// Combines TBA (full schedule + results) with Nexus (live queue status).
///
/// TBA is the authority on match data. Nexus supplements with real-time status
/// only when Team 751's event is currently active in Nexus.
class ScheduleRepository {
  ScheduleRepository({required this.tba, required this.nexus});

  final TbaService tba;
  final NexusService nexus;

  /// Cached result so both schedule and teams cubits don't each make a call.
  String? _cachedEventKey;

  /// The resolved event key if already detected, otherwise the config fallback.
  /// Safe to read synchronously after the schedule has loaded at least once.
  String get resolvedEventKey => _cachedEventKey ?? AppConfig.currentEventKey;

  /// Finds Team 751's current event automatically from TBA:
  ///   1. Active today (start ≤ now ≤ end+1d)
  ///   2. Most recently completed
  ///   3. Next upcoming
  ///   4. Falls back to AppConfig.currentEventKey if TBA has nothing
  Future<String> detectCurrentEvent() async {
    if (_cachedEventKey != null) return _cachedEventKey!;

    final year = DateTime.now().year;
    final data = await tba.get(
      '/team/${AppConfig.myTeamKey}/events/$year/simple',
    ) as List;
    final events = data.cast<Map<String, dynamic>>();
    final now = DateTime.now();

    // 1 — currently active
    for (final e in events) {
      final start = DateTime.parse(e['start_date'] as String);
      final end = DateTime.parse(e['end_date'] as String)
          .add(const Duration(days: 1));
      if (now.isAfter(start) && now.isBefore(end)) {
        return _cachedEventKey = e['key'] as String;
      }
    }

    // 2 — most recently completed
    final past = events
        .where((e) => DateTime.parse(e['end_date'] as String).isBefore(now))
        .toList()
      ..sort((a, b) => DateTime.parse(b['end_date'] as String)
          .compareTo(DateTime.parse(a['end_date'] as String)));
    if (past.isNotEmpty) return _cachedEventKey = past.first['key'] as String;

    // 3 — next upcoming
    final future = events
        .where((e) => DateTime.parse(e['start_date'] as String).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(a['start_date'] as String)
          .compareTo(DateTime.parse(b['start_date'] as String)));
    if (future.isNotEmpty) {
      return _cachedEventKey = future.first['key'] as String;
    }

    // 4 — hardcoded fallback
    return _cachedEventKey = AppConfig.currentEventKey;
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
