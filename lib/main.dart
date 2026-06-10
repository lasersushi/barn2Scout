import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/match_repository.dart';
import 'data/repositories/picklist_repository.dart';
import 'data/repositories/pit_scouting_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/scouting_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'data/repositories/team_repository.dart';
import 'data/repositories/update_repository.dart';
import 'data/services/isar_service.dart';
import 'data/services/nexus_service.dart';
import 'data/services/tba_service.dart';
import 'features/settings/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Load settings before runApp so the correct themeMode is available
  // on the very first frame — prevents a light→dark flash.
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  // Load saved picklists before runApp so PicklistCubit's initial state is ready.
  final picklistRepo = PicklistRepository();
  await picklistRepo.init();

  final isarService = await IsarService.open();
  final isar = isarService.isar;

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: isarService),
        RepositoryProvider.value(value: settingsRepo),
        RepositoryProvider.value(value: picklistRepo),
        RepositoryProvider(create: (_) => ScoutingRepository(isar)),
        RepositoryProvider(create: (_) => PitScoutingRepository(isar)),
        RepositoryProvider(
          create: (ctx) => SyncRepository(
            ctx.read<ScoutingRepository>(),
            ctx.read<PicklistRepository>(),
            ctx.read<PitScoutingRepository>(),
          ),
        ),
        RepositoryProvider(create: (_) => TeamRepository(isar)),
        RepositoryProvider(create: (_) => MatchRepository(isar)),
        RepositoryProvider(create: (_) => EventRepository(isar)),
        RepositoryProvider(create: (_) => UpdateRepository()),
        RepositoryProvider(
          create: (ctx) => ScheduleRepository(
            tba: TbaService(),
            nexus: NexusService(),
            settings: ctx.read<SettingsRepository>(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (ctx) => SettingsCubit(ctx.read<SettingsRepository>()),
        child: const Barn2ScoutApp(),
      ),
    ),
  );
}
