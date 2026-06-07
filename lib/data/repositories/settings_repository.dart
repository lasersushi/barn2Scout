import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Persists user preferences to a JSON file in the app's support directory.
///
/// Call [init] once at startup (before runApp) to load saved values into
/// memory. All subsequent reads are synchronous. Writes flush the full file.
class SettingsRepository {
  static const _fileName = 'settings.json';

  Map<String, dynamic> _data = {};

  /// Load saved settings from disk. Safe to call even if the file doesn't
  /// exist yet (first launch).
  Future<void> init() async {
    final file = await _file();
    if (await file.exists()) {
      try {
        _data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        _data = {}; // corrupt file — start fresh
      }
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  String get scouterName => _data['scouterName'] as String? ?? '';

  ThemeMode get themeMode => switch (_data['themeMode'] as String?) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// null = auto-detect from TBA.
  String? get eventKeyOverride => _data['eventKeyOverride'] as String?;

  // ── Writes ────────────────────────────────────────────────────────────────

  Future<void> setScouterName(String name) =>
      _save({'scouterName': name.trim()});

  Future<void> setThemeMode(ThemeMode mode) =>
      _save({'themeMode': mode.name});

  Future<void> setEventOverride(String key) =>
      _save({'eventKeyOverride': key.trim()});

  Future<void> clearEventOverride() async {
    _data.remove('eventKeyOverride');
    await (await _file()).writeAsString(jsonEncode(_data));
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _save(Map<String, dynamic> updates) async {
    _data.addAll(updates);
    await (await _file()).writeAsString(jsonEncode(_data));
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }
}
