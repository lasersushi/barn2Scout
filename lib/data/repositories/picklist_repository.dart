import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/picklist.dart';

/// Persists alliance picklists to a JSON file in the app support directory.
///
/// Mirrors [SettingsRepository]: call [init] once at startup to load saved
/// lists into memory, after which reads are synchronous and [persist] flushes
/// the whole file. There is always at least one list, and [activeId] always
/// refers to an existing one.
class PicklistRepository {
  PicklistRepository({this.directoryOverride});

  /// Test seam: when set, the JSON file lives here instead of the app support
  /// directory, so tests can run without mocking path_provider.
  final String? directoryOverride;

  static const _fileName = 'picklists.json';

  List<Picklist> _lists = [];
  String _activeId = '';

  /// All saved lists, in creation order.
  List<Picklist> get lists => List.unmodifiable(_lists);

  /// Id of the currently selected list.
  String get activeId => _activeId;

  /// Load saved lists from disk. Safe on first launch (no file yet): seeds a
  /// single "Main" list so the picklist UI always has something to show.
  Future<void> init() async {
    final file = await _file();
    if (await file.exists()) {
      try {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _lists = (data['lists'] as List? ?? [])
            .map((e) => Picklist.fromJson(e as Map<String, dynamic>))
            .toList();
        _activeId = data['activeId'] as String? ?? '';
      } catch (_) {
        _lists = []; // corrupt file — start fresh
        _activeId = '';
      }
    }

    if (_lists.isEmpty) {
      _lists = [Picklist(id: 'main', name: 'Main')];
    }
    if (!_lists.any((l) => l.id == _activeId)) {
      _activeId = _lists.first.id;
    }
  }

  /// Replace the saved lists and active selection, flushing to disk.
  Future<void> persist(List<Picklist> lists, String activeId) async {
    _lists = List.of(lists);
    _activeId = activeId;
    await (await _file()).writeAsString(jsonEncode({
      'activeId': _activeId,
      'lists': _lists.map((l) => l.toJson()).toList(),
    }));
  }

  Future<File> _file() async {
    final dir = directoryOverride ?? (await getApplicationSupportDirectory()).path;
    return File('$dir/$_fileName');
  }
}
