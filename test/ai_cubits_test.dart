import 'dart:async';

import 'package:barn2scout/data/models/ai_models.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/services/ai_service.dart';
import 'package:barn2scout/features/ai/cubit/ai_access_cubit.dart';
import 'package:barn2scout/features/ai/cubit/ai_chat_cubit.dart';
import 'package:barn2scout/features/ai/cubit/ai_generate_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_ai_repository.dart';

void main() {
  group('AiGenerateCubit', () {
    test('requests nothing until generate()', () async {
      var calls = 0;
      final cubit = AiGenerateCubit(() {
        calls++;
        return const Stream.empty();
      });
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
      expect(cubit.state.status, AiGenerateStatus.idle);
      await cubit.close();
    });

    test('streams text, then done with cached flag and remaining', () async {
      int? reported;
      final cubit = AiGenerateCubit(
        () => Stream.fromIterable(const [
          AiDelta('Strong '),
          AiDelta('climber.'),
          AiDone(cached: true, remainingToday: 7),
        ]),
        onRemaining: (r) => reported = r,
      );
      final seen = <AiGenerateState>[];
      final sub = cubit.stream.listen(seen.add);
      await cubit.generate();
      await pumpEventQueue();

      expect(seen.first.status, AiGenerateStatus.streaming);
      expect(seen.map((s) => s.text), contains('Strong '));
      expect(cubit.state.status, AiGenerateStatus.done);
      expect(cubit.state.text, 'Strong climber.');
      expect(cubit.state.cached, isTrue);
      expect(cubit.state.remainingToday, 7);
      expect(reported, 7);
      await sub.cancel();
      await cubit.close();
    });

    for (final code in [
      AiErrorCode.dailyLimit,
      AiErrorCode.budgetReached,
      AiErrorCode.offline,
      AiErrorCode.refused,
    ]) {
      test('fails with $code', () async {
        int? reported;
        final cubit = AiGenerateCubit(
          () => Stream.value(AiFailure(code, 'nope')),
          onRemaining: (r) => reported = r,
        );
        await cubit.generate();
        await pumpEventQueue();
        expect(cubit.state.status, AiGenerateStatus.failed);
        expect(cubit.state.errorCode, code);
        expect(cubit.state.errorMessage, 'nope');
        expect(reported, code == AiErrorCode.dailyLimit ? 0 : null);
        await cubit.close();
      });
    }

    test('a stream that ends without done is a dropped connection', () async {
      final cubit = AiGenerateCubit(() => Stream.value(const AiDelta('half')));
      await cubit.generate();
      await pumpEventQueue();
      expect(cubit.state.status, AiGenerateStatus.failed);
      expect(cubit.state.errorCode, AiErrorCode.offline);
      expect(cubit.state.text, 'half');
      await cubit.close();
    });
  });

  group('AiAccessCubit', () {
    const scout = AiAccess(
      kinds: {AiKind.teamSummary},
      unlimited: false,
      isAdmin: false,
      dailyLimit: 20,
      remainingToday: 20,
    );

    test('scouters only see team summaries', () async {
      final cubit = AiAccessCubit(FakeAiRepository(access: scout));
      await cubit.load();
      final s = cubit.state as AiAccessReady;
      expect(s.access.can(AiKind.teamSummary), isTrue);
      expect(s.access.can(AiKind.chat), isFalse);
      expect(s.access.can(AiKind.matchBrief), isFalse);
      cubit.updateRemaining(19);
      expect((cubit.state as AiAccessReady).access.remainingToday, 19);
      await cubit.close();
    });

    test('AI role sees chat and briefs; remaining stays null', () async {
      final cubit = AiAccessCubit(FakeAiRepository(
        access: AiAccess.fromJson(const {
          'kinds': ['team_summary', 'match_brief', 'chat', 'unknown_kind'],
          'unlimited': true,
          'isAdmin': false,
          'dailyLimit': null,
          'remainingToday': null,
        }),
      ));
      await cubit.load();
      final a = (cubit.state as AiAccessReady).access;
      expect(a.kinds, {AiKind.teamSummary, AiKind.matchBrief, AiKind.chat});
      cubit.updateRemaining(3);
      expect((cubit.state as AiAccessReady).access.remainingToday, isNull);
      await cubit.close();
    });

    test('offline shows a failure', () async {
      final cubit = AiAccessCubit(FakeAiRepository(
        accessError: const AiServiceException(AiErrorCode.offline, 'offline'),
      ));
      await cubit.load();
      expect(cubit.state, const AiAccessFailed(AiErrorCode.offline, 'offline'));
      await cubit.close();
    });
  });

  group('AiChatCubit', () {
    Future<void> ask(AiChatCubit cubit, String q) async {
      await cubit.send(q,
          eventKey: '2026cacac',
          ratings: EventRatings.empty,
          matches: const []);
      await pumpEventQueue();
    }

    test('alternates turns and builds the event data once', () async {
      final repo = FakeAiRepository(chatReplies: [
        const [AiDelta('Team 254.'), AiDone()],
        const [AiDelta('Yes.'), AiDone()],
      ]);
      final cubit = AiChatCubit(repo);

      await ask(cubit, 'Best defender?');
      await ask(cubit, 'Sure?');

      expect(cubit.state.turns, const [
        AiTurn.user('Best defender?'),
        AiTurn.assistant('Team 254.'),
        AiTurn.user('Sure?'),
        AiTurn.assistant('Yes.'),
      ]);
      expect(repo.chatContextBuilds, 1);
      expect(repo.chatHistories.last, hasLength(3));
      expect(repo.chatHistories.last.last, const AiTurn.user('Sure?'));
      expect(cubit.state.omittedReports, 3);
      expect(cubit.state.sending, isFalse);
      await cubit.close();
    });

    test('a failed question is removed from history and handed back', () async {
      final repo = FakeAiRepository(chatReplies: [
        const [AiFailure(AiErrorCode.forbidden, 'No chat for you')],
      ]);
      final cubit = AiChatCubit(repo);
      await ask(cubit, 'Hello?');
      expect(cubit.state.turns, isEmpty);
      expect(cubit.state.unsentQuestion, 'Hello?');
      expect(cubit.state.errorCode, AiErrorCode.forbidden);
      expect(cubit.state.sending, isFalse);
      await cubit.close();
    });

    test('clear starts over with fresh data', () async {
      final repo = FakeAiRepository(chatReplies: [
        const [AiDelta('A'), AiDone()],
        const [AiDelta('B'), AiDone()],
      ]);
      final cubit = AiChatCubit(repo);
      await ask(cubit, 'one');
      await cubit.clear();
      expect(cubit.state.turns, isEmpty);
      await ask(cubit, 'two');
      expect(repo.chatContextBuilds, 2);
      expect(repo.chatHistories.last, const [AiTurn.user('two')]);
      await cubit.close();
    });

    test('long conversations send the newest turns, user first', () async {
      final replies = [
        for (var i = 0; i < 25; i++) [AiDelta('a$i'), const AiDone()],
      ];
      final repo = FakeAiRepository(chatReplies: replies);
      final cubit = AiChatCubit(repo);
      for (var i = 0; i < 25; i++) {
        await ask(cubit, 'q$i');
      }
      final sent = repo.chatHistories.last;
      expect(sent.length, AiChatCubit.maxTurnsSent);
      expect(sent.first.fromUser, isTrue);
      expect(sent.last, const AiTurn.user('q24'));
      await cubit.close();
    });
  });
}
