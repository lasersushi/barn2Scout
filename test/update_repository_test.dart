import 'dart:convert';

import 'package:barn2scout/data/models/app_release.dart';
import 'package:barn2scout/data/repositories/update_repository.dart';
import 'package:barn2scout/data/services/github_release_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A GitHub /releases/latest response with the parts the repository reads.
Map<String, dynamic> releaseJson({
  String tag = 'v26.3.0',
  String body = 'Fixes the flux capacitor\nMore details below.',
  List<Map<String, dynamic>>? assets,
}) {
  return {
    'tag_name': tag,
    'body': body,
    'assets': assets ??
        [
          {
            'name': 'barn2scout-$tag.apk',
            'browser_download_url': 'https://example.com/$tag/app.apk',
            'digest': 'sha256:abc123',
          },
        ],
  };
}

UpdateRepository buildRepo({
  Map<String, dynamic>? latest,
  int statusCode = 200,
  String localVersion = '26.2.0',
  int? patchNumber,
}) {
  final client = MockClient((request) async {
    return http.Response(
      jsonEncode(latest ?? releaseJson()),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });
  return UpdateRepository(
    service: GithubReleaseService(client: client),
    loadPackageInfo: () async => PackageInfo(
      appName: 'Barn2Scout',
      packageName: 'org.frc751.barn2scout',
      version: localVersion,
      buildNumber: '4',
    ),
    readPatchNumber: () async => patchNumber,
  );
}

void main() {
  group('getInstalledVersion', () {
    test('combines package info and patch number', () async {
      final repo = buildRepo(patchNumber: 3);
      final installed = await repo.getInstalledVersion();
      expect(installed.version, '26.2.0');
      expect(installed.buildNumber, '4');
      expect(installed.patchNumber, 3);
    });

    test('patch number is null for unpatched builds', () async {
      final installed = await buildRepo().getInstalledVersion();
      expect(installed.patchNumber, isNull);
    });
  });

  group('checkForUpdate', () {
    test('returns the release when remote is newer', () async {
      final release = await buildRepo().checkForUpdate();
      expect(release, isNotNull);
      expect(release!.tagName, 'v26.3.0');
      expect(release.version, '26.3.0');
      expect(release.apkUrl, 'https://example.com/v26.3.0/app.apk');
      expect(release.sha256, 'abc123');
      expect(release.notes, startsWith('Fixes the flux capacitor'));
    });

    test('returns null when remote equals local', () async {
      final release =
          await buildRepo(latest: releaseJson(tag: 'v26.2.0')).checkForUpdate();
      expect(release, isNull);
    });

    test('returns null when remote is older (downgrade protection)', () async {
      final release =
          await buildRepo(latest: releaseJson(tag: 'v26.1.3')).checkForUpdate();
      expect(release, isNull);
    });

    test('returns null when the release has no apk asset', () async {
      final release = await buildRepo(
        latest: releaseJson(
          assets: [
            {
              'name': 'source.zip',
              'browser_download_url': 'https://example.com/source.zip',
            },
          ],
        ),
      ).checkForUpdate();
      expect(release, isNull);
    });

    test('returns null when the tag is unparsable', () async {
      final release = await buildRepo(latest: releaseJson(tag: 'latest'))
          .checkForUpdate();
      expect(release, isNull);
    });

    test('throws GithubReleaseException on non-200', () async {
      expect(
        buildRepo(statusCode: 403).checkForUpdate(),
        throwsA(isA<GithubReleaseException>()),
      );
    });
  });

  group('mapOtaEvent', () {
    test('downloading carries the percent', () {
      final step = UpdateRepository.mapOtaEvent(OtaStatus.DOWNLOADING, '42');
      expect(step, isA<InstallDownloading>());
      expect((step as InstallDownloading).percent, 42);
    });

    test('downloading with bad value defaults to 0', () {
      final step = UpdateRepository.mapOtaEvent(OtaStatus.DOWNLOADING, null);
      expect((step as InstallDownloading).percent, 0);
    });

    test('installing and done both map to launched', () {
      expect(UpdateRepository.mapOtaEvent(OtaStatus.INSTALLING, null),
          isA<InstallLaunched>());
      expect(UpdateRepository.mapOtaEvent(OtaStatus.INSTALLATION_DONE, null),
          isA<InstallLaunched>());
    });

    test('every error status maps to a failure with a reason', () {
      const errorStatuses = [
        OtaStatus.ALREADY_RUNNING_ERROR,
        OtaStatus.INSTALLATION_ERROR,
        OtaStatus.PERMISSION_NOT_GRANTED_ERROR,
        OtaStatus.INTERNAL_ERROR,
        OtaStatus.DOWNLOAD_ERROR,
        OtaStatus.CHECKSUM_ERROR,
        OtaStatus.CANCELED,
      ];
      for (final status in errorStatuses) {
        final step = UpdateRepository.mapOtaEvent(status, 'boom');
        expect(step, isA<InstallFailed>(), reason: '$status');
        expect((step as InstallFailed).reason, isNotEmpty, reason: '$status');
      }
    });
  });

  group('downloadAndInstall', () {
    final release = AppRelease.tryFromJson(releaseJson())!;

    test('maps events and ends after the terminal step', () async {
      final repo = UpdateRepository(
        startOta: (url, {destinationFilename, sha256checksum}) {
          expect(url, release.apkUrl);
          expect(destinationFilename, 'barn2scout-update.apk');
          expect(sha256checksum, 'abc123');
          return Stream.fromIterable([
            OtaEvent(OtaStatus.DOWNLOADING, '10'),
            OtaEvent(OtaStatus.DOWNLOADING, '90'),
            OtaEvent(OtaStatus.INSTALLING, null),
            // Anything after the terminal step must be ignored.
            OtaEvent(OtaStatus.INTERNAL_ERROR, 'late event'),
          ]);
        },
      );

      final steps = await repo.downloadAndInstall(release).toList();
      expect(steps, hasLength(3));
      expect((steps[0] as InstallDownloading).percent, 10);
      expect((steps[1] as InstallDownloading).percent, 90);
      expect(steps[2], isA<InstallLaunched>());
    });

    test('a synchronous plugin throw becomes InstallFailed', () async {
      final repo = UpdateRepository(
        startOta: (url, {destinationFilename, sha256checksum}) =>
            throw OtaUpdateException('bad input'),
      );

      final steps = await repo.downloadAndInstall(release).toList();
      expect(steps, hasLength(1));
      expect(steps.single, isA<InstallFailed>());
    });
  });
}
