import 'dates.dart';

/// A bottle the user drank, kept as history after the stock goes down.
class ConsumedBottle {
  ConsumedBottle({
    this.id,
    required this.wineId,
    required DateTime date,
    String? occasion,
  }) : date = dateOnly(date),
       occasion = _blankToNull(occasion);

  /// Null until saved.
  final String? id;
  final String wineId;

  /// The day it was drunk, without time of day.
  final DateTime date;

  /// E.g. "Christmas Eve" or "With Anna", or null.
  final String? occasion;

  ConsumedBottle withId(String id) =>
      ConsumedBottle(id: id, wineId: wineId, date: date, occasion: occasion);

  /// Columns of the `consumed_bottles` table. `id` and `user_id` are set by
  /// the database.
  Map<String, dynamic> toMap() => {
    'wine_id': wineId,
    'drunk_on': toIsoDate(date),
    'occasion': occasion,
  };

  /// Throws [FormatException] for rows with missing or invalid values.
  factory ConsumedBottle.fromMap(Map<String, dynamic> map) {
    try {
      return ConsumedBottle(
        id: map['id'] as String?,
        wineId: map['wine_id'] as String,
        date: parseIsoDate(map['drunk_on'] as String),
        occasion: map['occasion'] as String?,
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid consumed bottle: $e', map);
    }
  }

  /// Sort order for [List.sort]: newest date first.
  static int newestFirst(ConsumedBottle a, ConsumedBottle b) =>
      b.date.compareTo(a.date);
}

String? _blankToNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
