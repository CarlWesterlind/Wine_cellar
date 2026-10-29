import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/models/tasting_note.dart';

void main() {
  TastingNote note({int? rating, String text = 'Nice', DateTime? date}) =>
      TastingNote(
        wineId: 'w1',
        date: date ?? DateTime(2026, 3, 14),
        rating: rating,
        text: text,
      );

  group('constructor throws ArgumentError for impossible values', () {
    test('empty or blank text', () {
      expect(() => note(text: ''), throwsArgumentError);
      expect(() => note(text: '  \n '), throwsArgumentError);
    });

    test('rating outside 1–5', () {
      expect(() => note(rating: 0), throwsArgumentError);
      expect(() => note(rating: 6), throwsArgumentError);
      expect(() => note(rating: -1), throwsArgumentError);
    });

    test('accepts no rating and the edge ratings', () {
      expect(() => note(), returnsNormally);
      expect(() => note(rating: 1), returnsNormally);
      expect(() => note(rating: 5), returnsNormally);
    });
  });

  test('the date has no time of day', () {
    expect(
      note(date: DateTime(2026, 3, 14, 18, 30)).date,
      DateTime(2026, 3, 14),
    );
  });

  test('toMap and fromMap round-trip', () {
    final original = note(rating: 4).withId('n1');
    final copy = TastingNote.fromMap({...original.toMap(), 'id': 'n1'});
    expect(copy.toMap(), original.toMap());
    expect(copy.id, 'n1');
    expect(original.toMap()['tasted_on'], '2026-03-14');
  });

  group('fromMap throws FormatException for bad rows', () {
    final valid = {
      'id': 'n1',
      'wine_id': 'w1',
      'tasted_on': '2026-03-14',
      'rating': 3,
      'text': 'Nice',
    };

    for (final MapEntry(key: description, value: change) in {
      'missing wine id': {'wine_id': null},
      'missing date': {'tasted_on': null},
      'invalid date': {'tasted_on': '2026-02-31'},
      'rating out of range': {'rating': 9},
      'rating of the wrong type': {'rating': 'good'},
      'empty text': {'text': ''},
    }.entries) {
      test(description, () {
        expect(
          () => TastingNote.fromMap({...valid, ...change}),
          throwsFormatException,
        );
      });
    }

    test('the valid row itself works', () {
      expect(() => TastingNote.fromMap(valid), returnsNormally);
    });
  });
}
