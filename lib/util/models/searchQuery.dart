class SearchQuery {
  final String queryText;
  final DateTime startDate;
  final DateTime endDate;
  final String? userId;

  SearchQuery({
    required this.queryText,
    required this.startDate,
    required this.endDate,
    this.userId,
  });

  // Convert a SearchQuery object to a Map for storage or serialization
  Map<String, dynamic> toMap() {
    return {
      'queryText': queryText,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
    };
  }

  // Create a SearchQuery object from a Map
  factory SearchQuery.fromMap(Map<String, dynamic> map) {
    return SearchQuery(
      queryText: map['queryText'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      userId: map['userId'],
    );
  }

  @override
  String toString() {
    return 'SearchQuery(queryText: $queryText, startDate: $startDate, endDate: $endDate, userId: $userId)';
  }
}
