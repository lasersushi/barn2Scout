import 'package:isar_community/isar.dart';

import '../models/event.dart';

/// Reads and writes [Event]s (competitions).
class EventRepository {
  EventRepository(this._isar);

  final Isar _isar;

  IsarCollection<Event> get _events => _isar.events;

  Future<void> upsert(Event event) => _isar.writeTxn(() => _events.put(event));

  Future<Event?> getByKey(String eventKey) =>
      _events.filter().eventKeyEqualTo(eventKey).findFirst();

  Future<List<Event>> getAll() => _events.where().findAll();
}
