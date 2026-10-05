/// Tolerant readers for values that arrive from `jsonDecode`/SharedPreferences
/// (and from Isar-backed maps that may be handed back in either shape).
///
/// Model `fromJson`/`fromMap` methods use these instead of hard casts so a
/// value that is already decoded as the right type, stored as an ISO-8601
/// string, or absent/null never throws.
library;

/// Parses [value] into a [DateTime].
///
/// Accepts a [DateTime] (already decoded) or an ISO-8601 [String] (the shape
/// every serializer in this codebase writes). Returns null otherwise.
DateTime? dateTimeOrNull(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Parses [value] into a [double], tolerating ints coming out of JSON.
double? doubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString());
}

/// Parses [value] into an [int], tolerating JSON numbers arriving as doubles.
int? intValueOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString());
}
