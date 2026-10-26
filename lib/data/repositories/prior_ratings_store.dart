import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/team_rating.dart';

/// What `ScheduleRepository` borrows for an event's roster from elsewhere:
/// the rating model's priors, and before quals the ratings the Teams tabs
/// show.
class BorrowedPriors {
  const BorrowedPriors({this.ratings = const {}, this.relative = const {}});

  /// Each team's rating at its newest completed event this season, tagged
  /// with [TeamRating.sourceEventKey], keyed by team number.
  final Map<int, TeamRating> ratings;

  /// For teams not in [ratings]: how many standard deviations above an
  /// average robot each was last season (see `RatingModel.fit`'s
  /// `relativePriors`), keyed by team number.
  final Map<int, double> relative;
}

/// Saves each event's [BorrowedPriors] (see
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

  /// [eventKey]'s saved priors, or null if there are none. [complete] says
  /// they were saved once the event had started, so they can't change.
  Future<({BorrowedPriors priors, bool complete})?> read(
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
      final relative = data['relative'] as Map<String, dynamic>?;
      return (
        priors: BorrowedPriors(
          ratings: {for (final r in ratings) r.team: r},
          relative: {
            for (final MapEntry(:key, :value) in (relative ?? const {}).entries)
              int.parse(key): (value as num).toDouble(),
          },
        ),
        // Saved before last season's standings were: never final.
        complete: relative != null && (data['complete'] as bool? ?? false),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String eventKey,
    BorrowedPriors priors, {
    required bool complete,
  }) async {
    try {
      final file = await _file(eventKey);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'complete': complete,
          'ratings': [for (final r in priors.ratings.values) r.toJson()],
          'relative': {
            for (final MapEntry(:key, :value) in priors.relative.entries)
              '$key': value,
          },
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
