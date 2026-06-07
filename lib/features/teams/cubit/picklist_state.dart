part of 'picklist_cubit.dart';

/// Where a team sits in the active picklist.
enum PickStatus { available, picked, veto }

class PicklistState {
  const PicklistState({required this.lists, required this.activeId});

  /// Every saved list, in creation order.
  final List<Picklist> lists;

  /// Id of the selected list.
  final String activeId;

  /// The currently selected list (falls back to the first if [activeId] is
  /// somehow stale — the repository guarantees at least one list exists).
  Picklist get active =>
      lists.firstWhere((l) => l.id == activeId, orElse: () => lists.first);

  /// Pick/veto status of [team] within the active list.
  PickStatus statusOf(int team) {
    final a = active;
    if (a.picks.contains(team)) return PickStatus.picked;
    if (a.vetoes.contains(team)) return PickStatus.veto;
    return PickStatus.available;
  }

  /// 1-based priority of a picked team (1 = top pick), or null if not picked.
  int? priorityOf(int team) {
    final i = active.picks.indexOf(team);
    return i < 0 ? null : i + 1;
  }
}
