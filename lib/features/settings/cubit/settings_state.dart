part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.scouterName = '',
    this.themeMode = ThemeMode.system,
    this.eventKeyOverride,
    this.showPastMatchesTab = false,
    this.logoutMinutes = 180,
  });

  final String scouterName;
  final ThemeMode themeMode;
  final String? eventKeyOverride; // null = auto-detect from TBA
  final bool showPastMatchesTab;
  final int logoutMinutes; // minutes of backgrounded inactivity before auto sign-out

  SettingsState copyWith({
    String? scouterName,
    ThemeMode? themeMode,
    String? eventKeyOverride,
    bool clearEventOverride = false,
    bool? showPastMatchesTab,
    int? logoutMinutes,
  }) {
    return SettingsState(
      scouterName: scouterName ?? this.scouterName,
      themeMode: themeMode ?? this.themeMode,
      eventKeyOverride:
          clearEventOverride ? null : (eventKeyOverride ?? this.eventKeyOverride),
      showPastMatchesTab: showPastMatchesTab ?? this.showPastMatchesTab,
      logoutMinutes: logoutMinutes ?? this.logoutMinutes,
    );
  }

  @override
  List<Object?> get props => [
        scouterName,
        themeMode,
        eventKeyOverride,
        showPastMatchesTab,
        logoutMinutes,
      ];
}
