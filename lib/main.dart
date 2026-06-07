import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/match_repository.dart';
import 'data/repositories/scouting_repository.dart';
import 'data/repositories/team_repository.dart';
import 'data/services/isar_service.dart';

Future<void> main() async {
  // Required before using plugins (path_provider) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Isar is the source of truth on device — open it before the UI starts so
  // every repository has a live database to talk to.
  final isarService = await IsarService.open();
  final isar = isarService.isar;

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: isarService),
        RepositoryProvider(create: (_) => ScoutingRepository(isar)),
        RepositoryProvider(create: (_) => TeamRepository(isar)),
        RepositoryProvider(create: (_) => MatchRepository(isar)),
        RepositoryProvider(create: (_) => EventRepository(isar)),
      ],
      child: const Barn2ScoutApp(),
    ),
  );
}
