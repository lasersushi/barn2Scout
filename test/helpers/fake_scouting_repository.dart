import 'dart:async';

import 'package:barn2scout/data/models/scouting_record.dart';
import 'package:barn2scout/data/repositories/scouting_repository.dart';

/// In-memory [ScoutingRepository] for tests — no Isar required. Records saves
/// and streams them back. Any unused method throws via [noSuchMethod].
class FakeScoutingRepository implements ScoutingRepository {
  final List<ScoutingRecord> saved = [];
  final StreamController<List<ScoutingRecord>> _controller =
      StreamController<List<ScoutingRecord>>.broadcast();

  @override
  Future<void> save(ScoutingRecord record) async {
    saved.add(record);
    _controller.add(List.unmodifiable(saved));
  }

  @override
  Stream<List<ScoutingRecord>> watchAll() async* {
    yield List.unmodifiable(saved);
    yield* _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
