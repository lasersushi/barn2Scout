import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barn2scout/app.dart';
import 'package:barn2scout/data/repositories/scouting_repository.dart';

import 'helpers/fake_scouting_repository.dart';

void main() {
  testWidgets('Boots into the home shell with a nav bar', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ScoutingRepository>.value(
        value: FakeScoutingRepository(),
        child: const Barn2ScoutApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
