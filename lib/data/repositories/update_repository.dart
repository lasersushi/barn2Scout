import 'dart:async';

import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../../core/utils/app_version.dart';
import '../models/app_release.dart';
import '../services/github_release_service.dart';

/// Steps reported while downloading and installing a full-APK update.
///
/// These are the repository's own types — ota_update's OtaEvent never
/// escapes this file, so cubits and UI stay plugin-free.
sealed class InstallStep {
  const InstallStep();
}

class InstallDownloading extends InstallStep {
  const InstallDownloading(this.percent);
  final int percent;
}

/// The system install prompt has been launched; this is the terminal step.
/// Android owns the flow from here — if the user confirms, this process is
/// killed and replaced by the new version.
class InstallLaunched extends InstallStep {
  const InstallLaunched();
}

class InstallFailed extends InstallStep {
  const InstallFailed(this.reason);
  final String reason;
}

typedef StartOta = Stream<OtaEvent> Function(
  String url, {
  String? destinationFilename,
  String? sha256checksum,
});

/// Checks GitHub for newer full releases and reads what's installed
/// (including the Shorebird patch number). All three plugin dependencies
/// are injectable so tests can run without platform channels.
class UpdateRepository {
  UpdateRepository({
    GithubReleaseService? service,
    Future<PackageInfo> Function()? loadPackageInfo,
    Future<int?> Function()? readPatchNumber,
    StartOta? startOta,
  })  : _service = service ?? GithubReleaseService(),
        _loadPackageInfo = loadPackageInfo ?? PackageInfo.fromPlatform,
        _readPatchNumber = readPatchNumber ?? _readShorebirdPatch,
        _startOta = startOta ?? _defaultStartOta;

  final GithubReleaseService _service;
  final Future<PackageInfo> Function() _loadPackageInfo;
  final Future<int?> Function() _readPatchNumber;
  final StartOta _startOta;

  InstalledVersion? _cached;

  Future<InstalledVersion> getInstalledVersion() async {
    if (_cached != null) return _cached!;
    final info = await _loadPackageInfo();
    final patch = await _readPatchNumber();
    return _cached = InstalledVersion(
      version: info.version,
      buildNumber: info.buildNumber,
      patchNumber: patch,
    );
  }

  /// The newest published release, or null when there is nothing to offer:
  /// already up to date (or remote is older — downgrade protection), no
  /// .apk asset, or an unparsable tag. Network and API errors propagate;
  /// the cubit decides whether to stay silent.
  Future<AppRelease?> checkForUpdate() async {
    final installed = await getInstalledVersion();
    final release = AppRelease.tryFromJson(await _service.getLatestRelease());
    if (release == null) return null;
    if (!isRemoteNewer(local: installed.version, remote: release.version)) {
      return null;
    }
    return release;
  }

  /// Downloads the APK and fires the system installer. The stream ends
  /// after a terminal step ([InstallLaunched] or [InstallFailed]).
  Stream<InstallStep> downloadAndInstall(AppRelease release) async* {
    Stream<OtaEvent> events;
    try {
      // Fixed filename so repeated downloads overwrite rather than pile up
      // 75 MB files in app storage.
      events = _startOta(
        release.apkUrl,
        destinationFilename: 'barn2scout-update.apk',
        sha256checksum: release.sha256,
      );
    } catch (e) {
      yield InstallFailed('$e');
      return;
    }
    await for (final event in events) {
      final step = mapOtaEvent(event.status, event.value);
      if (step == null) continue;
      yield step;
      if (step is! InstallDownloading) return;
    }
  }

  /// Visible for testing: pure mapping from plugin events to [InstallStep].
  static InstallStep? mapOtaEvent(OtaStatus status, String? value) {
    switch (status) {
      case OtaStatus.DOWNLOADING:
        return InstallDownloading(int.tryParse(value ?? '') ?? 0);
      case OtaStatus.INSTALLING:
      case OtaStatus.INSTALLATION_DONE:
        return const InstallLaunched();
      case OtaStatus.ALREADY_RUNNING_ERROR:
        return const InstallFailed('A download is already running.');
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        return const InstallFailed(
          'Install permission was denied — allow "Install unknown apps" '
          'for Barn2Scout in your device Settings.',
        );
      case OtaStatus.INSTALLATION_ERROR:
        return InstallFailed(value ?? 'Installation failed.');
      case OtaStatus.DOWNLOAD_ERROR:
        return InstallFailed(
          value == null ? 'Download failed.' : 'Download failed: $value',
        );
      case OtaStatus.CHECKSUM_ERROR:
        return const InstallFailed('The downloaded file failed verification.');
      case OtaStatus.INTERNAL_ERROR:
        return InstallFailed(value ?? 'Unknown error.');
      case OtaStatus.CANCELED:
        return const InstallFailed('Download canceled.');
    }
  }

  static Future<int?> _readShorebirdPatch() async {
    try {
      final updater = ShorebirdUpdater();
      // False in debug builds and plain `flutter build` artifacts.
      if (!updater.isAvailable) return null;
      return (await updater.readCurrentPatch())?.number;
    } catch (_) {
      // ReadPatchException etc. — treat as "no patch".
      return null;
    }
  }

  static Stream<OtaEvent> _defaultStartOta(
    String url, {
    String? destinationFilename,
    String? sha256checksum,
  }) {
    return OtaUpdate().execute(
      url,
      destinationFilename: destinationFilename,
      sha256checksum: sha256checksum,
    );
  }
}
