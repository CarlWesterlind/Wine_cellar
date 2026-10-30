import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/models/cellar_stats.dart';
import 'package:wine_cellar/models/consumed_bottle.dart';
import 'package:wine_cellar/models/csv.dart';
import 'package:wine_cellar/models/rack.dart';
import 'package:wine_cellar/models/wine.dart';

void main() {
  group('ConsumedBottle', () {
    test('keeps only the date, and a blank occasion becomes null', () {
      final bottle = ConsumedBottle(
        wineId: 'w',
        date: DateTime(2026, 10, 30, 21, 15),
        occasion: '   ',
      );
      expect(bottle.date, DateTime(2026, 10, 30));
      expect(bottle.occasion, isNull);
    });

    test('survives a trip to the database and back', () {
      final bottle = ConsumedBottle(
        wineId: 'w',
        date: DateTime(2025, 12, 24),
        occasion: ' Christmas Eve ',
      );
      final back = ConsumedBottle.fromMap({...bottle.toMap(), 'id': '7'});
      expect(back.id, '7');
      expect(back.wineId, 'w');
      expect(back.date, DateTime(2025, 12, 24));
      expect(back.occasion, 'Christmas Eve');
    });

    test('a broken row throws FormatException, not a TypeError', () {
      expect(
        () => ConsumedBottle.fromMap({'wine_id': 'w'}),
        throwsFormatException,
      );
      expect(
        () =>
            ConsumedBottle.fromMap({'wine_id': 'w', 'drunk_on': '2026-02-30'}),
        throwsFormatException,
      );
    });
  });

  group('Rack', () {
    test('rejects an empty name and sizes outside 1–30', () {
      expect(
        () => Rack(name: ' ', shelves: 2, slotsPerShelf: 2),
        throwsArgumentError,
      );
      expect(
        () => Rack(name: 'A', shelves: 0, slotsPerShelf: 2),
        throwsArgumentError,
      );
      expect(
        () => Rack(name: 'A', shelves: 2, slotsPerShelf: 31),
        throwsArgumentError,
      );
      expect(Rack(name: 'A', shelves: 30, slotsPerShelf: 1).capacity, 30);
    });

    final rack = Rack(name: ' A ', shelves: 3, slotsPerShelf: 4);

    Wine wineAt(String? rack, String? shelf, String? position) =>
        Wine(name: 'X', rack: rack, shelf: shelf, position: position);

    test('finds wines by rack name regardless of case and spaces', () {
      expect(rack.name, 'A');
      expect(rack.holds(wineAt('a ', null, null)), isTrue);
      expect(rack.holds(wineAt('B', null, null)), isFalse);
      expect(rack.holds(wineAt(null, '1', '1')), isFalse);
    });

    test('places a wine only at numbers inside the grid', () {
      expect(rack.placeOf(wineAt('A', '2', ' 4')), (shelf: 2, slot: 4));
      expect(rack.placeOf(wineAt('A', '4', '1')), isNull); // no shelf 4
      expect(rack.placeOf(wineAt('A', '1', '5')), isNull); // no slot 5
      expect(rack.placeOf(wineAt('A', '0', '1')), isNull);
      expect(rack.placeOf(wineAt('A', 'top', '1')), isNull);
      expect(rack.placeOf(wineAt('A', '1', null)), isNull);
      expect(rack.placeOf(wineAt('B', '1', '1')), isNull);
    });

    test('survives a trip to the database and back', () {
      final back = Rack.fromMap({...rack.toMap(), 'id': '3'});
      expect(back.id, '3');
      expect(back.name, 'A');
      expect(back.shelves, 3);
      expect(back.slotsPerShelf, 4);
    });

    test('a broken row throws FormatException', () {
      expect(() => Rack.fromMap({'name': 'A'}), throwsFormatException);
      expect(
        () => Rack.fromMap({'name': 'A', 'shelves': 99, 'slots_per_shelf': 1}),
        throwsFormatException,
      );
    });
  });

  group('CellarStats', () {
    final stats = CellarStats([
      Wine(
        name: 'Barolo',
        quantity: 3,
        price: 100,
        country: 'Italia',
        grapes: ['Nebbiolo'],
        drinkFrom: 2030,
      ),
      Wine(
        name: 'Chianti',
        quantity: 2,
        country: 'italia ',
        grapes: ['Sangiovese', 'Merlot'],
        drinkUntil: 2026,
      ),
      Wine(
        name: 'Chablis',
        type: WineType.white,
        quantity: 1,
        price: 250,
        country: 'France',
        grapes: ['Chardonnay'],
      ),
      // Empty bottles don't count anywhere.
      Wine(name: 'Gone', quantity: 0, price: 999, country: 'Spain'),
    ], year: 2026);

    test('counts bottles, wines and value of the stock', () {
      expect(stats.bottles, 6);
      expect(stats.wines, 3);
      expect(stats.value, 550);
      // Only bottles with a price: (300 + 250) / 4.
      expect(stats.averagePrice, 137.5);
    });

    test('has no average price when no bottle has a price', () {
      expect(CellarStats([Wine(name: 'X')], year: 2026).averagePrice, isNull);
      expect(CellarStats([], year: 2026).bottles, 0);
    });

    test('groups bottles by type, country, grape and status', () {
      expect(stats.byType[WineType.red], 5);
      expect(stats.byType[WineType.white], 1);
      // "Italia" and "italia " are the same country.
      expect(stats.byCountry.sorted.map((e) => (e.key, e.value)), [
        ('Italia', 5),
        ('France', 1),
      ]);
      // A blend counts for each grape.
      expect(stats.byGrape['Merlot'], 2);
      expect(stats.byStatus[DrinkingStatus.tooEarly], 3);
      expect(stats.byStatus[DrinkingStatus.ready], 2);
      expect(stats.byStatus[DrinkingStatus.unknown], 1);
    });

    test('lists wines whose window ends this year', () {
      expect(stats.lastYear.map((w) => w.name), ['Chianti']);
    });

    test('top folds the rest into one number', () {
      final tally = NameTally()
        ..addName('A', 1)
        ..addName('B', 5)
        ..addName('C', 1)
        ..addName('D', 2)
        ..addName('', 9);
      final (top, rest) = tally.top(2);
      expect(top.map((e) => e.key), ['B', 'D']);
      expect(rest, 2);
      // Ties keep the order they were added in.
      expect(tally.sorted.map((e) => e.key), ['B', 'D', 'A', 'C']);
      expect(tally.top(10).$2, 0);
    });
  });

  group('toCsv', () {
    test('separates with semicolons and lines with CRLF', () {
      expect(
        toCsv([
          ['a', 'b'],
          ['1', '2'],
        ]),
        'a;b\r\n1;2',
      );
    });

    test('quotes cells with the separator, quotes, line breaks or edges', () {
      expect(
        toCsv([
          ['a;b', 'say "hi"', 'two\nlines', ' pad', 'x,y'],
        ]),
        '"a;b";"say ""hi""";"two\nlines";" pad";x,y',
      );
    });

    test('stops spreadsheet formulas from running', () {
      expect(
        toCsv([
          ['=HYPERLINK("x")', '+1', '@SUM', 'Brut'],
        ]),
        '"\'=HYPERLINK(""x"")";\'+1;\'@SUM;Brut',
      );
    });
  });
}
