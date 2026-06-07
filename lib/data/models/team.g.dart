// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTeamCollection on Isar {
  IsarCollection<Team> get teams => this.collection();
}

const TeamSchema = CollectionSchema(
  name: r'Team',
  id: -3518492973250071660,
  properties: {
    r'capabilitiesJson': PropertySchema(
      id: 0,
      name: r'capabilitiesJson',
      type: IsarType.string,
    ),
    r'nickname': PropertySchema(
      id: 1,
      name: r'nickname',
      type: IsarType.string,
    ),
    r'pitNotes': PropertySchema(
      id: 2,
      name: r'pitNotes',
      type: IsarType.string,
    ),
    r'teamNumber': PropertySchema(
      id: 3,
      name: r'teamNumber',
      type: IsarType.long,
    ),
  },

  estimateSize: _teamEstimateSize,
  serialize: _teamSerialize,
  deserialize: _teamDeserialize,
  deserializeProp: _teamDeserializeProp,
  idName: r'id',
  indexes: {
    r'teamNumber': IndexSchema(
      id: 6426004114963464129,
      name: r'teamNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'teamNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _teamGetId,
  getLinks: _teamGetLinks,
  attach: _teamAttach,
  version: '3.3.2',
);

int _teamEstimateSize(
  Team object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.capabilitiesJson.length * 3;
  bytesCount += 3 + object.nickname.length * 3;
  {
    final value = object.pitNotes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _teamSerialize(
  Team object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.capabilitiesJson);
  writer.writeString(offsets[1], object.nickname);
  writer.writeString(offsets[2], object.pitNotes);
  writer.writeLong(offsets[3], object.teamNumber);
}

Team _teamDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Team();
  object.capabilitiesJson = reader.readString(offsets[0]);
  object.id = id;
  object.nickname = reader.readString(offsets[1]);
  object.pitNotes = reader.readStringOrNull(offsets[2]);
  object.teamNumber = reader.readLong(offsets[3]);
  return object;
}

P _teamDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _teamGetId(Team object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _teamGetLinks(Team object) {
  return [];
}

void _teamAttach(IsarCollection<dynamic> col, Id id, Team object) {
  object.id = id;
}

extension TeamByIndex on IsarCollection<Team> {
  Future<Team?> getByTeamNumber(int teamNumber) {
    return getByIndex(r'teamNumber', [teamNumber]);
  }

  Team? getByTeamNumberSync(int teamNumber) {
    return getByIndexSync(r'teamNumber', [teamNumber]);
  }

  Future<bool> deleteByTeamNumber(int teamNumber) {
    return deleteByIndex(r'teamNumber', [teamNumber]);
  }

  bool deleteByTeamNumberSync(int teamNumber) {
    return deleteByIndexSync(r'teamNumber', [teamNumber]);
  }

  Future<List<Team?>> getAllByTeamNumber(List<int> teamNumberValues) {
    final values = teamNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'teamNumber', values);
  }

  List<Team?> getAllByTeamNumberSync(List<int> teamNumberValues) {
    final values = teamNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'teamNumber', values);
  }

  Future<int> deleteAllByTeamNumber(List<int> teamNumberValues) {
    final values = teamNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'teamNumber', values);
  }

  int deleteAllByTeamNumberSync(List<int> teamNumberValues) {
    final values = teamNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'teamNumber', values);
  }

  Future<Id> putByTeamNumber(Team object) {
    return putByIndex(r'teamNumber', object);
  }

  Id putByTeamNumberSync(Team object, {bool saveLinks = true}) {
    return putByIndexSync(r'teamNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTeamNumber(List<Team> objects) {
    return putAllByIndex(r'teamNumber', objects);
  }

  List<Id> putAllByTeamNumberSync(List<Team> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'teamNumber', objects, saveLinks: saveLinks);
  }
}

extension TeamQueryWhereSort on QueryBuilder<Team, Team, QWhere> {
  QueryBuilder<Team, Team, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Team, Team, QAfterWhere> anyTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'teamNumber'),
      );
    });
  }
}

extension TeamQueryWhere on QueryBuilder<Team, Team, QWhereClause> {
  QueryBuilder<Team, Team, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> teamNumberEqualTo(
    int teamNumber,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'teamNumber', value: [teamNumber]),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> teamNumberNotEqualTo(
    int teamNumber,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'teamNumber',
                lower: [],
                upper: [teamNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'teamNumber',
                lower: [teamNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'teamNumber',
                lower: [teamNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'teamNumber',
                lower: [],
                upper: [teamNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> teamNumberGreaterThan(
    int teamNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'teamNumber',
          lower: [teamNumber],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> teamNumberLessThan(
    int teamNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'teamNumber',
          lower: [],
          upper: [teamNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterWhereClause> teamNumberBetween(
    int lowerTeamNumber,
    int upperTeamNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'teamNumber',
          lower: [lowerTeamNumber],
          includeLower: includeLower,
          upper: [upperTeamNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TeamQueryFilter on QueryBuilder<Team, Team, QFilterCondition> {
  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'capabilitiesJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'capabilitiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'capabilitiesJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'capabilitiesJson', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> capabilitiesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'capabilitiesJson', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nickname',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nickname',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nickname',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nickname', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> nicknameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nickname', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'pitNotes'),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'pitNotes'),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pitNotes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pitNotes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pitNotes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pitNotes', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> pitNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pitNotes', value: ''),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> teamNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'teamNumber', value: value),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> teamNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'teamNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> teamNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'teamNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Team, Team, QAfterFilterCondition> teamNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'teamNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TeamQueryObject on QueryBuilder<Team, Team, QFilterCondition> {}

extension TeamQueryLinks on QueryBuilder<Team, Team, QFilterCondition> {}

extension TeamQuerySortBy on QueryBuilder<Team, Team, QSortBy> {
  QueryBuilder<Team, Team, QAfterSortBy> sortByCapabilitiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capabilitiesJson', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByCapabilitiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capabilitiesJson', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByNickname() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickname', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByNicknameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickname', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByPitNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitNotes', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByPitNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitNotes', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> sortByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }
}

extension TeamQuerySortThenBy on QueryBuilder<Team, Team, QSortThenBy> {
  QueryBuilder<Team, Team, QAfterSortBy> thenByCapabilitiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capabilitiesJson', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByCapabilitiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capabilitiesJson', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByNickname() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickname', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByNicknameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickname', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByPitNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitNotes', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByPitNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitNotes', Sort.desc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<Team, Team, QAfterSortBy> thenByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }
}

extension TeamQueryWhereDistinct on QueryBuilder<Team, Team, QDistinct> {
  QueryBuilder<Team, Team, QDistinct> distinctByCapabilitiesJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'capabilitiesJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Team, Team, QDistinct> distinctByNickname({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nickname', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Team, Team, QDistinct> distinctByPitNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pitNotes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Team, Team, QDistinct> distinctByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teamNumber');
    });
  }
}

extension TeamQueryProperty on QueryBuilder<Team, Team, QQueryProperty> {
  QueryBuilder<Team, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Team, String, QQueryOperations> capabilitiesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'capabilitiesJson');
    });
  }

  QueryBuilder<Team, String, QQueryOperations> nicknameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nickname');
    });
  }

  QueryBuilder<Team, String?, QQueryOperations> pitNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pitNotes');
    });
  }

  QueryBuilder<Team, int, QQueryOperations> teamNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teamNumber');
    });
  }
}
