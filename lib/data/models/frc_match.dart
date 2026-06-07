import 'package:isar_community/isar.dart';

part 'frc_match.g.dart';

/// Qualification vs. playoff. Stored by ordinal index (see `@enumerated`).
enum MatchType { qual, playoff }

/// A scheduled match at an event.
///
/// Named `FrcMatch`, not `Match`, because `dart:core` already exports a
/// `Match` type (the result of a RegExp match) and the names would collide.
///
/// Identity is the triple (eventKey, matchType, matchNumber): qual match 1
/// exists at every event, and qual 1 / playoff 1 can share a number, so none
/// of those three alone is unique.
@Collection(accessor: 'matches')
class FrcMatch {
  Id id = Isar.autoIncrement;

  /// First column of the composite unique index. `replace: true` means
  /// re-syncing the schedule from TBA updates rows instead of duplicating.
  @Index(
    composite: [CompositeIndex('matchType'), CompositeIndex('matchNumber')],
    unique: true,
    replace: true,
  )
  late String eventKey;

  @enumerated
  late MatchType matchType;

  late int matchNumber;

  /// The three red team numbers.
  late List<int> redAlliance;

  /// The three blue team numbers.
  late List<int> blueAlliance;

  FrcMatch();

  FrcMatch.create({
    required this.eventKey,
    required this.matchType,
    required this.matchNumber,
    required this.redAlliance,
    required this.blueAlliance,
  });
}
