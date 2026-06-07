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
