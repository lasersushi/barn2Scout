import 'package:isar_community/isar.dart';

part 'event.g.dart';

/// A competition event, identified by its TBA key (e.g. `"2027casvr"`).
@collection
class Event {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String eventKey;

  late String name;

  /// Team numbers attending this event.
  late List<int> teams;

  Event();

  Event.create({
    required this.eventKey,
    required this.name,
    this.teams = const [],
  });
}
