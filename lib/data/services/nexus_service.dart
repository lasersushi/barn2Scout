import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Thin HTTP wrapper for the FRC Nexus API v1.
///
/// Nexus shows real-time queue status (queuing / on deck / on field) for live
/// events. Returns null-safe results so callers can handle "no live event"
/// gracefully without crashing.
class NexusService {
  NexusService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Public raw fetch — returns decoded JSON (could be a String, List, or Map).
  Future<dynamic> getRaw(String path) => _get(path);

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('${AppConfig.nexusBaseUrl}$path');
    final response = await _client.get(
      uri,
      headers: {'Nexus-Api-Key': AppConfig.nexusKey},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw NexusException('Nexus $path → ${response.statusCode}');
  }

  /// Returns the event object or null if the event isn't active in Nexus.
  Future<Map<String, dynamic>?> getEvent(String eventKey) async {
    try {
      final data = await _get('/event/$eventKey');
      if (data is String) return null; // Nexus returns a string error message
      return data as Map<String, dynamic>;
    } on NexusException {
      return null;
    }
  }

  /// Returns all currently active events keyed by event key.
  Future<Map<String, dynamic>> getActiveEvents() async {
    final data = await _get('/events');
    return data as Map<String, dynamic>;
  }
}

class NexusException implements Exception {
  const NexusException(this.message);
  final String message;
  @override
  String toString() => 'NexusException: $message';
}
