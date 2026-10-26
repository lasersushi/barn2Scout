import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/points_cubit.dart';
import 'points_view.dart';

/// Every match still open for bets — the Points view only lists the next few.
class OpenMatchesPage extends StatelessWidget {
  const OpenMatchesPage({super.key});

  /// Reuses the caller's [PointsCubit], so bets placed here show up there.
  static Future<void> push(BuildContext context) {
    final cubit = context.read<PointsCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const OpenMatchesPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open matches')),
      body: BlocBuilder<PointsCubit, PointsState>(
        builder: (context, state) {
          if (state is! PointsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final open = state.openMatches;
          if (open.isEmpty) {
            return const Center(child: Text('No open matches.'));
          }
          return RefreshIndicator(
            onRefresh: () => context.read<PointsCubit>().refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: open.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => BetMatchTile(match: open[i], state: state),
            ),
          );
        },
      ),
    );
  }
}
