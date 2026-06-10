import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/app_release.dart';
import '../../../data/repositories/update_repository.dart';

/// Every state carries the installed-version info so the Settings page can
/// always show "v26.2.0 (4) · patch 1" regardless of update activity.
sealed class UpdateState {
  const UpdateState(this.installed);
  final InstalledVersion? installed; // null until loaded
}

class UpdateInitial extends UpdateState {
  const UpdateInitial() : super(null);
}

/// Nothing to show — also the resting state after a dismissed banner or a
/// silently failed automatic check.
class UpdateIdle extends UpdateState {
  const UpdateIdle(super.installed);
}

/// Only emitted for user-initiated checks (Settings row feedback).
class UpdateChecking extends UpdateState {
  const UpdateChecking(super.installed);
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate(super.installed);
}

class UpdateCheckFailure extends UpdateState {
  const UpdateCheckFailure(super.installed);
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(super.installed, this.release);
  final AppRelease release;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(super.installed, this.release, this.percent);
  final AppRelease release;
  final int percent;
}

/// The system install prompt is up. If the user confirms, Android replaces
/// this process; if they cancel, the banner offers Retry.
class UpdateInstalling extends UpdateState {
  const UpdateInstalling(super.installed, this.release);
  final AppRelease release;
}

class UpdateDownloadFailure extends UpdateState {
  const UpdateDownloadFailure(super.installed, this.release, this.message);
  final AppRelease release;
  final String message;
}

/// Checks for newer full releases once per launch and drives the download /
/// install flow. Dart-only fixes arrive via Shorebird patches without ever
/// touching this cubit — this path exists for releases with native changes.
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._repo, {bool? supported})
      // APK self-update is Android-only; on iOS the cubit stays dormant
      // (the version rows in Settings still work).
      : _supported = supported ?? Platform.isAndroid,
        super(const UpdateInitial());

  final UpdateRepository _repo;
  final bool _supported;

  /// In-memory only: a dismissed version stays hidden until the next app
  /// launch, when the automatic check may offer it again.
  String? _dismissedVersion;
  StreamSubscription<InstallStep>? _installSub;

  Future<void> init() async {
    InstalledVersion? installed;
    try {
      installed = await _repo.getInstalledVersion();
    } catch (_) {
      // Version display degrades gracefully; the check below still runs.
    }
    emit(UpdateIdle(installed));
    if (_supported) await checkForUpdate();
  }

  Future<void> checkForUpdate({bool userInitiated = false}) async {
    if (!_supported) return;
    if (state is UpdateChecking ||
        state is UpdateDownloading ||
        state is UpdateInstalling) {
      return;
    }
    final installed = state.installed;
    if (userInitiated) emit(UpdateChecking(installed));
    try {
      final release = await _repo.checkForUpdate();
      if (release == null) {
        emit(userInitiated
            ? UpdateUpToDate(installed)
            : UpdateIdle(installed));
      } else if (!userInitiated && release.version == _dismissedVersion) {
        emit(UpdateIdle(installed));
      } else {
        // A manual check deliberately bypasses dismissal — explicit user
        // intent re-shows the banner.
        emit(UpdateAvailable(installed, release));
      }
    } catch (_) {
      // Offline-first: automatic checks must never surface errors (venue
      // wifi is unreliable). Manual checks get in-row feedback.
      emit(userInitiated
          ? UpdateCheckFailure(installed)
          : UpdateIdle(installed));
    }
  }

  void startDownload() {
    final current = state;
    final release = switch (current) {
      UpdateAvailable(:final release) => release,
      UpdateDownloadFailure(:final release) => release,
      // Retry path for a cancelled system install prompt.
      UpdateInstalling(:final release) => release,
      _ => null,
    };
    if (release == null || _installSub != null) return;

    emit(UpdateDownloading(current.installed, release, 0));
    _installSub = _repo.downloadAndInstall(release).listen(
      (step) {
        switch (step) {
          case InstallDownloading(:final percent):
            emit(UpdateDownloading(state.installed, release, percent));
          case InstallLaunched():
            emit(UpdateInstalling(state.installed, release));
          case InstallFailed(:final reason):
            emit(UpdateDownloadFailure(state.installed, release, reason));
        }
      },
      onError: (Object e) {
        emit(UpdateDownloadFailure(state.installed, release, '$e'));
        _installSub = null;
      },
      onDone: () => _installSub = null,
    );
  }

  void dismiss() {
    final current = state;
    switch (current) {
      case UpdateAvailable(:final release) ||
            UpdateInstalling(:final release) ||
            UpdateDownloadFailure(:final release):
        _dismissedVersion = release.version;
        emit(UpdateIdle(current.installed));
      case UpdateUpToDate() || UpdateCheckFailure():
        emit(UpdateIdle(current.installed));
      default:
        break;
    }
  }

  @override
  Future<void> close() {
    _installSub?.cancel();
    return super.close();
  }
}
