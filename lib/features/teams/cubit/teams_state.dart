part of 'teams_cubit.dart';

sealed class TeamsState {
  const TeamsState();
}

class TeamsInitial extends TeamsState {
  const TeamsInitial();
}

class TeamsLoading extends TeamsState {
  const TeamsLoading();
}

class TeamsLoaded extends TeamsState {
  const TeamsLoaded({required this.pits, required this.eventKey});

  final List<NexusPit> pits; // empty = volunteers haven't configured yet
  final String eventKey;

  /// Pits grouped by row letter: {"A": [pit, pit, ...], "B": [...], ...}
  Map<String, List<NexusPit>> get byRow {
    final map = <String, List<NexusPit>>{};
    for (final pit in pits) {
      (map[pit.row] ??= []).add(pit);
    }
    return map;
  }
}

class TeamsError extends TeamsState {
  const TeamsError(this.message);
  final String message;
}
