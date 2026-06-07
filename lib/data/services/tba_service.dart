import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Thin HTTP wrapper for The Blue Alliance API v3.
///
/// Every request attaches the auth key header. Throws [TbaException] on
/// non-200 responses so callers can catch and surface a message.
class TbaService {
  TbaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('${AppConfig.tbaBaseUrl}$path');
    final response = await _client.get(
      uri,
      headers: {'X-TBA-Auth-Key': AppConfig.tbaKey},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw TbaException('TBA $path → ${response.statusCode}');
  }
}

class TbaException implements Exception {
  const TbaException(this.message);
  final String message;
  @override
  String toString() => 'TbaException: $message';
}
