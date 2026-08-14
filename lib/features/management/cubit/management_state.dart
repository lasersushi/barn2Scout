part of 'management_cubit.dart';

sealed class ManagementState {
  const ManagementState();
}

class ManagementLoading extends ManagementState {
  const ManagementLoading();
}

class ManagementNoEvent extends ManagementState {
  const ManagementNoEvent();
}

class ManagementError extends ManagementState {
  const ManagementError(this.message);
  final String message;
}

class ManagementLoaded extends ManagementState {
  const ManagementLoaded({
    required this.eventKey,
    required this.eventName,
    required this.profiles,
    required this.assignments,
    required this.teams,
    required this.scoutedTeams,
  });

  final String eventKey;
  final String eventName;
  final List<ScoutProfile> profiles;
  final List<PitAssignment> assignments;
  final List<Team> teams;
  final Set<int> scoutedTeams;

  Set<int> teamsFor(String userId) => {
    for (final a in assignments)
      if (a.userId == userId) a.teamNumber,
  };

  int assignedCountFor(String userId) => teamsFor(userId).length;

  int doneCountFor(String userId) =>
      teamsFor(userId).where(scoutedTeams.contains).length;

  String? ownerOf(int teamNumber) {
    for (final a in assignments) {
      if (a.teamNumber == teamNumber) return a.userId;
    }
    return null;
  }

  String? displayNameOf(String userId) {
    for (final p in profiles) {
      if (p.userId == userId) return p.displayName;
    }
    return null;
  }

  List<Team> get unassignedTeams => [
    for (final t in teams)
      if (ownerOf(t.teamNumber) == null) t,
  ];

  int get assignedCount => assignments.length;

  bool get hasRoster => teams.isNotEmpty;
}
