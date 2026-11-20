import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/ai_models.dart';

/// HTTP client for the `ai` Supabase Edge Function
/// (`supabase/functions/ai/index.ts`). Streams answers as NDJSON so text
/// appears as it's written.
///
/// Uses `http` directly rather than `functions.invoke`, which buffers the
/// whole response before returning.
class AiService {
  AiService({http.Client? client, String? Function()? accessToken})
      : _http = client ?? http.Client(),
        _accessToken = accessToken ?? _supabaseToken;

  final http.Client _http;
  final String? Function() _accessToken;

  static String? _supabaseToken() =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  static const _timeout = Duration(seconds: 150);

  Uri get _endpoint => Uri.parse('${AppConfig.supabaseUrl}/functions/v1/ai');

  Map<String, String> _headers() {
    final token = _accessToken();
    return {
      'Content-Type': 'application/json',
      'apikey': AppConfig.supabaseAnonKey,
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// What the signed-in user may do. Throws [AiServiceException].
  Future<AiAccess> fetchAccess() async {
    final http.Response res;
    try {
      res = await _http
          .post(_endpoint,
              headers: _headers(), body: jsonEncode({'action': 'access'}))
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const AiServiceException(AiErrorCode.offline, _offlineMessage);
    } on TimeoutException {
      throw const AiServiceException(AiErrorCode.offline, _offlineMessage);
    } on http.ClientException {
      throw const AiServiceException(AiErrorCode.offline, _offlineMessage);
    }
    if (res.statusCode != 200) throw _errorFrom(res.statusCode, res.body);
    return AiAccess.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Streams one generation. Never throws: failures arrive as [AiFailure].
  Stream<AiEvent> generate({
    required AiKind kind,
    required String eventKey,
    required Map<String, dynamic> payload,
    List<AiTurn> messages = const [],
  }) async* {
    final request = http.Request('POST', _endpoint)
      ..headers.addAll(_headers())
      ..body = jsonEncode({
        'action': 'generate',
        'kind': kind.wire,
        'eventKey': eventKey,
        'payload': payload,
        if (kind == AiKind.chat)
          'messages': [for (final m in messages) m.toJson()],
      });

    final http.StreamedResponse res;
    try {
      res = await _http.send(request).timeout(const Duration(seconds: 30));
    } on SocketException {
      yield const AiFailure(AiErrorCode.offline, _offlineMessage);
      return;
    } on TimeoutException {
      yield const AiFailure(AiErrorCode.offline, _offlineMessage);
      return;
    } on http.ClientException {
      yield const AiFailure(AiErrorCode.offline, _offlineMessage);
      return;
    }

    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      final e = _errorFrom(res.statusCode, body);
      yield AiFailure(e.code, e.message);
      return;
    }

    var finished = false;
    try {
      final lines = res.stream
          .timeout(_timeout)
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final event = parseEvent(line);
        if (event == null) continue;
        yield event;
        if (event is AiDone || event is AiFailure) {
          finished = true;
          return;
        }
      }
    } on TimeoutException {
      yield const AiFailure(
          AiErrorCode.server, 'The AI took too long. Try again.');
      return;
    } on Object {
      yield const AiFailure(AiErrorCode.offline, _offlineMessage);
      return;
    }
    if (!finished) {
      yield const AiFailure(
          AiErrorCode.offline, 'The connection dropped before the answer finished.');
    }
  }

  /// One NDJSON line → event, or null for lines it doesn't understand.
  static AiEvent? parseEvent(String line) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    return switch (decoded['type']) {
      'delta' => AiDelta(decoded['text'] as String? ?? ''),
      'done' => AiDone(
          cached: decoded['cached'] as bool? ?? false,
          truncated: decoded['truncated'] as bool? ?? false,
          remainingToday: decoded['remainingToday'] as int?,
        ),
      'error' => AiFailure(
          AiErrorCode.fromWire(decoded['code'] as String?),
          decoded['message'] as String? ?? 'Something went wrong.',
        ),
      _ => null,
    };
  }

  static AiServiceException _errorFrom(int status, String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error']
          as Map<String, dynamic>;
      return AiServiceException(
        AiErrorCode.fromWire(error['code'] as String?),
        error['message'] as String? ?? 'Something went wrong.',
      );
    } on Object {
      return AiServiceException(
        status == 401 ? AiErrorCode.unauthorized : AiErrorCode.server,
        status == 401
            ? 'Sign in again to use AI.'
            : 'The AI service had a problem (HTTP $status).',
      );
    }
  }

  static const _offlineMessage = 'AI needs an internet connection.';
}

class AiServiceException implements Exception {
  const AiServiceException(this.code, this.message);
  final AiErrorCode code;
  final String message;

  @override
  String toString() => message;
}
