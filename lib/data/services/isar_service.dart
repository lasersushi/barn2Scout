import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Owns the single Isar instance. Isar is the source of truth on device;
/// TBA caching and Supabase sync both read and write through it.
class IsarService {
  IsarService._(this.isar);

  final Isar isar;

  /// Opens Isar in the app documents directory with every collection schema.
  /// Call once at startup, after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<IsarService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [TeamSchema, FrcMatchSchema, ScoutingRecordSchema, EventSchema],
      directory: dir.path,
      name: 'barn2scout',
    );
    return IsarService._(isar);
  }

  Future<void> close() => isar.close();
}
