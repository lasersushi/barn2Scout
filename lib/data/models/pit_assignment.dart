import 'package:isar_community/isar.dart';

part 'pit_assignment.g.dart';

@collection
class PitAssignment {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('teamNumber')], unique: true, replace: true)
  late String eventKey;

  late int teamNumber;

  @Index()
  late String userId;

  late DateTime updatedAt;

  PitAssignment();

  PitAssignment.create({
    required this.eventKey,
    required this.teamNumber,
    required this.userId,
    required this.updatedAt,
  });

  factory PitAssignment.fromSupabase(Map<String, dynamic> row) =>
      PitAssignment.create(
        eventKey: row['event_key'] as String,
        teamNumber: row['team_number'] as int,
        userId: row['user_id'] as String,
        updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
