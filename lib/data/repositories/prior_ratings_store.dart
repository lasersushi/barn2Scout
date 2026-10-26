import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/team_rating.dart';

/// Saves each event's borrowed pre-comp ratings (see
/// `ScheduleRepository.fetchTeamRatings`) to a JSON file per event in the app
/// support directory, so they survive a restart without the network.
///
/// They're TBA data, never scouting. Reads and writes never throw: a missing,
/// corrupt or unwritable file just means fetching them again.
class PriorRatingsStore {
  PriorRatingsStore({this.directoryOverride});

  /// Test seam: when set, files live here instead of the app support
  /// directory, so tests can run without mocking path_provider.
  final String? directoryOverride;

  /// [eventKey]'s saved ratings, or null if there are none. [complete] says
  /// they were saved once the event had started, so they can't change.
  Future<({Map<int, TeamRating> ratings, bool complete})?> read(
    String eventKey,
  ) async {
    try {
      final file = await _file(eventKey);
      if (!await file.exists()) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final ratings = [
        for (final r in data['ratings'] as List)
          TeamRating.fromJson(r as Map<String, dynamic>),
      ];
      return (
        ratings: {for (final r in ratings) r.team: r},
        complete: data['complete'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String eventKey,
    Map<int, TeamRating> ratings, {
    required bool complete,
  }) async {
    try {
      final file = await _file(eventKey);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'complete': complete,
          'ratings': [for (final r in ratings.values) r.toJson()],
        }),
      );
    } catch (_) {
      // Not saved: the next load fetches them again.
    }
  }

  Future<File> _file(String eventKey) async {
    final dir =
        directoryOverride ?? (await getApplicationSupportDirectory()).path;
    return File('$dir/prior_ratings/$eventKey.json');
  }
}
