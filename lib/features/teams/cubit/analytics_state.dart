part of 'analytics_cubit.dart';

sealed class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsEmpty extends AnalyticsState {
  const AnalyticsEmpty();
}

class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded({required this.teams});

  /// Teams sorted by composite score descending.
  final List<TeamAnalytics> teams;
}
