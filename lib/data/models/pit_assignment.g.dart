// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pit_assignment.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPitAssignmentCollection on Isar {
  IsarCollection<PitAssignment> get pitAssignments => this.collection();
}

const PitAssignmentSchema = CollectionSchema(
  name: r'PitAssignment',
  id: -8250211956828930242,
  properties: {
    r'eventKey': PropertySchema(
      id: 0,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'teamNumber': PropertySchema(
      id: 1,
      name: r'teamNumber',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 2,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(id: 3, name: r'userId', type: IsarType.string),
  },

  estimateSize: _pitAssignmentEstimateSize,
  serialize: _pitAssignmentSerialize,
  deserialize: _pitAssignmentDeserialize,
  deserializeProp: _pitAssignmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey_teamNumber': IndexSchema(
      id: 8748572956853585777,
      name: r'eventKey_teamNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'teamNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _pitAssignmentGetId,
  getLinks: _pitAssignmentGetLinks,
  attach: _pitAssignmentAttach,
  version: '3.3.2',
);

int _pitAssignmentEstimateSize(
  PitAssignment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _pitAssignmentSerialize(
  PitAssignment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.eventKey);
  writer.writeLong(offsets[1], object.teamNumber);
  writer.writeDateTime(offsets[2], object.updatedAt);
  writer.writeString(offsets[3], object.userId);
}

PitAssignment _pitAssignmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PitAssignment();
  object.eventKey = reader.readString(offsets[0]);
  object.id = id;
  object.teamNumber = reader.readLong(offsets[1]);
  object.updatedAt = reader.readDateTime(offsets[2]);
  object.userId = reader.readString(offsets[3]);
  return object;
}

P _pitAssignmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pitAssignmentGetId(PitAssignment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pitAssignmentGetLinks(PitAssignment object) {
  return [];
}

void _pitAssignmentAttach(
  IsarCollection<dynamic> col,
  Id id,
  PitAssignment object,
) {
  object.id = id;
}

extension PitAssignmentByIndex on IsarCollection<PitAssignment> {
  Future<PitAssignment?> getByEventKeyTeamNumber(
    String eventKey,
    int teamNumber,
  ) {
    return getByIndex(r'eventKey_teamNumber', [eventKey, teamNumber]);
  }

  PitAssignment? getByEventKeyTeamNumberSync(String eventKey, int teamNumber) {
    return getByIndexSync(r'eventKey_teamNumber', [eventKey, teamNumber]);
  }

  Future<bool> deleteByEventKeyTeamNumber(String eventKey, int teamNumber) {
    return deleteByIndex(r'eventKey_teamNumber', [eventKey, teamNumber]);
  }

  bool deleteByEventKeyTeamNumberSync(String eventKey, int teamNumber) {
    return deleteByIndexSync(r'eventKey_teamNumber', [eventKey, teamNumber]);
  }

  Future<List<PitAssignment?>> getAllByEventKeyTeamNumber(
    List<String> eventKeyValues,
    List<int> teamNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      teamNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], teamNumberValues[i]]);
    }

    return getAllByIndex(r'eventKey_teamNumber', values);
  }

  List<PitAssignment?> getAllByEventKeyTeamNumberSync(
    List<String> eventKeyValues,
    List<int> teamNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      teamNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], teamNumberValues[i]]);
    }

    return getAllByIndexSync(r'eventKey_teamNumber', values);
  }

  Future<int> deleteAllByEventKeyTeamNumber(
    List<String> eventKeyValues,
    List<int> teamNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      teamNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], teamNumberValues[i]]);
    }

    return deleteAllByIndex(r'eventKey_teamNumber', values);
  }

  int deleteAllByEventKeyTeamNumberSync(
    List<String> eventKeyValues,
    List<int> teamNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      teamNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], teamNumberValues[i]]);
    }

    return deleteAllByIndexSync(r'eventKey_teamNumber', values);
  }

  Future<Id> putByEventKeyTeamNumber(PitAssignment object) {
    return putByIndex(r'eventKey_teamNumber', object);
  }

  Id putByEventKeyTeamNumberSync(
    PitAssignment object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'eventKey_teamNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKeyTeamNumber(List<PitAssignment> objects) {
    return putAllByIndex(r'eventKey_teamNumber', objects);
  }

  List<Id> putAllByEventKeyTeamNumberSync(
    List<PitAssignment> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'eventKey_teamNumber',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension PitAssignmentQueryWhereSort
    on QueryBuilder<PitAssignment, PitAssignment, QWhere> {
  QueryBuilder<PitAssignment, PitAssignment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PitAssignmentQueryWhere
    on QueryBuilder<PitAssignment, PitAssignment, QWhereClause> {
  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> idBetween(
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyEqualToAnyTeamNumber(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'eventKey_teamNumber',
          value: [eventKey],
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyNotEqualToAnyTeamNumber(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [],
                upper: [eventKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [],
                upper: [eventKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyTeamNumberEqualTo(String eventKey, int teamNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'eventKey_teamNumber',
          value: [eventKey, teamNumber],
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyEqualToTeamNumberNotEqualTo(String eventKey, int teamNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey],
                upper: [eventKey, teamNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey, teamNumber],
                includeLower: false,
                upper: [eventKey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey, teamNumber],
                includeLower: false,
                upper: [eventKey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_teamNumber',
                lower: [eventKey],
                upper: [eventKey, teamNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyEqualToTeamNumberGreaterThan(
    String eventKey,
    int teamNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_teamNumber',
          lower: [eventKey, teamNumber],
          includeLower: include,
          upper: [eventKey],
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyEqualToTeamNumberLessThan(
    String eventKey,
    int teamNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_teamNumber',
          lower: [eventKey],
          upper: [eventKey, teamNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  eventKeyEqualToTeamNumberBetween(
    String eventKey,
    int lowerTeamNumber,
    int upperTeamNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_teamNumber',
          lower: [eventKey, lowerTeamNumber],
          includeLower: includeLower,
          upper: [eventKey, upperTeamNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause> userIdEqualTo(
    String userId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'userId', value: [userId]),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterWhereClause>
  userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PitAssignmentQueryFilter
    on QueryBuilder<PitAssignment, PitAssignment, QFilterCondition> {
  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  teamNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'teamNumber', value: value),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  teamNumberGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  teamNumberLessThan(int value, {bool include = false}) {
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  teamNumberBetween(
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

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterFilterCondition>
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension PitAssignmentQueryObject
    on QueryBuilder<PitAssignment, PitAssignment, QFilterCondition> {}

extension PitAssignmentQueryLinks
    on QueryBuilder<PitAssignment, PitAssignment, QFilterCondition> {}

extension PitAssignmentQuerySortBy
    on QueryBuilder<PitAssignment, PitAssignment, QSortBy> {
  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> sortByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  sortByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PitAssignmentQuerySortThenBy
    on QueryBuilder<PitAssignment, PitAssignment, QSortThenBy> {
  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  thenByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PitAssignmentQueryWhereDistinct
    on QueryBuilder<PitAssignment, PitAssignment, QDistinct> {
  QueryBuilder<PitAssignment, PitAssignment, QDistinct> distinctByEventKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QDistinct> distinctByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teamNumber');
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PitAssignment, PitAssignment, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension PitAssignmentQueryProperty
    on QueryBuilder<PitAssignment, PitAssignment, QQueryProperty> {
  QueryBuilder<PitAssignment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PitAssignment, String, QQueryOperations> eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<PitAssignment, int, QQueryOperations> teamNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teamNumber');
    });
  }

  QueryBuilder<PitAssignment, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PitAssignment, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
