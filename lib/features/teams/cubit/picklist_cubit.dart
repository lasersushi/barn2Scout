import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/picklist.dart';
import '../../../data/repositories/picklist_repository.dart';

part 'picklist_state.dart';

/// Owns the alliance picklists — pick/veto/reorder on the active list, plus
/// create/rename/delete/select across lists. Every mutation emits a fresh
/// state (so Bloc rebuilds) and flushes to [PicklistRepository].
///
/// The repository is loaded at startup, so the initial state is read straight
/// from it synchronously.
class PicklistCubit extends Cubit<PicklistState> {
  PicklistCubit(this._repo)
      : super(PicklistState(lists: _repo.lists, activeId: _repo.activeId));

  final PicklistRepository _repo;
  final Uuid _uuid = const Uuid();

  /// Emit the new state synchronously (UI updates instantly), then flush to
  /// disk. The returned future is for callers who want to await the write
  /// (tests); the UI fires-and-forgets it.
  Future<void> _commit(List<Picklist> lists, String activeId) async {
    emit(PicklistState(lists: lists, activeId: activeId));
    await _repo.persist(lists, activeId);
  }

  /// Return a copy of [lists] with the active list transformed by [f].
  List<Picklist> _mapActive(Picklist Function(Picklist) f) => [
        for (final l in state.lists) l.id == state.activeId ? f(l) : l,
      ];

  // ── Pick / veto on the active list ─────────────────────────────────────────

  /// Add [team] to picks (appended as lowest priority) and clear any veto.
  Future<void> pick(int team) => _commit(
        _mapActive((l) => l.copyWith(
              picks: [...l.picks.where((t) => t != team), team],
              vetoes: l.vetoes.where((t) => t != team).toList(),
            )),
        state.activeId,
      );

  /// Mark [team] do-not-pick and remove it from picks.
  Future<void> veto(int team) => _commit(
        _mapActive((l) => l.copyWith(
              picks: l.picks.where((t) => t != team).toList(),
              vetoes: [...l.vetoes.where((t) => t != team), team],
            )),
        state.activeId,
      );

  /// Reset [team] to available (remove from both picks and vetoes).
  Future<void> clear(int team) => _commit(
        _mapActive((l) => l.copyWith(
              picks: l.picks.where((t) => t != team).toList(),
              vetoes: l.vetoes.where((t) => t != team).toList(),
            )),
        state.activeId,
      );

  /// Reorder picks. [newIndex] is the already-adjusted target index, matching
  /// ReorderableListView's `onReorderItem` contract.
  Future<void> reorder(int oldIndex, int newIndex) => _commit(
        _mapActive((l) {
          final picks = [...l.picks];
          picks.insert(newIndex, picks.removeAt(oldIndex));
          return l.copyWith(picks: picks);
        }),
        state.activeId,
      );

  // ── List management ────────────────────────────────────────────────────────

  Future<void> createList(String name) {
    final list = Picklist(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
    );
    return _commit([...state.lists, list], list.id); // switch to the new list
  }

  Future<void> renameList(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return _commit(
      [
        for (final l in state.lists)
          l.id == id ? l.copyWith(name: trimmed) : l,
      ],
      state.activeId,
    );
  }

  Future<void> deleteList(String id) {
    final remaining = state.lists.where((l) => l.id != id).toList();
    if (remaining.isEmpty) {
      // Never allow zero lists — replace with a fresh empty "Main".
      final fresh = Picklist(id: _uuid.v4(), name: 'Main');
      return _commit([fresh], fresh.id);
    }
    final activeId =
        id == state.activeId ? remaining.first.id : state.activeId;
    return _commit(remaining, activeId);
  }

  Future<void> selectList(String id) {
    if (state.lists.any((l) => l.id == id)) return _commit(state.lists, id);
    return Future.value();
  }
}
