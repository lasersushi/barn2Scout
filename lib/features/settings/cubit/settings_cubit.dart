import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo)
      : super(SettingsState(
          scouterName: _repo.scouterName,
          themeMode: _repo.themeMode,
          eventKeyOverride: _repo.eventKeyOverride,
        ));

  final SettingsRepository _repo;

  Future<void> setScouterName(String name) async {
    await _repo.setScouterName(name);
    emit(state.copyWith(scouterName: name.trim()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setEventOverride(String key) async {
    await _repo.setEventOverride(key);
    emit(state.copyWith(eventKeyOverride: key.trim()));
  }

  Future<void> clearEventOverride() async {
    await _repo.clearEventOverride();
    emit(state.copyWith(clearEventOverride: true));
  }
}
