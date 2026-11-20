import 'field_config.dart';
import 'game_config.dart';
import 'pit_config.dart';

/// Every configured field by its stored key, match and pit forms together.
final Map<String, FieldConfig> _fieldsByKey = {
  for (final f in [...kDefaultGameConfig, ...kPitScoutingConfig]) f.key: f,
};

/// The configured field for a stored [key], or null for keys from an older
/// season's config that has since been edited.
FieldConfig? fieldFor(String key) => _fieldsByKey[key];

/// Human label for a stored field [key]: the configured [FieldConfig.label],
/// or the key itself turned into words when no field has it any more.
String fieldLabel(String key) => _fieldsByKey[key]?.label ?? prettyFieldKey(key);

/// `"auto_left_line"` / `"autoLeftLine"` → `"auto left line"`.
String prettyFieldKey(String key) => key
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAll('_', ' ')
    .trim();
