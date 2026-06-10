import 'package:barn2scout/data/models/app_release.dart';
import 'package:barn2scout/data/repositories/update_repository.dart';
import 'package:barn2scout/features/update/cubit/update_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_update_repository.dart';

const newer = AppRelease(
  tagName: 'v26.3.0',
  version: '26.3.0',
  notes: 'New stuff',
  apkUrl: 'https://example.com/app.apk',
);

void main() {
  late FakeUpdateRepository repo;

  setUp(() => repo = FakeUpdateRepository());

  UpdateCubit buildCubit() => UpdateCubit(repo, supported: true);

  group('init', () {
    test('loads installed version then offers a newer release', () async {
      repo.release = newer;
      final cubit = buildCubit();
      await cubit.init();

      final state = cubit.state;
      expect(state, isA<UpdateAvailable>());
      expect(state.installed?.version, '26.2.0');
      expect((state as UpdateAvailable).release.tagName, 'v26.3.0');
      await cubit.close();
    });

    test('stays idle when up to date', () async {
      final cubit = buildCubit();
      await cubit.init();
      expect(cubit.state, isA<UpdateIdle>());
      expect(cubit.state.installed?.version, '26.2.0');
      await cubit.close();
    });

    test('automatic check failure is silent (offline-first)', () async {
      repo.checkError = Exception('no wifi at the venue');
      final cubit = buildCubit();
      await cubit.init();
      expect(cubit.state, isA<UpdateIdle>());
      await cubit.close();
    });

    test('does nothing on unsupported platforms', () async {
      repo.release = newer;
      final cubit = UpdateCubit(repo, supported: false);
      await cubit.init();
      expect(cubit.state, isA<UpdateIdle>());
      expect(repo.checkCalls, 0);
      await cubit.close();
    });
  });

  group('manual check', () {
    test('emits Checking then UpToDate', () async {
      final cubit = buildCubit();
      await cubit.init();

      final states = <UpdateState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.checkForUpdate(userInitiated: true);
      await pumpEventQueue();
      await sub.cancel();

      expect(states.first, isA<UpdateChecking>());
      expect(states.last, isA<UpdateUpToDate>());
      await cubit.close();
    });

    test('emits CheckFailure when offline', () async {
      final cubit = buildCubit();
      await cubit.init();

      repo.checkError = Exception('offline');
      await cubit.checkForUpdate(userInitiated: true);
      expect(cubit.state, isA<UpdateCheckFailure>());
      await cubit.close();
    });
  });

  group('dismiss', () {
    test('hides the release until the next launch', () async {
      repo.release = newer;
      final cubit = buildCubit();
      await cubit.init();
      expect(cubit.state, isA<UpdateAvailable>());

      cubit.dismiss();
      expect(cubit.state, isA<UpdateIdle>());

      // The next automatic check stays quiet about the same version…
      await cubit.checkForUpdate();
      expect(cubit.state, isA<UpdateIdle>());

      // …but an explicit manual check re-offers it.
      await cubit.checkForUpdate(userInitiated: true);
      expect(cubit.state, isA<UpdateAvailable>());
      await cubit.close();
    });
  });

  group('download', () {
    test('happy path: progress then the system installer', () async {
      repo.release = newer;
      repo.installSteps = const [
        InstallDownloading(10),
        InstallDownloading(80),
        InstallLaunched(),
      ];
      final cubit = buildCubit();
      await cubit.init();

      final states = <UpdateState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.startDownload();
      await pumpEventQueue();
      await sub.cancel();

      expect(states[0], isA<UpdateDownloading>());
      expect((states[0] as UpdateDownloading).percent, 0);
      expect((states[1] as UpdateDownloading).percent, 10);
      expect((states[2] as UpdateDownloading).percent, 80);
      expect(states[3], isA<UpdateInstalling>());
      await cubit.close();
    });

    test('mid-download failure surfaces with a retry-able state', () async {
      repo.release = newer;
      repo.installSteps = const [
        InstallDownloading(30),
        InstallFailed('Download failed: connection reset'),
      ];
      final cubit = buildCubit();
      await cubit.init();

      cubit.startDownload();
      await pumpEventQueue();

      expect(cubit.state, isA<UpdateDownloadFailure>());
      final failure = cubit.state as UpdateDownloadFailure;
      expect(failure.message, contains('connection reset'));
      expect(failure.release.tagName, 'v26.3.0');

      // Retry restarts the download from the failure state.
      repo.installSteps = const [InstallLaunched()];
      cubit.startDownload();
      await pumpEventQueue();
      expect(cubit.state, isA<UpdateInstalling>());
      await cubit.close();
    });

    test('re-entrant startDownload is ignored', () async {
      repo.release = newer;
      repo.installSteps = const [InstallDownloading(10)];
      final cubit = buildCubit();
      await cubit.init();

      final states = <UpdateState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.startDownload();
      cubit.startDownload(); // second call must be a no-op
      await pumpEventQueue();
      await sub.cancel();

      expect(states.whereType<UpdateDownloading>().where((s) => s.percent == 0),
          hasLength(1));
      await cubit.close();
    });

    test('startDownload without a release is a no-op', () async {
      final cubit = buildCubit();
      await cubit.init();
      cubit.startDownload();
      expect(cubit.state, isA<UpdateIdle>());
      await cubit.close();
    });
  });
}
