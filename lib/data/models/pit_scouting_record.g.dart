// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pit_scouting_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPitScoutingRecordCollection on Isar {
  IsarCollection<PitScoutingRecord> get pitScoutingRecords => this.collection();
}

const PitScoutingRecordSchema = CollectionSchema(
  name: r'PitScoutingRecord',
  id: 7018151762287867638,
  properties: {
    r'eventKey': PropertySchema(
      id: 0,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(id: 1, name: r'notes', type: IsarType.string),
    r'pitDataJson': PropertySchema(
      id: 2,
      name: r'pitDataJson',
      type: IsarType.string,
    ),
    r'scouterName': PropertySchema(
      id: 3,
      name: r'scouterName',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(id: 4, name: r'synced', type: IsarType.bool),
    r'teamNumber': PropertySchema(
      id: 5,
      name: r'teamNumber',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 7, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _pitScoutingRecordEstimateSize,
  serialize: _pitScoutingRecordSerialize,
  deserialize: _pitScoutingRecordDeserialize,
  deserializeProp: _pitScoutingRecordDeserializeProp,
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

  getId: _pitScoutingRecordGetId,
  getLinks: _pitScoutingRecordGetLinks,
  attach: _pitScoutingRecordAttach,
  version: '3.3.2',
);

int _pitScoutingRecordEstimateSize(
  PitScoutingRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.pitDataJson.length * 3;
  bytesCount += 3 + object.scouterName.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _pitScoutingRecordSerialize(
  PitScoutingRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.eventKey);
  writer.writeString(offsets[1], object.notes);
  writer.writeString(offsets[2], object.pitDataJson);
  writer.writeString(offsets[3], object.scouterName);
  writer.writeBool(offsets[4], object.synced);
  writer.writeLong(offsets[5], object.teamNumber);
  writer.writeDateTime(offsets[6], object.timestamp);
  writer.writeString(offsets[7], object.uuid);
}

PitScoutingRecord _pitScoutingRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PitScoutingRecord();
  object.eventKey = reader.readString(offsets[0]);
  object.id = id;
  object.notes = reader.readString(offsets[1]);
  object.pitDataJson = reader.readString(offsets[2]);
  object.scouterName = reader.readString(offsets[3]);
  object.synced = reader.readBool(offsets[4]);
  object.teamNumber = reader.readLong(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  object.uuid = reader.readString(offsets[7]);
  return object;
}

P _pitScoutingRecordDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pitScoutingRecordGetId(PitScoutingRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pitScoutingRecordGetLinks(
  PitScoutingRecord object,
) {
  return [];
}

void _pitScoutingRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  PitScoutingRecord object,
) {
  object.id = id;
}

extension PitScoutingRecordByIndex on IsarCollection<PitScoutingRecord> {
  Future<PitScoutingRecord?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  PitScoutingRecord? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<PitScoutingRecord?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<PitScoutingRecord?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(PitScoutingRecord object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(PitScoutingRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<PitScoutingRecord> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<PitScoutingRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension PitScoutingRecordQueryWhereSort
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QWhere> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhere>
  anyTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'teamNumber'),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhere> anySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'synced'),
      );
    });
  }
}

extension PitScoutingRecordQueryWhere
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QWhereClause> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  teamNumberEqualTo(int teamNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'teamNumber', value: [teamNumber]),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
  syncedEqualTo(bool synced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'synced', value: [synced]),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterWhereClause>
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

extension PitScoutingRecordQueryFilter
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QFilterCondition> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pitDataJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pitDataJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pitDataJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pitDataJson', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  pitDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pitDataJson', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  scouterNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scouterName', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  scouterNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scouterName', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'synced', value: value),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  teamNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'teamNumber', value: value),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
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

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension PitScoutingRecordQueryObject
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QFilterCondition> {}

extension PitScoutingRecordQueryLinks
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QFilterCondition> {}

extension PitScoutingRecordQuerySortBy
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QSortBy> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByPitDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitDataJson', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByPitDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitDataJson', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByScouterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByScouterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PitScoutingRecordQuerySortThenBy
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QSortThenBy> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByPitDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitDataJson', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByPitDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pitDataJson', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByScouterName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByScouterNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scouterName', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByTeamNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamNumber', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QAfterSortBy>
  thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PitScoutingRecordQueryWhereDistinct
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct> {
  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByPitDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pitDataJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByScouterName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scouterName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByTeamNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teamNumber');
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<PitScoutingRecord, PitScoutingRecord, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension PitScoutingRecordQueryProperty
    on QueryBuilder<PitScoutingRecord, PitScoutingRecord, QQueryProperty> {
  QueryBuilder<PitScoutingRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PitScoutingRecord, String, QQueryOperations> eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<PitScoutingRecord, String, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<PitScoutingRecord, String, QQueryOperations>
  pitDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pitDataJson');
    });
  }

  QueryBuilder<PitScoutingRecord, String, QQueryOperations>
  scouterNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scouterName');
    });
  }

  QueryBuilder<PitScoutingRecord, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<PitScoutingRecord, int, QQueryOperations> teamNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teamNumber');
    });
  }

  QueryBuilder<PitScoutingRecord, DateTime, QQueryOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<PitScoutingRecord, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
