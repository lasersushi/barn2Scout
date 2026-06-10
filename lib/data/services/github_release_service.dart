import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin HTTP wrapper for the GitHub Releases API.
///
/// Unauthenticated — the repo is public and the 60 req/hr/IP limit is
/// plenty for one check per app launch. `/releases/latest` excludes drafts
/// and prereleases by design, so marking a release "pre-release" on GitHub
/// stages it invisibly. Throws [GithubReleaseException] on non-200.
///
/// Owner/repo live here rather than in AppConfig: AppConfig is gitignored
/// (secrets only) and the repo path is not a secret.
class GithubReleaseService {
  GithubReleaseService({http.Client? client})
      : _client = client ?? http.Client();

  static const _latestUrl =
      'https://api.github.com/repos/lasersushi/barn2Scout/releases/latest';

  final http.Client _client;

  Future<Map<String, dynamic>> getLatestRelease() async {
    final response = await _client.get(
      Uri.parse(_latestUrl),
      headers: {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw GithubReleaseException('releases/latest → ${response.statusCode}');
  }
}

class GithubReleaseException implements Exception {
  const GithubReleaseException(this.message);
  final String message;
  @override
  String toString() => 'GithubReleaseException: $message';
}
