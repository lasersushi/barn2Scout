/// A published GitHub release of this app, parsed from the
/// `/repos/{owner}/{repo}/releases/latest` response.
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.notes,
    required this.apkUrl,
    this.sha256,
  });

  final String tagName; // 'v26.2.0'
  final String version; // '26.2.0' — tagName minus the leading v
  final String notes; // release body markdown, '' when absent
  final String apkUrl; // browser_download_url of the first .apk asset
  final String? sha256; // asset digest hex, when GitHub provides one

  /// Returns null when the release has no .apk asset (e.g. a source-only
  /// release) — callers treat that as "nothing to offer".
  static AppRelease? tryFromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String?;
    if (tagName == null) return null;

    final assets = (json['assets'] as List?) ?? const [];
    Map<String, dynamic>? apkAsset;
    for (final asset in assets) {
      final map = asset as Map<String, dynamic>;
      if ((map['name'] as String? ?? '').endsWith('.apk')) {
        apkAsset = map;
        break;
      }
    }
    final apkUrl = apkAsset?['browser_download_url'] as String?;
    if (apkUrl == null) return null;

    // GitHub reports asset digests as 'sha256:<hex>'.
    final digest = apkAsset?['digest'] as String?;
    final sha256 = digest != null && digest.startsWith('sha256:')
        ? digest.substring('sha256:'.length)
        : null;

    var version = tagName;
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }

    return AppRelease(
      tagName: tagName,
      version: version,
      notes: json['body'] as String? ?? '',
      apkUrl: apkUrl,
      sha256: sha256,
    );
  }
}

/// What this device is currently running.
class InstalledVersion {
  const InstalledVersion({
    required this.version,
    required this.buildNumber,
    this.patchNumber,
  });

  final String version; // PackageInfo.version, e.g. '26.2.0'
  final String buildNumber; // PackageInfo.buildNumber, e.g. '4'

  /// Shorebird patch number; null when running the unpatched base release
  /// (or a plain non-Shorebird build, e.g. during development).
  final int? patchNumber;
}
