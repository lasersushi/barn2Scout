import 'package:barn2scout/data/models/app_release.dart';
import 'package:barn2scout/data/repositories/update_repository.dart';

/// Scriptable [UpdateRepository] for tests — no platform channels required.
/// Set the public fields to script behavior; unused members throw via
/// [noSuchMethod].
class FakeUpdateRepository implements UpdateRepository {
  InstalledVersion installed =
      const InstalledVersion(version: '26.2.0', buildNumber: '4');

  /// When non-null, [checkForUpdate] throws this instead of returning.
  Object? checkError;

  /// What [checkForUpdate] returns (null = up to date).
  AppRelease? release;

  /// Steps replayed by [downloadAndInstall].
  List<InstallStep> installSteps = const [];

  int checkCalls = 0;

  @override
  Future<InstalledVersion> getInstalledVersion() async => installed;

  @override
  Future<AppRelease?> checkForUpdate() async {
    checkCalls++;
    final error = checkError;
    if (error != null) throw error;
    return release;
  }

  @override
  Stream<InstallStep> downloadAndInstall(AppRelease release) =>
      Stream.fromIterable(installSteps);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
