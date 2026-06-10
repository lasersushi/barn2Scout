import 'package:barn2scout/core/utils/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDottedVersion', () {
    test('plain version', () {
      expect(parseDottedVersion('26.2.0'), [26, 2, 0]);
    });

    test('strips leading v', () {
      expect(parseDottedVersion('v26.1.3'), [26, 1, 3]);
      expect(parseDottedVersion('V26.1.3'), [26, 1, 3]);
    });

    test('four segments (real tag v26.1.0.2)', () {
      expect(parseDottedVersion('v26.1.0.2'), [26, 1, 0, 2]);
    });

    test('strips -suffix and +build (real tag v26.0.1.0-alpha)', () {
      expect(parseDottedVersion('v26.0.1.0-alpha'), [26, 0, 1, 0]);
      expect(parseDottedVersion('26.2.0+4'), [26, 2, 0]);
    });

    test('garbage returns null', () {
      expect(parseDottedVersion(''), isNull);
      expect(parseDottedVersion('v'), isNull);
      expect(parseDottedVersion('latest'), isNull);
      expect(parseDottedVersion('26.x.0'), isNull);
      expect(parseDottedVersion('26..0'), isNull);
    });
  });

  group('isRemoteNewer', () {
    test('strictly newer', () {
      expect(isRemoteNewer(local: '26.2.0', remote: '26.2.1'), isTrue);
      expect(isRemoteNewer(local: '26.2.0', remote: '26.3.0'), isTrue);
      expect(isRemoteNewer(local: '26.2.0', remote: '27.0.0'), isTrue);
    });

    test('equal is not newer', () {
      expect(isRemoteNewer(local: '26.2.0', remote: '26.2.0'), isFalse);
      expect(isRemoteNewer(local: '26.2.0', remote: 'v26.2.0'), isFalse);
    });

    test('older is not newer (downgrade protection)', () {
      expect(isRemoteNewer(local: '26.2.0', remote: '26.1.3'), isFalse);
      expect(isRemoteNewer(local: '26.2.0', remote: '25.9.9'), isFalse);
    });

    test('old 1.x scheme vs new 26.x scheme', () {
      // A device still on the legacy pubspec scheme must see new releases.
      expect(isRemoteNewer(local: '1.0.2', remote: '26.1.2'), isTrue);
    });

    test('shorter side is zero-padded', () {
      expect(isRemoteNewer(local: '26.1.0', remote: '26.1.0.2'), isTrue);
      expect(isRemoteNewer(local: '26.1.0.2', remote: '26.1.0'), isFalse);
      expect(isRemoteNewer(local: '26.1', remote: '26.1.0'), isFalse);
    });

    test('unparsable on either side is never newer', () {
      expect(isRemoteNewer(local: '26.2.0', remote: 'latest'), isFalse);
      expect(isRemoteNewer(local: '???', remote: '26.2.0'), isFalse);
    });
  });
}
