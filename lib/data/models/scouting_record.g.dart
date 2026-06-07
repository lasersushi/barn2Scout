// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scouting_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScoutingRecordCollection on Isar {
  IsarCollection<ScoutingRecord> get scoutingRecords => this.collection();
}

const ScoutingRecordSchema = CollectionSchema(
  name: r'ScoutingRecord',
  id: 8175975101797364119,
  properties: {
    r'autoDataJson': PropertySchema(
      id: 0,
      name: r'autoDataJson',
      type: IsarType.string,
    ),
    r'endgameDataJson': PropertySchema(
      id: 1,
      name: r'endgameDataJson',
      type: IsarType.string,
    ),
    r'eventKey': PropertySchema(
      id: 2,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'matchNumber': PropertySchema(
      id: 3,
      name: r'matchNumber',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(id: 4, name: r'notes', type: IsarType.string),
    r'scouterName': PropertySchema(
      id: 5,
      name: r'scouterName',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(id: 6, name: r'synced', type: IsarType.bool),
    r'teamNumber': PropertySchema(
      id: 7,
      name: r'teamNumber',
      type: IsarType.long,
    ),
    r'teleopDataJson': PropertySchema(
      id: 8,
      name: r'teleopDataJson',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 9,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 10, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _scoutingRecordEstimateSize,
  serialize: _scoutingRecordSerialize,
  deserialize: _scoutingRecordDeserialize,
  deserializeProp: _scoutingRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'teamNumber': IndexSchema(
      id: 6426004114963464129,
      name: r'teamNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'teamNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'matchNumber': IndexSchema(
      id: -567511061156043526,
      name: r'matchNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'matchNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'synced': IndexSchema(
      id: -4832663256418428922,
      name: r'synced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'synced',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _scoutingRecordGetId,
  getLinks: _scoutingRecordGetLinks,
  attach: _scoutingRecordAttach,
  version: '3.3.2',
);

int _scoutingRecordEstimateSize(
  ScoutingRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.autoDataJson.length * 3;
  bytesCount += 3 + object.endgameDataJson.length * 3;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.scouterName.length * 3;
  bytesCount += 3 + object.teleopDataJson.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _scoutingRecordSerialize(
  ScoutingRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.autoDataJson);
  writer.writeString(offsets[1], object.endgameDataJson);
  writer.writeString(offsets[2], object.eventKey);
  writer.writeLong(offsets[3], object.matchNumber);
  writer.writeString(offsets[4], object.notes);
  writer.writeString(offsets[5], object.scouterName);
  writer.writeBool(offsets[6], object.synced);
  writer.writeLong(offsets[7], object.teamNumber);
  writer.writeString(offsets[8], object.teleopDataJson);
  writer.writeDateTime(offsets[9], object.timestamp);
  writer.writeString(offsets[10], object.uuid);
}

ScoutingRecord _scoutingRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScoutingRecord();
  object.autoDataJson = reader.readString(offsets[0]);
  object.endgameDataJson = reader.readString(offsets[1]);
  object.eventKey = reader.readString(offsets[2]);
  object.id = id;
  object.matchNumber = reader.readLong(offsets[3]);
  object.notes = reader.readString(offsets[4]);
  object.scouterName = reader.readString(offsets[5]);
  object.synced = reader.readBool(offsets[6]);
  object.teamNumber = reader.readLong(offsets[7]);
  object.teleopDataJson = reader.readString(offsets[8]);
  object.timestamp = reader.readDateTime(offsets[9]);
  object.uuid = reader.readString(offsets[10]);
  return object;
}

P _scoutingRecordDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scoutingRecordGetId(ScoutingRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _scoutingRecordGetLinks(ScoutingRecord object) {
  return [];
}

void _scoutingRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  ScoutingRecord object,
) {
  object.id = id;
}

extension ScoutingRecordByIndex on IsarCollection<ScoutingRecord> {
  Future<ScoutingRecord?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  ScoutingRecord? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<ScoutingRecord?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<ScoutingRecord?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(ScoutingRecord object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(ScoutingRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<ScoutingRecord> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<ScoutingRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension ScoutingRecordQueryWhereSort
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QWhere> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhere> anyTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'teamNumber'),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhere> anyMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'matchNumber'),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhere> anySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'synced'),
      );
    });
  }
}

extension ScoutingRecordQueryWhere
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QWhereClause> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  teamNumberEqualTo(int teamNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'teamNumber', value: [teamNumber]),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  teamNumberNotEqualTo(int teamNumber) {
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  teamNumberGreaterThan(int teamNumber, {bool include = false}) {
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  teamNumberLessThan(int teamNumber, {bool include = false}) {
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  teamNumberBetween(
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  matchNumberEqualTo(int matchNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'matchNumber',
          value: [matchNumber],
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  matchNumberNotEqualTo(int matchNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchNumber',
                lower: [],
                upper: [matchNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchNumber',
                lower: [matchNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchNumber',
                lower: [matchNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchNumber',
                lower: [],
                upper: [matchNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  matchNumberGreaterThan(int matchNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'matchNumber',
          lower: [matchNumber],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  matchNumberLessThan(int matchNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'matchNumber',
          lower: [],
          upper: [matchNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  matchNumberBetween(
    int lowerMatchNumber,
    int upperMatchNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'matchNumber',
          lower: [lowerMatchNumber],
          includeLower: includeLower,
          upper: [upperMatchNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause> syncedEqualTo(
    bool synced,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'synced', value: [synced]),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterWhereClause>
  syncedNotEqualTo(bool synced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [],
                upper: [synced],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [synced],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [synced],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [],
                upper: [synced],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ScoutingRecordQueryFilter
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QFilterCondition> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'autoDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'autoDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'autoDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'autoDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  autoDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'autoDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endgameDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'endgameDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'endgameDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endgameDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  endgameDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'endgameDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  matchNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchNumber', value: value),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  matchNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  matchNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  matchNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scouterName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'scouterName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'scouterName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scouterName', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  scouterNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scouterName', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'synced', value: value),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teamNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'teamNumber', value: value),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'teleopDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'teleopDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'teleopDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'teleopDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  teleopDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'teleopDataJson', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension ScoutingRecordQueryObject
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QFilterCondition> {}

extension ScoutingRecordQueryLinks
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QFilterCondition> {}

extension ScoutingRecordQuerySortBy
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QSortBy> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByAutoDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByAutoDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByEndgameDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endgameDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByEndgameDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endgameDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByMatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByScouterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByScouterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByTeleopDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teleopDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByTeleopDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teleopDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ScoutingRecordQuerySortThenBy
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QSortThenBy> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByAutoDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByAutoDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByEndgameDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endgameDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByEndgameDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endgameDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByMatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByScouterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByScouterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByTeleopDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teleopDataJson', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByTeleopDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teleopDataJson', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ScoutingRecordQueryWhereDistinct
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct> {
  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByAutoDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoDataJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByEndgameDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'endgameDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct> distinctByEventKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchNumber');
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByScouterName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scouterName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teamNumber');
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByTeleopDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'teleopDataJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<ScoutingRecord, ScoutingRecord, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension ScoutingRecordQueryProperty
    on QueryBuilder<ScoutingRecord, ScoutingRecord, QQueryProperty> {
  QueryBuilder<ScoutingRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations>
  autoDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoDataJson');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations>
  endgameDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endgameDataJson');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations> eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<ScoutingRecord, int, QQueryOperations> matchNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchNumber');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations> scouterNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scouterName');
    });
  }

  QueryBuilder<ScoutingRecord, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<ScoutingRecord, int, QQueryOperations> teamNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teamNumber');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations>
  teleopDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teleopDataJson');
    });
  }

  QueryBuilder<ScoutingRecord, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<ScoutingRecord, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
