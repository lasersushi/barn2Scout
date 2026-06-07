import 'dart:io';

import 'package:barn2scout/data/models/picklist.dart';
import 'package:barn2scout/data/repositories/picklist_repository.dart';
import 'package:barn2scout/features/teams/cubit/picklist_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('picklist_test');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('PicklistRepository', () {
    test('seeds a default list when nothing is saved', () async {
      final repo = PicklistRepository(directoryOverride: tmp.path);
      await repo.init();
      expect(repo.lists, isNotEmpty);
      expect(repo.activeId, repo.lists.first.id);
    });

    test('persists and reloads lists across instances', () async {
      final repo = PicklistRepository(directoryOverride: tmp.path);
      await repo.init();
      await repo.persist(
        [Picklist(id: 'a', name: 'Main', picks: [254, 1678], vetoes: [118])],
        'a',
      );

      final reloaded = PicklistRepository(directoryOverride: tmp.path);
      await reloaded.init();
      expect(reloaded.lists.length, 1);
      expect(reloaded.lists.first.picks, [254, 1678]);
      expect(reloaded.lists.first.vetoes, [118]);
      expect(reloaded.activeId, 'a');
    });
  });

  group('PicklistCubit', () {
    late PicklistCubit cubit;

    setUp(() async {
      final repo = PicklistRepository(directoryOverride: tmp.path);
      await repo.init();
      cubit = PicklistCubit(repo);
    });

    test('pick → veto → clear moves a team between sets', () async {
      await cubit.pick(254);
      expect(cubit.state.statusOf(254), PickStatus.picked);

      await cubit.veto(254);
      expect(cubit.state.statusOf(254), PickStatus.veto);
      expect(cubit.state.active.picks, isEmpty);

      await cubit.clear(254);
      expect(cubit.state.statusOf(254), PickStatus.available);
    });

    test('reorder uses pre-adjusted (onReorderItem) indices', () async {
      await cubit.pick(1);
      await cubit.pick(2);
      await cubit.pick(3);
      expect(cubit.state.active.picks, [1, 2, 3]);

      await cubit.reorder(2, 0); // drag team 3 to the top
      expect(cubit.state.active.picks, [3, 1, 2]);
      expect(cubit.state.priorityOf(3), 1);
    });

    test('create switches to the new list; delete falls back', () async {
      final firstId = cubit.state.activeId;
      await cubit.createList('Backup');
      expect(cubit.state.lists.length, 2);
      expect(cubit.state.active.name, 'Backup');

      await cubit.deleteList(cubit.state.activeId);
      expect(cubit.state.lists.length, 1);
      expect(cubit.state.activeId, firstId);
    });

    test('deleting the last list keeps one and never goes empty', () async {
      await cubit.deleteList(cubit.state.activeId);
      expect(cubit.state.lists.length, 1);
    });
  });
}
