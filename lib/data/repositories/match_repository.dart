import 'package:isar_community/isar.dart';

import '../models/frc_match.dart';

/// Reads and writes the [FrcMatch] schedule, cached from TBA so it works
/// offline after first load.
class MatchRepository {
  MatchRepository(this._isar);

  final Isar _isar;

  IsarCollection<FrcMatch> get _matches => _isar.matches;

  /// Upsert from a TBA sync. The composite unique index (replace: true) means
  /// existing matches are updated in place rather than duplicated.
  Future<void> upsertAll(List<FrcMatch> matches) =>
      _isar.writeTxn(() => _matches.putAll(matches));

  Future<List<FrcMatch>> getForEvent(String eventKey) => _matches
      .filter()
      .eventKeyEqualTo(eventKey)
      .sortByMatchType()
      .thenByMatchNumber()
      .findAll();

  Stream<List<FrcMatch>> watchForEvent(String eventKey) => _matches
      .filter()
      .eventKeyEqualTo(eventKey)
      .sortByMatchType()
      .thenByMatchNumber()
      .watch(fireImmediately: true);
}
