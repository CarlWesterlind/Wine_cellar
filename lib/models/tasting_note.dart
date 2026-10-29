import 'dates.dart';

/// A dated note about a wine, e.g. from opening a bottle.
class TastingNote {
  /// Throws [ArgumentError] for an empty text or a rating outside 1–5.
  TastingNote({
    this.id,
    required this.wineId,
    required DateTime date,
    this.rating,
    required this.text,
  }) : date = dateOnly(date) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    if (rating != null && (rating! < minRating || rating! > maxRating)) {
      throw ArgumentError.value(
        rating,
        'rating',
        'must be between $minRating and $maxRating',
      );
    }
  }

  static const minRating = 1;
  static const maxRating = 5;

  /// Null until the note has been saved.
  final String? id;
  final String wineId;

  /// The day of the note, without time of day.
  final DateTime date;

  /// Stars from [minRating] to [maxRating], or null if not rated.
  final int? rating;
  final String text;

  TastingNote withId(String id) => TastingNote(
    id: id,
    wineId: wineId,
    date: date,
    rating: rating,
    text: text,
  );

  /// Columns of the `tasting_notes` table. `id` and `user_id` are set by the
  /// database.
  Map<String, dynamic> toMap() => {
    'wine_id': wineId,
    'tasted_on': toIsoDate(date),
    'rating': rating,
    'text': text,
  };

  /// Throws [FormatException] for rows with missing or invalid values.
  factory TastingNote.fromMap(Map<String, dynamic> map) {
    try {
      return TastingNote(
        id: map['id'] as String?,
        wineId: map['wine_id'] as String,
        date: parseIsoDate(map['tasted_on'] as String),
        rating: map['rating'] as int?,
        text: map['text'] as String,
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid tasting note: $e', map);
    } on ArgumentError catch (e) {
      throw FormatException('Invalid tasting note: ${e.message}', map);
    }
  }

  /// Sort order for [List.sort]: newest date first.
  static int newestFirst(TastingNote a, TastingNote b) =>
      b.date.compareTo(a.date);
}
