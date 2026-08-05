// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Emap.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EmapSchema = Schema(
  name: r'Emap',
  id: 6560251807475344057,
  properties: {
    r'buyPrice': PropertySchema(
      id: 0,
      name: r'buyPrice',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'sellPrice': PropertySchema(
      id: 2,
      name: r'sellPrice',
      type: IsarType.double,
    )
  },
  estimateSize: _emapEstimateSize,
  serialize: _emapSerialize,
  deserialize: _emapDeserialize,
  deserializeProp: _emapDeserializeProp,
);

int _emapEstimateSize(
  Emap object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _emapSerialize(
  Emap object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.buyPrice);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeDouble(offsets[2], object.sellPrice);
}

Emap _emapDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Emap();
  object.buyPrice = reader.readDoubleOrNull(offsets[0]);
  object.date = reader.readDateTimeOrNull(offsets[1]);
  object.sellPrice = reader.readDoubleOrNull(offsets[2]);
  return object;
}

P _emapDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EmapQueryFilter on QueryBuilder<Emap, Emap, QFilterCondition> {
  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'buyPrice',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'buyPrice',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'buyPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'buyPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'buyPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> buyPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'buyPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateGreaterThan(
    DateTime? value, {
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

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateLessThan(
    DateTime? value, {
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

  QueryBuilder<Emap, Emap, QAfterFilterCondition> dateBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sellPrice',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sellPrice',
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Emap, Emap, QAfterFilterCondition> sellPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension EmapQueryObject on QueryBuilder<Emap, Emap, QFilterCondition> {}
