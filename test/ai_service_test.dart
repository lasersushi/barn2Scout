import 'dart:convert';

import 'package:barn2scout/data/models/ai_models.dart';
import 'package:barn2scout/data/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AiService _service(http.Client client) =>
    AiService(client: client, accessToken: () => 'token');

void main() {
  test('parses NDJSON events', () {
    expect(AiService.parseEvent('{"type":"delta","text":"Hi"}'),
        const AiDelta('Hi'));
    expect(
      AiService.parseEvent(
          '{"type":"done","cached":true,"remainingToday":4}'),
      const AiDone(cached: true, remainingToday: 4),
    );
    expect(
      AiService.parseEvent(
          '{"type":"error","code":"budget_reached","message":"Out"}'),
      const AiFailure(AiErrorCode.budgetReached, 'Out'),
    );
    expect(AiService.parseEvent('not json'), isNull);
    expect(AiService.parseEvent('{"type":"mystery"}'), isNull);
  });

  test('generate sends the request and streams events', () async {
    late Map<String, dynamic> sent;
    late Map<String, String> headers;
    final client = MockClient.streaming((request, body) async {
      headers = request.headers;
      sent = jsonDecode(await body.bytesToString()) as Map<String, dynamic>;
      return http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode('{"type":"delta","text":"Go "}\n{"type":"del'),
          utf8.encode('ta","text":"defense"}\n\n{"type":"done","cached":false}\n'),
        ]),
        200,
      );
    });

    final events = await _service(client)
        .generate(
          kind: AiKind.chat,
          eventKey: '2026cacac',
          payload: const {'teams': []},
          messages: const [AiTurn.user('Plan?')],
        )
        .toList();

    expect(events, const [AiDelta('Go '), AiDelta('defense'), AiDone()]);
    expect(headers['Authorization'], 'Bearer token');
    expect(sent['action'], 'generate');
    expect(sent['kind'], 'chat');
    expect(sent['messages'], [
      {'role': 'user', 'text': 'Plan?'},
    ]);
  });

  test('non-chat requests carry no messages', () async {
    late Map<String, dynamic> sent;
    final client = MockClient.streaming((request, body) async {
      sent = jsonDecode(await body.bytesToString()) as Map<String, dynamic>;
      return http.StreamedResponse(
          Stream.value(utf8.encode('{"type":"done"}\n')), 200);
    });
    await _service(client)
        .generate(
            kind: AiKind.teamSummary,
            eventKey: '2026cacac',
            payload: const {'team': 254})
        .toList();
    expect(sent.containsKey('messages'), isFalse);
  });

  test('HTTP errors become failures with the server code', () async {
    final client = MockClient((_) async => http.Response(
          '{"error":{"code":"daily_limit","message":"Used up"}}',
          429,
        ));
    final events = await _service(client)
        .generate(
            kind: AiKind.teamSummary, eventKey: '2026cacac', payload: const {})
        .toList();
    expect(events, const [AiFailure(AiErrorCode.dailyLimit, 'Used up')]);
  });

  test('a stream cut off before done is reported', () async {
    final client = MockClient.streaming((_, _) async => http.StreamedResponse(
        Stream.value(utf8.encode('{"type":"delta","text":"Half"}\n')), 200));
    final events = await _service(client)
        .generate(
            kind: AiKind.teamSummary, eventKey: '2026cacac', payload: const {})
        .toList();
    expect(events.first, const AiDelta('Half'));
    expect((events.last as AiFailure).code, AiErrorCode.offline);
  });

  test('no connection is offline', () async {
    final client =
        MockClient((_) async => throw http.ClientException('no route'));
    final events = await _service(client)
        .generate(
            kind: AiKind.teamSummary, eventKey: '2026cacac', payload: const {})
        .toList();
    expect((events.single as AiFailure).code, AiErrorCode.offline);

    expect(
      () => _service(client).fetchAccess(),
      throwsA(isA<AiServiceException>()
          .having((e) => e.code, 'code', AiErrorCode.offline)),
    );
  });

  test('fetchAccess parses the access response', () async {
    final client = MockClient((request) async {
      expect(jsonDecode(request.body), {'action': 'access'});
      return http.Response(
        '{"unlimited":false,"isAdmin":false,"kinds":["team_summary"],'
        '"dailyLimit":20,"remainingToday":12}',
        200,
      );
    });
    final access = await _service(client).fetchAccess();
    expect(access.kinds, {AiKind.teamSummary});
    expect(access.remainingToday, 12);
    expect(access.dailyLimit, 20);
  });
}
