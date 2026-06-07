// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frc_match.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFrcMatchCollection on Isar {
  IsarCollection<FrcMatch> get matches => this.collection();
}

const FrcMatchSchema = CollectionSchema(
  name: r'FrcMatch',
  id: -6468484781755067887,
  properties: {
    r'blueAlliance': PropertySchema(
      id: 0,
      name: r'blueAlliance',
      type: IsarType.longList,
    ),
    r'eventKey': PropertySchema(
      id: 1,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'matchNumber': PropertySchema(
      id: 2,
      name: r'matchNumber',
      type: IsarType.long,
    ),
    r'matchType': PropertySchema(
      id: 3,
      name: r'matchType',
      type: IsarType.byte,
      enumMap: _FrcMatchmatchTypeEnumValueMap,
    ),
    r'redAlliance': PropertySchema(
      id: 4,
      name: r'redAlliance',
      type: IsarType.longList,
    ),
  },

  estimateSize: _frcMatchEstimateSize,
  serialize: _frcMatchSerialize,
  deserialize: _frcMatchDeserialize,
  deserializeProp: _frcMatchDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey_matchType_matchNumber': IndexSchema(
      id: -2804666174610398988,
      name: r'eventKey_matchType_matchNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'matchType',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'matchNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _frcMatchGetId,
  getLinks: _frcMatchGetLinks,
  attach: _frcMatchAttach,
  version: '3.3.2',
);

int _frcMatchEstimateSize(
  FrcMatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blueAlliance.length * 8;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.redAlliance.length * 8;
  return bytesCount;
}

void _frcMatchSerialize(
  FrcMatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.blueAlliance);
  writer.writeString(offsets[1], object.eventKey);
  writer.writeLong(offsets[2], object.matchNumber);
  writer.writeByte(offsets[3], object.matchType.index);
  writer.writeLongList(offsets[4], object.redAlliance);
}

FrcMatch _frcMatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FrcMatch();
  object.blueAlliance = reader.readLongList(offsets[0]) ?? [];
  object.eventKey = reader.readString(offsets[1]);
  object.id = id;
  object.matchNumber = reader.readLong(offsets[2]);
  object.matchType =
      _FrcMatchmatchTypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
      MatchType.qual;
  object.redAlliance = reader.readLongList(offsets[4]) ?? [];
  return object;
}

P _frcMatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (_FrcMatchmatchTypeValueEnumMap[reader.readByteOrNull(offset)] ??
              MatchType.qual)
          as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _FrcMatchmatchTypeEnumValueMap = {'qual': 0, 'playoff': 1};
const _FrcMatchmatchTypeValueEnumMap = {
  0: MatchType.qual,
  1: MatchType.playoff,
};

Id _frcMatchGetId(FrcMatch object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _frcMatchGetLinks(FrcMatch object) {
  return [];
}

void _frcMatchAttach(IsarCollection<dynamic> col, Id id, FrcMatch object) {
  object.id = id;
}

extension FrcMatchByIndex on IsarCollection<FrcMatch> {
  Future<FrcMatch?> getByEventKeyMatchTypeMatchNumber(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return getByIndex(r'eventKey_matchType_matchNumber', [
      eventKey,
      matchType,
      matchNumber,
    ]);
  }

  FrcMatch? getByEventKeyMatchTypeMatchNumberSync(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return getByIndexSync(r'eventKey_matchType_matchNumber', [
      eventKey,
      matchType,
      matchNumber,
    ]);
  }

  Future<bool> deleteByEventKeyMatchTypeMatchNumber(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return deleteByIndex(r'eventKey_matchType_matchNumber', [
      eventKey,
      matchType,
      matchNumber,
    ]);
  }

  bool deleteByEventKeyMatchTypeMatchNumberSync(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return deleteByIndexSync(r'eventKey_matchType_matchNumber', [
      eventKey,
      matchType,
      matchNumber,
    ]);
  }

  Future<List<FrcMatch?>> getAllByEventKeyMatchTypeMatchNumber(
    List<String> eventKeyValues,
    List<MatchType> matchTypeValues,
    List<int> matchNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      matchTypeValues.length == len && matchNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], matchTypeValues[i], matchNumberValues[i]]);
    }

    return getAllByIndex(r'eventKey_matchType_matchNumber', values);
  }

  List<FrcMatch?> getAllByEventKeyMatchTypeMatchNumberSync(
    List<String> eventKeyValues,
    List<MatchType> matchTypeValues,
    List<int> matchNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      matchTypeValues.length == len && matchNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], matchTypeValues[i], matchNumberValues[i]]);
    }

    return getAllByIndexSync(r'eventKey_matchType_matchNumber', values);
  }

  Future<int> deleteAllByEventKeyMatchTypeMatchNumber(
    List<String> eventKeyValues,
    List<MatchType> matchTypeValues,
    List<int> matchNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      matchTypeValues.length == len && matchNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], matchTypeValues[i], matchNumberValues[i]]);
    }

    return deleteAllByIndex(r'eventKey_matchType_matchNumber', values);
  }

  int deleteAllByEventKeyMatchTypeMatchNumberSync(
    List<String> eventKeyValues,
    List<MatchType> matchTypeValues,
    List<int> matchNumberValues,
  ) {
    final len = eventKeyValues.length;
    assert(
      matchTypeValues.length == len && matchNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([eventKeyValues[i], matchTypeValues[i], matchNumberValues[i]]);
    }

    return deleteAllByIndexSync(r'eventKey_matchType_matchNumber', values);
  }

  Future<Id> putByEventKeyMatchTypeMatchNumber(FrcMatch object) {
    return putByIndex(r'eventKey_matchType_matchNumber', object);
  }

  Id putByEventKeyMatchTypeMatchNumberSync(
    FrcMatch object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'eventKey_matchType_matchNumber',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByEventKeyMatchTypeMatchNumber(
    List<FrcMatch> objects,
  ) {
    return putAllByIndex(r'eventKey_matchType_matchNumber', objects);
  }

  List<Id> putAllByEventKeyMatchTypeMatchNumberSync(
    List<FrcMatch> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'eventKey_matchType_matchNumber',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension FrcMatchQueryWhereSort on QueryBuilder<FrcMatch, FrcMatch, QWhere> {
  QueryBuilder<FrcMatch, FrcMatch, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FrcMatchQueryWhere on QueryBuilder<FrcMatch, FrcMatch, QWhereClause> {
  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause> idBetween(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyEqualToAnyMatchTypeMatchNumber(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'eventKey_matchType_matchNumber',
          value: [eventKey],
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyNotEqualToAnyMatchTypeMatchNumber(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [],
                upper: [eventKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [],
                upper: [eventKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeEqualToAnyMatchNumber(String eventKey, MatchType matchType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'eventKey_matchType_matchNumber',
          value: [eventKey, matchType],
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyEqualToMatchTypeNotEqualToAnyMatchNumber(
    String eventKey,
    MatchType matchType,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey],
                upper: [eventKey, matchType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType],
                includeLower: false,
                upper: [eventKey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType],
                includeLower: false,
                upper: [eventKey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey],
                upper: [eventKey, matchType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyEqualToMatchTypeGreaterThanAnyMatchNumber(
    String eventKey,
    MatchType matchType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey, matchType],
          includeLower: include,
          upper: [eventKey],
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyEqualToMatchTypeLessThanAnyMatchNumber(
    String eventKey,
    MatchType matchType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey],
          upper: [eventKey, matchType],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyEqualToMatchTypeBetweenAnyMatchNumber(
    String eventKey,
    MatchType lowerMatchType,
    MatchType upperMatchType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey, lowerMatchType],
          includeLower: includeLower,
          upper: [eventKey, upperMatchType],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeMatchNumberEqualTo(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'eventKey_matchType_matchNumber',
          value: [eventKey, matchType, matchNumber],
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeEqualToMatchNumberNotEqualTo(
    String eventKey,
    MatchType matchType,
    int matchNumber,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType],
                upper: [eventKey, matchType, matchNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType, matchNumber],
                includeLower: false,
                upper: [eventKey, matchType],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType, matchNumber],
                includeLower: false,
                upper: [eventKey, matchType],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventKey_matchType_matchNumber',
                lower: [eventKey, matchType],
                upper: [eventKey, matchType, matchNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeEqualToMatchNumberGreaterThan(
    String eventKey,
    MatchType matchType,
    int matchNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey, matchType, matchNumber],
          includeLower: include,
          upper: [eventKey, matchType],
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeEqualToMatchNumberLessThan(
    String eventKey,
    MatchType matchType,
    int matchNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey, matchType],
          upper: [eventKey, matchType, matchNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterWhereClause>
  eventKeyMatchTypeEqualToMatchNumberBetween(
    String eventKey,
    MatchType matchType,
    int lowerMatchNumber,
    int upperMatchNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'eventKey_matchType_matchNumber',
          lower: [eventKey, matchType, lowerMatchNumber],
          includeLower: includeLower,
          upper: [eventKey, matchType, upperMatchNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FrcMatchQueryFilter
    on QueryBuilder<FrcMatch, FrcMatch, QFilterCondition> {
  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'blueAlliance', value: value),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'blueAlliance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'blueAlliance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'blueAlliance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blueAlliance', length, true, length, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blueAlliance', 0, true, 0, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blueAlliance', 0, false, 999999, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blueAlliance', 0, true, length, include);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'blueAlliance', length, include, 999999, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  blueAllianceLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blueAlliance',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyGreaterThan(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyLessThan(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyBetween(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventKey', value: ''),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchNumberEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchNumber', value: value),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchNumberLessThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchNumberBetween(
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

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchTypeEqualTo(
    MatchType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchType', value: value),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchTypeGreaterThan(
    MatchType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchTypeLessThan(
    MatchType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> matchTypeBetween(
    MatchType lower,
    MatchType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redAlliance', value: value),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'redAlliance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'redAlliance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'redAlliance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redAlliance', length, true, length, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition> redAllianceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redAlliance', 0, true, 0, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redAlliance', 0, false, 999999, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redAlliance', 0, true, length, include);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redAlliance', length, include, 999999, true);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterFilterCondition>
  redAllianceLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'redAlliance',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension FrcMatchQueryObject
    on QueryBuilder<FrcMatch, FrcMatch, QFilterCondition> {}

extension FrcMatchQueryLinks
    on QueryBuilder<FrcMatch, FrcMatch, QFilterCondition> {}

extension FrcMatchQuerySortBy on QueryBuilder<FrcMatch, FrcMatch, QSortBy> {
  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByMatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.desc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> sortByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }
}

extension FrcMatchQuerySortThenBy
    on QueryBuilder<FrcMatch, FrcMatch, QSortThenBy> {
  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByMatchNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchNumber', Sort.desc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QAfterSortBy> thenByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }
}

extension FrcMatchQueryWhereDistinct
    on QueryBuilder<FrcMatch, FrcMatch, QDistinct> {
  QueryBuilder<FrcMatch, FrcMatch, QDistinct> distinctByBlueAlliance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blueAlliance');
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QDistinct> distinctByEventKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QDistinct> distinctByMatchNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchNumber');
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QDistinct> distinctByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchType');
    });
  }

  QueryBuilder<FrcMatch, FrcMatch, QDistinct> distinctByRedAlliance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redAlliance');
    });
  }
}

extension FrcMatchQueryProperty
    on QueryBuilder<FrcMatch, FrcMatch, QQueryProperty> {
  QueryBuilder<FrcMatch, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FrcMatch, List<int>, QQueryOperations> blueAllianceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blueAlliance');
    });
  }

  QueryBuilder<FrcMatch, String, QQueryOperations> eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<FrcMatch, int, QQueryOperations> matchNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchNumber');
    });
  }

  QueryBuilder<FrcMatch, MatchType, QQueryOperations> matchTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchType');
    });
  }

  QueryBuilder<FrcMatch, List<int>, QQueryOperations> redAllianceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redAlliance');
    });
  }
}
