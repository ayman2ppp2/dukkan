// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLogCollection on Isar {
  IsarCollection<Log> get logs => this.collection();
}

const LogSchema = CollectionSchema(
  name: r'Log',
  id: 7425915233166922082,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'discount': PropertySchema(
      id: 1,
      name: r'discount',
      type: IsarType.double,
    ),
    r'expense': PropertySchema(
      id: 2,
      name: r'expense',
      type: IsarType.bool,
    ),
    r'expenseId': PropertySchema(
      id: 3,
      name: r'expenseId',
      type: IsarType.long,
    ),
    r'loaned': PropertySchema(
      id: 4,
      name: r'loaned',
      type: IsarType.bool,
    ),
    r'loanerID': PropertySchema(
      id: 5,
      name: r'loanerID',
      type: IsarType.long,
    ),
    r'price': PropertySchema(
      id: 6,
      name: r'price',
      type: IsarType.double,
    ),
    r'products': PropertySchema(
      id: 7,
      name: r'products',
      type: IsarType.objectList,
      target: r'EmbeddedProduct',
    ),
    r'profit': PropertySchema(
      id: 8,
      name: r'profit',
      type: IsarType.double,
    )
  },
  estimateSize: _logEstimateSize,
  serialize: _logSerialize,
  deserialize: _logDeserialize,
  deserializeProp: _logDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'loaned': IndexSchema(
      id: -5031882674968475024,
      name: r'loaned',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'loaned',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'loanerID': IndexSchema(
      id: -8216433769298640305,
      name: r'loanerID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'loanerID',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'expense': IndexSchema(
      id: -4097527398321967696,
      name: r'expense',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expense',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'expenseId': IndexSchema(
      id: -8289172275633362361,
      name: r'expenseId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expenseId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'EmbeddedProduct': EmbeddedProductSchema},
  getId: _logGetId,
  getLinks: _logGetLinks,
  attach: _logAttach,
  version: '3.1.0+1',
);

int _logEstimateSize(
  Log object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.products.length * 3;
  {
    final offsets = allOffsets[EmbeddedProduct]!;
    for (var i = 0; i < object.products.length; i++) {
      final value = object.products[i];
      bytesCount +=
          EmbeddedProductSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _logSerialize(
  Log object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeDouble(offsets[1], object.discount);
  writer.writeBool(offsets[2], object.expense);
  writer.writeLong(offsets[3], object.expenseId);
  writer.writeBool(offsets[4], object.loaned);
  writer.writeLong(offsets[5], object.loanerID);
  writer.writeDouble(offsets[6], object.price);
  writer.writeObjectList<EmbeddedProduct>(
    offsets[7],
    allOffsets,
    EmbeddedProductSchema.serialize,
    object.products,
  );
  writer.writeDouble(offsets[8], object.profit);
}

Log _logDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Log(
    date: reader.readDateTime(offsets[0]),
    discount: reader.readDouble(offsets[1]),
    loaned: reader.readBool(offsets[4]),
    loanerID: reader.readLongOrNull(offsets[5]),
    price: reader.readDouble(offsets[6]),
    profit: reader.readDouble(offsets[8]),
  );
  object.expense = reader.readBool(offsets[2]);
  object.expenseId = reader.readLongOrNull(offsets[3]);
  object.id = id;
  object.products = reader.readObjectList<EmbeddedProduct>(
        offsets[7],
        EmbeddedProductSchema.deserialize,
        allOffsets,
        EmbeddedProduct(),
      ) ??
      [];
  return object;
}

P _logDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readObjectList<EmbeddedProduct>(
            offset,
            EmbeddedProductSchema.deserialize,
            allOffsets,
            EmbeddedProduct(),
          ) ??
          []) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _logGetId(Log object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _logGetLinks(Log object) {
  return [];
}

void _logAttach(IsarCollection<dynamic> col, Id id, Log object) {
  object.id = id;
}

extension LogByIndex on IsarCollection<Log> {
  Future<Log?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  Log? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<Log?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<Log?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(Log object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(Log object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<Log> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<Log> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension LogQueryWhereSort on QueryBuilder<Log, Log, QWhere> {
  QueryBuilder<Log, Log, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyLoaned() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'loaned'),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyLoanerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'loanerID'),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyExpense() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expense'),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expenseId'),
      );
    });
  }
}

extension LogQueryWhere on QueryBuilder<Log, Log, QWhereClause> {
  QueryBuilder<Log, Log, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Log, Log, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idBetween(
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

  QueryBuilder<Log, Log, QAfterWhereClause> dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanedEqualTo(bool loaned) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'loaned',
        value: [loaned],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanedNotEqualTo(bool loaned) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loaned',
              lower: [],
              upper: [loaned],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loaned',
              lower: [loaned],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loaned',
              lower: [loaned],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loaned',
              lower: [],
              upper: [loaned],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'loanerID',
        value: [null],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loanerID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDEqualTo(int? loanerID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'loanerID',
        value: [loanerID],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDNotEqualTo(int? loanerID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loanerID',
              lower: [],
              upper: [loanerID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loanerID',
              lower: [loanerID],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loanerID',
              lower: [loanerID],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loanerID',
              lower: [],
              upper: [loanerID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDGreaterThan(
    int? loanerID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loanerID',
        lower: [loanerID],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDLessThan(
    int? loanerID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loanerID',
        lower: [],
        upper: [loanerID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> loanerIDBetween(
    int? lowerLoanerID,
    int? upperLoanerID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loanerID',
        lower: [lowerLoanerID],
        includeLower: includeLower,
        upper: [upperLoanerID],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseEqualTo(bool expense) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'expense',
        value: [expense],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseNotEqualTo(bool expense) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expense',
              lower: [],
              upper: [expense],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expense',
              lower: [expense],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expense',
              lower: [expense],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expense',
              lower: [],
              upper: [expense],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'expenseId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdEqualTo(int? expenseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'expenseId',
        value: [expenseId],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdNotEqualTo(
      int? expenseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseId',
              lower: [],
              upper: [expenseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseId',
              lower: [expenseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseId',
              lower: [expenseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseId',
              lower: [],
              upper: [expenseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdGreaterThan(
    int? expenseId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseId',
        lower: [expenseId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdLessThan(
    int? expenseId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseId',
        lower: [],
        upper: [expenseId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> expenseIdBetween(
    int? lowerExpenseId,
    int? upperExpenseId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseId',
        lower: [lowerExpenseId],
        includeLower: includeLower,
        upper: [upperExpenseId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LogQueryFilter on QueryBuilder<Log, Log, QFilterCondition> {
  QueryBuilder<Log, Log, QAfterFilterCondition> dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> discountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> discountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> discountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> discountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expense',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expenseId',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expenseId',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expenseId',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expenseId',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expenseId',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> expenseIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expenseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> loanedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loaned',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'loanerID',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'loanerID',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loanerID',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loanerID',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loanerID',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> loanerIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loanerID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> productsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'products',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> profitEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> profitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> profitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> profitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension LogQueryObject on QueryBuilder<Log, Log, QFilterCondition> {
  QueryBuilder<Log, Log, QAfterFilterCondition> productsElement(
      FilterQuery<EmbeddedProduct> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'products');
    });
  }
}

extension LogQueryLinks on QueryBuilder<Log, Log, QFilterCondition> {}

extension LogQuerySortBy on QueryBuilder<Log, Log, QSortBy> {
  QueryBuilder<Log, Log, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByExpense() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expense', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByExpenseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expense', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByExpenseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByLoaned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loaned', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByLoanedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loaned', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByLoanerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loanerID', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByLoanerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loanerID', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.desc);
    });
  }
}

extension LogQuerySortThenBy on QueryBuilder<Log, Log, QSortThenBy> {
  QueryBuilder<Log, Log, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByExpense() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expense', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByExpenseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expense', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByExpenseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLoaned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loaned', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLoanedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loaned', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLoanerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loanerID', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLoanerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loanerID', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profit', Sort.desc);
    });
  }
}

extension LogQueryWhereDistinct on QueryBuilder<Log, Log, QDistinct> {
  QueryBuilder<Log, Log, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discount');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByExpense() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expense');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expenseId');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByLoaned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loaned');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByLoanerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loanerID');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profit');
    });
  }
}

extension LogQueryProperty on QueryBuilder<Log, Log, QQueryProperty> {
  QueryBuilder<Log, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Log, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<Log, double, QQueryOperations> discountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discount');
    });
  }

  QueryBuilder<Log, bool, QQueryOperations> expenseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expense');
    });
  }

  QueryBuilder<Log, int?, QQueryOperations> expenseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expenseId');
    });
  }

  QueryBuilder<Log, bool, QQueryOperations> loanedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loaned');
    });
  }

  QueryBuilder<Log, int?, QQueryOperations> loanerIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loanerID');
    });
  }

  QueryBuilder<Log, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<Log, List<EmbeddedProduct>, QQueryOperations>
      productsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'products');
    });
  }

  QueryBuilder<Log, double, QQueryOperations> profitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profit');
    });
  }
}
