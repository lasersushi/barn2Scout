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
    required this.allMatches,
    required this.nexusMatches,
  });

  final String eventKey;
  final String eventName;
  final List<TbaMatch> allMatches; // sorted in competition order
  final List<NexusMatch> nexusMatches; // empty when event isn't live in Nexus

  /// Team 751's matches only.
  List<TbaMatch> get myMatches => allMatches
      .where((m) => m.containsTeam(AppConfig.myTeamKey))
      .toList();

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
