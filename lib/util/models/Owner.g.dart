// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Owner.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOwnerCollection on Isar {
  IsarCollection<Owner> get owners => this.collection();
}

const OwnerSchema = CollectionSchema(
  name: r'Owner',
  id: -7588770778366197124,
  properties: {
    r'dueMoney': PropertySchema(
      id: 0,
      name: r'dueMoney',
      type: IsarType.double,
    ),
    r'lastPayment': PropertySchema(
      id: 1,
      name: r'lastPayment',
      type: IsarType.double,
    ),
    r'lastPaymentDate': PropertySchema(
      id: 2,
      name: r'lastPaymentDate',
      type: IsarType.dateTime,
    ),
    r'ownerName': PropertySchema(
      id: 3,
      name: r'ownerName',
      type: IsarType.string,
    ),
    r'totalPayed': PropertySchema(
      id: 4,
      name: r'totalPayed',
      type: IsarType.double,
    )
  },
  estimateSize: _ownerEstimateSize,
  serialize: _ownerSerialize,
  deserialize: _ownerDeserialize,
  deserializeProp: _ownerDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerName': IndexSchema(
      id: 1960260818120052236,
      name: r'ownerName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerName',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ownerGetId,
  getLinks: _ownerGetLinks,
  attach: _ownerAttach,
  version: '3.1.0+1',
);

int _ownerEstimateSize(
  Owner object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ownerName.length * 3;
  return bytesCount;
}

void _ownerSerialize(
  Owner object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.dueMoney);
  writer.writeDouble(offsets[1], object.lastPayment);
  writer.writeDateTime(offsets[2], object.lastPaymentDate);
  writer.writeString(offsets[3], object.ownerName);
  writer.writeDouble(offsets[4], object.totalPayed);
}

Owner _ownerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Owner(
    dueMoney: reader.readDouble(offsets[0]),
    lastPayment: reader.readDouble(offsets[1]),
    lastPaymentDate: reader.readDateTime(offsets[2]),
    ownerName: reader.readString(offsets[3]),
    totalPayed: reader.readDouble(offsets[4]),
  );
  object.id = id;
  return object;
}

P _ownerDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ownerGetId(Owner object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ownerGetLinks(Owner object) {
  return [];
}

void _ownerAttach(IsarCollection<dynamic> col, Id id, Owner object) {
  object.id = id;
}

extension OwnerQueryWhereSort on QueryBuilder<Owner, Owner, QWhere> {
  QueryBuilder<Owner, Owner, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhere> anyOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ownerName'),
      );
    });
  }
}

extension OwnerQueryWhere on QueryBuilder<Owner, Owner, QWhereClause> {
  QueryBuilder<Owner, Owner, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Owner, Owner, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameEqualTo(
      String ownerName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerName',
        value: [ownerName],
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameNotEqualTo(
      String ownerName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerName',
              lower: [],
              upper: [ownerName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerName',
              lower: [ownerName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerName',
              lower: [ownerName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerName',
              lower: [],
              upper: [ownerName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameGreaterThan(
    String ownerName, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerName',
        lower: [ownerName],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameLessThan(
    String ownerName, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerName',
        lower: [],
        upper: [ownerName],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameBetween(
    String lowerOwnerName,
    String upperOwnerName, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerName',
        lower: [lowerOwnerName],
        includeLower: includeLower,
        upper: [upperOwnerName],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameStartsWith(
      String OwnerNamePrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerName',
        lower: [OwnerNamePrefix],
        upper: ['$OwnerNamePrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerName',
        value: [''],
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterWhereClause> ownerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'ownerName',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'ownerName',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'ownerName',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'ownerName',
              upper: [''],
            ));
      }
    });
  }
}

extension OwnerQueryFilter on QueryBuilder<Owner, Owner, QFilterCondition> {
  QueryBuilder<Owner, Owner, QAfterFilterCondition> dueMoneyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueMoney',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> dueMoneyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueMoney',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> dueMoneyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueMoney',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> dueMoneyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueMoney',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPayment',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> lastPaymentDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPaymentDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> ownerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> totalPayedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalPayed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> totalPayedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalPayed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> totalPayedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalPayed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Owner, Owner, QAfterFilterCondition> totalPayedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalPayed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension OwnerQueryObject on QueryBuilder<Owner, Owner, QFilterCondition> {}

extension OwnerQueryLinks on QueryBuilder<Owner, Owner, QFilterCondition> {}

extension OwnerQuerySortBy on QueryBuilder<Owner, Owner, QSortBy> {
  QueryBuilder<Owner, Owner, QAfterSortBy> sortByDueMoney() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueMoney', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByDueMoneyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueMoney', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByLastPayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPayment', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByLastPaymentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPayment', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByLastPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaymentDate', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByLastPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaymentDate', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByTotalPayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPayed', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> sortByTotalPayedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPayed', Sort.desc);
    });
  }
}

extension OwnerQuerySortThenBy on QueryBuilder<Owner, Owner, QSortThenBy> {
  QueryBuilder<Owner, Owner, QAfterSortBy> thenByDueMoney() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueMoney', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByDueMoneyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueMoney', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByLastPayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPayment', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByLastPaymentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPayment', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByLastPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaymentDate', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByLastPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaymentDate', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByTotalPayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPayed', Sort.asc);
    });
  }

  QueryBuilder<Owner, Owner, QAfterSortBy> thenByTotalPayedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPayed', Sort.desc);
    });
  }
}

extension OwnerQueryWhereDistinct on QueryBuilder<Owner, Owner, QDistinct> {
  QueryBuilder<Owner, Owner, QDistinct> distinctByDueMoney() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueMoney');
    });
  }

  QueryBuilder<Owner, Owner, QDistinct> distinctByLastPayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPayment');
    });
  }

  QueryBuilder<Owner, Owner, QDistinct> distinctByLastPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPaymentDate');
    });
  }

  QueryBuilder<Owner, Owner, QDistinct> distinctByOwnerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Owner, Owner, QDistinct> distinctByTotalPayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalPayed');
    });
  }
}

extension OwnerQueryProperty on QueryBuilder<Owner, Owner, QQueryProperty> {
  QueryBuilder<Owner, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Owner, double, QQueryOperations> dueMoneyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueMoney');
    });
  }

  QueryBuilder<Owner, double, QQueryOperations> lastPaymentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPayment');
    });
  }

  QueryBuilder<Owner, DateTime, QQueryOperations> lastPaymentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPaymentDate');
    });
  }

  QueryBuilder<Owner, String, QQueryOperations> ownerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerName');
    });
  }

  QueryBuilder<Owner, double, QQueryOperations> totalPayedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalPayed');
    });
  }
}
