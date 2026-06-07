part of 'schedule_cubit.dart';

sealed class ScheduleState {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded({
    required this.eventKey,
    required this.eventName,
    required this.eventStatus,
    required this.allMatches,
    required this.nexusMatches,
    required this.pastEventKey,
    required this.pastEventName,
    required this.pastAllMatches,
    this.ratings = const {},
  });

  /// The current / upcoming event — drives the schedule tabs.
  final String eventKey;
  final String eventName;

  /// Where [eventKey] sits relative to today (active / upcoming / past).
  final EventStatus eventStatus;

  // Convenience flags so views don't import EventStatus directly.
  bool get isActiveEvent => eventStatus == EventStatus.active;
  bool get isUpcomingEvent => eventStatus == EventStatus.upcoming;
  bool get isPastEvent => eventStatus == EventStatus.past;

  final List<TbaMatch> allMatches;   // from current event, competition order
  final List<NexusMatch> nexusMatches; // empty when not live in Nexus

  /// TBA-derived team strength for the current event, keyed by team number.
  /// Empty before the event has OPRs — predictions simply don't render.
  final Map<int, TeamRating> ratings;

  /// The most recently completed event — drives the Past Matches tab.
  /// May equal [eventKey] when actively competing.
  final String pastEventKey;
  final String pastEventName;
  final List<TbaMatch> pastAllMatches; // from past event

  // ── Current event getters ────────────────────────────────────────────────

  /// All of Team 751's matches at the current event.
  List<TbaMatch> get myMatches =>
      allMatches.where((m) => m.containsTeam(AppConfig.myTeamKey)).toList();

  /// Upcoming (not yet played) matches for Team 751.
  List<TbaMatch> get myUpcomingMatches =>
      myMatches.where((m) => !m.isPlayed).toList();

  /// All teams' upcoming matches at the current event.
  List<TbaMatch> get upcomingMatches =>
      allMatches.where((m) => !m.isPlayed).toList();

  // ── Past event getters ───────────────────────────────────────────────────

  /// Team 751's played matches from the most recent competition, newest first.
  List<TbaMatch> get myPastMatches => pastAllMatches
      .where((m) => m.isPlayed && m.containsTeam(AppConfig.myTeamKey))
      .toList()
      .reversed
      .toList();

  /// All teams' played matches from the most recent competition, newest first.
  List<TbaMatch> get pastMatches =>
      pastAllMatches.where((m) => m.isPlayed).toList().reversed.toList();

  /// Nexus status for a given match label, or null if not found.
  NexusMatch? nexusFor(String label) {
    try {
      return nexusMatches.firstWhere((n) => n.label == label);
    } catch (_) {
      return null;
    }
  }
}

class ScheduleError extends ScheduleState {
  const ScheduleError(this.message);
  final String message;
}
