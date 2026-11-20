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

  /// The "AI role": unlimited AI generations plus chat and match briefs.
  /// Admins have the same without it. Granted in the Manager tab.
  bool aiAccess = false;

  @ignore
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  ScoutProfile();

  ScoutProfile.create({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    this.aiAccess = false,
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
      aiAccess: row['ai_access'] as bool? ?? false,
    );
  }
}
