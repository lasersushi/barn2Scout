import 'package:isar_community/isar.dart';

part 'scout_profile.g.dart';

@collection
class ScoutProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String email;

  late String displayName;

  late String role;

  @ignore
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  ScoutProfile();

  ScoutProfile.create({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory ScoutProfile.fromSupabase(Map<String, dynamic> row) {
    final email = row['email'] as String? ?? '';
    final name = (row['display_name'] as String?)?.trim();
    return ScoutProfile.create(
      userId: row['id'] as String,
      email: email,
      displayName:
          (name == null || name.isEmpty) ? email.split('@').first : name,
      role: row['role'] as String? ?? 'scout',
    );
  }
}
