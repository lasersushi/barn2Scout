part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.scouterName = '',
    this.themeMode = ThemeMode.system,
    this.eventKeyOverride,
    this.showPastMatchesTab = false,
    this.logoutTime = 180,
  }) : assert(
         logoutTime >= 60 && logoutTime <= 300,
         'logoutTime must be between 60 and 300 minutes',
       );

  final String scouterName;
  final ThemeMode themeMode;
  final String? eventKeyOverride; // null = auto-detect from TBA
  final bool showPastMatchesTab;
  final int logoutTime;

  SettingsState copyWith({
    String? scouterName,
    ThemeMode? themeMode,
    String? eventKeyOverride,
    bool clearEventOverride = false,
    bool? showPastMatchesTab,
    int? logoutTime,
  }) {
    return SettingsState(
      scouterName: scouterName ?? this.scouterName,
      themeMode: themeMode ?? this.themeMode,
      eventKeyOverride: clearEventOverride
          ? null
          : (eventKeyOverride ?? this.eventKeyOverride),
      showPastMatchesTab: showPastMatchesTab ?? this.showPastMatchesTab,
      logoutTime: logoutTime ?? this.logoutTime,
    );
  }

  @override
  List<Object?> get props => [
    scouterName,
    themeMode,
    eventKeyOverride,
    showPastMatchesTab,
    logoutTime,
  ];
}
