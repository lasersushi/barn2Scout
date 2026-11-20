import 'package:barn2scout/data/models/ai_models.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/repositories/ai_repository.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/features/ai/cubit/ai_access_cubit.dart';
import 'package:barn2scout/features/ai/cubit/ai_chat_cubit.dart';
import 'package:barn2scout/features/ai/view/ai_page.dart';
import 'package:barn2scout/features/schedule/cubit/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_ai_repository.dart';

class _FakeScheduleRepository implements ScheduleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

const _match = TbaMatch(
  key: '2026cacac_qm12',
  compLevel: 'qm',
  setNumber: 1,
  matchNumber: 12,
  redTeams: ['frc751', 'frc254', 'frc1678'],
  blueTeams: ['frc971', 'frc973', 'frc604'],
);

Future<FakeAiRepository> _pump(WidgetTester tester, AiAccess access) async {
  final repo = FakeAiRepository(
    access: access,
    summaryEvents: const [AiDelta('Reliable climber.'), AiDone(remainingToday: 19)],
  );
  final schedule = ScheduleCubit(_FakeScheduleRepository())
    // ignore: invalid_use_of_protected_member
    ..emit(const ScheduleLoaded(
      eventKey: '2026cacac',
      eventName: 'Test Regional',
      eventStatus: EventStatus.active,
      allMatches: [_match],
      nexusMatches: [],
      pastEventKey: '2026cacac',
      pastEventName: 'Test Regional',
      pastAllMatches: [_match],
    ));
  final accessCubit = AiAccessCubit(repo);
  await accessCubit.load();

  await tester.pumpWidget(
    RepositoryProvider<AiRepository>.value(
      value: repo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: schedule),
          BlocProvider.value(value: accessCubit),
          BlocProvider(create: (_) => AiChatCubit(repo)),
        ],
        child: const MaterialApp(home: AiPage()),
      ),
    ),
  );
  await tester.pump();
  return repo;
}

void main() {
  testWidgets('scouters get the team list only; summary waits for the button',
      (tester) async {
    final repo = await _pump(
      tester,
      const AiAccess(
        kinds: {AiKind.teamSummary},
        unlimited: false,
        isAdmin: false,
        dailyLimit: 20,
        remainingToday: 20,
      ),
    );

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(find.text('Team 254'), findsOneWidget);
    expect(find.text('Team 751 (us)'), findsOneWidget);

    await tester.tap(find.text('Team 254'));
    await tester.pumpAndSettle();
    expect(find.text('Generate summary'), findsOneWidget);
    expect(find.textContaining('20 of 20'), findsOneWidget);
    expect(repo.summaryCalls, isEmpty, reason: 'opening the sheet is free');

    await tester.tap(find.text('Generate summary'));
    await tester.pumpAndSettle();
    expect(repo.summaryCalls, [254]);
    expect(find.text('Reliable climber.'), findsOneWidget);
    expect(find.textContaining('Not used in rankings or predictions'),
        findsOneWidget);
  });

  testWidgets('the AI role gets match briefs and chat', (tester) async {
    await _pump(
      tester,
      const AiAccess(
        kinds: {AiKind.teamSummary, AiKind.matchBrief, AiKind.chat},
        unlimited: true,
        isAdmin: false,
      ),
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Match briefs'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    await tester.tap(find.text('Match briefs'));
    await tester.pumpAndSettle();
    expect(find.text('Qual 12'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Ask anything about this event'), findsOneWidget);
  });
}
