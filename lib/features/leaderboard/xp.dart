import '../../data/models/pit_scouting_record.dart';
import '../../data/models/scout_profile.dart';
import '../../data/models/scouting_record.dart';
import '../scouting/config/field_config.dart';
import '../scouting/config/game_config.dart';
import '../scouting/config/pit_config.dart';

/// XP rules for the scouter leaderboard.
///
/// XP measures scouting *effort* — how many reports a scouter filed — never
/// anything about the scouted team, so it stays clear of the rankings rule.
const kMatchReportXp = 10;
const kPitReportXp = 15;

/// Bonus for a report whose written text totals at least
/// [kNotesBonusMinChars] characters.
const kNotesBonusXp = 5;
const kNotesBonusMinChars = 20;

const kXpPerLevel = 100;

int levelFor(int xp) => xp ~/ kXpPerLevel + 1;

/// Fraction (0–1) of the way from the current level to the next.
double levelProgress(int xp) => (xp % kXpPerLevel) / kXpPerLevel;

int xpForMatchRecord(ScoutingRecord record) {
  final data = {
    ...record.autoData,
    ...record.teleopData,
    ...record.endgameData,
  };
  return kMatchReportXp +
      _notesBonus(record.notes, data, kDefaultGameConfig);
}

int xpForPitRecord(PitScoutingRecord record) =>
    kPitReportXp + _notesBonus(record.notes, record.pitData, kPitScoutingConfig);

/// Written text is [notes] plus every [FieldType.text] field in [config], so
/// the bonus follows the season's config rather than hard-coded keys.
int _notesBonus(
  String notes,
  Map<String, dynamic> data,
  List<FieldConfig> config,
) {
  var length = notes.trim().length;
  for (final field in config.where((f) => f.type == FieldType.text)) {
    final value = data[field.key];
    if (value is String) length += value.trim().length;
  }
  return length >= kNotesBonusMinChars ? kNotesBonusXp : 0;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.xp,
    required this.matchCount,
    required this.pitCount,
    required this.rank,
    required this.isMe,
  });

  final String userId;
  final String name;
  final int xp;
  final int matchCount;
  final int pitCount;

  /// 1-based; tied XP shares a rank (1, 2, 2, 4).
  final int rank;
  final bool isMe;

  int get level => levelFor(xp);
  double get progress => levelProgress(xp);
}

/// Totals XP per scouter account.
///
/// A synced record belongs to its [ScoutingRecord.userId]. An unsynced record
/// belongs to [currentUserId], since that's the id the next push stamps on it.
/// Synced records with no userId yet are skipped until a pull backfills them.
List<LeaderboardEntry> buildLeaderboard({
  required List<ScoutingRecord> matchRecords,
  required List<PitScoutingRecord> pitRecords,
  required List<ScoutProfile> profiles,
  required String? currentUserId,
}) {
  final totals = <String, _Tally>{};

  _Tally? tallyFor(bool synced, String? userId) {
    final owner = synced ? userId : currentUserId;
    if (owner == null) return null;
    return totals.putIfAbsent(owner, _Tally.new);
  }

  for (final r in matchRecords) {
    final tally = tallyFor(r.synced, r.userId);
    if (tally == null) continue;
    tally
      ..xp += xpForMatchRecord(r)
      ..matchCount += 1
      ..noteName(r.scouterName, r.timestamp);
  }
  for (final r in pitRecords) {
    final tally = tallyFor(r.synced, r.userId);
    if (tally == null) continue;
    tally
      ..xp += xpForPitRecord(r)
      ..pitCount += 1
      ..noteName(r.scouterName, r.timestamp);
  }

  final names = {for (final p in profiles) p.userId: p.displayName};
  final rows = [
    for (final MapEntry(key: userId, value: t) in totals.entries)
      (userId: userId, name: names[userId] ?? t.latestName ?? 'Scout', t: t),
  ]..sort((a, b) {
      final byXp = b.t.xp.compareTo(a.t.xp);
      return byXp != 0
          ? byXp
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  final entries = <LeaderboardEntry>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final tied = i > 0 && rows[i - 1].t.xp == row.t.xp;
    entries.add(LeaderboardEntry(
      userId: row.userId,
      name: row.name,
      xp: row.t.xp,
      matchCount: row.t.matchCount,
      pitCount: row.t.pitCount,
      rank: tied ? entries[i - 1].rank : i + 1,
      isMe: row.userId == currentUserId,
    ));
  }
  return entries;
}

class _Tally {
  int xp = 0;
  int matchCount = 0;
  int pitCount = 0;
  String? latestName;
  DateTime? _latestAt;

  /// Remembers the most recent non-empty scouter name — the display-name
  /// fallback when the profiles table has no row for this account.
  void noteName(String name, DateTime at) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_latestAt == null || at.isAfter(_latestAt!)) {
      latestName = trimmed;
      _latestAt = at;
    }
  }
}
