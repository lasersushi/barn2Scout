part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.scouterName = '',
    this.themeMode = ThemeMode.system,
    this.eventKeyOverride,
    this.showPastMatchesTab = false,
  });

  final String scouterName;
  final ThemeMode themeMode;
  final String? eventKeyOverride; // null = auto-detect from TBA
  final bool showPastMatchesTab;

  SettingsState copyWith({
    String? scouterName,
    ThemeMode? themeMode,
    String? eventKeyOverride,
    bool clearEventOverride = false,
    bool? showPastMatchesTab,
  }) {
    return SettingsState(
      scouterName: scouterName ?? this.scouterName,
      themeMode: themeMode ?? this.themeMode,
      eventKeyOverride:
          clearEventOverride ? null : (eventKeyOverride ?? this.eventKeyOverride),
      showPastMatchesTab: showPastMatchesTab ?? this.showPastMatchesTab,
    );
  }

  @override
  List<Object?> get props =>
      [scouterName, themeMode, eventKeyOverride, showPastMatchesTab];
}
