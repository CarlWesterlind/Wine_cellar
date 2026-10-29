import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/models/wine.dart';

void main() {
  group('drinkingStatus', () {
    final wine = Wine(name: 'Test', drinkFrom: 2025, drinkUntil: 2030);

    test('is too early before the window', () {
      expect(wine.drinkingStatus(2024), DrinkingStatus.tooEarly);
    });

    test('is ready inside the window, including both ends', () {
      expect(wine.drinkingStatus(2025), DrinkingStatus.ready);
      expect(wine.drinkingStatus(2030), DrinkingStatus.ready);
    });

    test('is past peak after the window', () {
      expect(wine.drinkingStatus(2031), DrinkingStatus.pastPeak);
    });

    test('is unknown without a window', () {
      expect(Wine(name: 'X').drinkingStatus(2025), DrinkingStatus.unknown);
    });

    test('handles an open-ended window', () {
      final fromOnly = Wine(name: 'X', drinkFrom: 2030);
      expect(fromOnly.drinkingStatus(2029), DrinkingStatus.tooEarly);
      expect(fromOnly.drinkingStatus(2050), DrinkingStatus.ready);
      final untilOnly = Wine(name: 'X', drinkUntil: 2020);
      expect(untilOnly.drinkingStatus(2000), DrinkingStatus.ready);
      expect(untilOnly.drinkingStatus(2021), DrinkingStatus.pastPeak);
    });
  });

  test('toMap and fromMap round-trip every field', () {
    final wine = Wine(
      id: 'abc',
      name: 'Barolo',
      producer: 'Scavino',
      vintage: 2019,
      type: WineType.rose,
      country: 'Italia',
      region: 'Piemonte',
      grapes: ['Nebbiolo'],
      quantity: 3,
      price: 650.5,
      rack: 'A',
      shelf: '2',
      position: '4',
      drinkFrom: 2027,
      drinkUntil: 2040,
      purchaseDate: DateTime(2026, 3, 14),
      purchasedFrom: 'Systembolaget',
    );
    final copy = Wine.fromMap({...wine.toMap(), 'id': 'abc'});
    expect(copy.toMap(), wine.toMap());
    expect(copy.id, 'abc');
  });

  test('fromMap reads integer prices from the database', () {
    final wine = Wine.fromMap({'id': '1', 'name': 'X', 'price': 100});
    expect(wine.price, 100.0);
  });

  test('matchesSearch looks in name, producer, region, country and grapes', () {
    final wine = Wine(
      name: 'Barolo',
      producer: 'Scavino',
      region: 'Piemonte',
      grapes: ['Nebbiolo'],
    );
    expect(wine.matchesSearch('barolo'), isTrue);
    expect(wine.matchesSearch('SCAV'), isTrue);
    expect(wine.matchesSearch('piemonte'), isTrue);
    expect(wine.matchesSearch('nebb'), isTrue);
    expect(wine.matchesSearch('rioja'), isFalse);
    expect(wine.matchesSearch('  '), isTrue);
  });

  group('constructor throws ArgumentError for impossible values', () {
    test('empty or blank name', () {
      expect(() => Wine(name: ''), throwsArgumentError);
      expect(() => Wine(name: '   '), throwsArgumentError);
    });

    test('negative quantity', () {
      expect(() => Wine(name: 'X', quantity: -1), throwsArgumentError);
    });

    test('negative price', () {
      expect(() => Wine(name: 'X', price: -0.5), throwsArgumentError);
    });

    test('drinking window that ends before it starts', () {
      expect(
        () => Wine(name: 'X', drinkFrom: 2030, drinkUntil: 2025),
        throwsArgumentError,
      );
    });

    test('accepts the edge cases that are allowed', () {
      expect(
        () => Wine(
          name: 'X',
          quantity: 0,
          price: 0,
          drinkFrom: 2030,
          drinkUntil: 2030,
        ),
        returnsNormally,
      );
    });

    test('withQuantity also checks the new value', () {
      expect(() => Wine(name: 'X').withQuantity(-1), throwsArgumentError);
    });
  });

  group('fromMap throws FormatException for bad database rows', () {
    test('missing name', () {
      expect(() => Wine.fromMap({'id': '1'}), throwsFormatException);
    });

    test('value of the wrong type', () {
      expect(
        () => Wine.fromMap({'id': '1', 'name': 'X', 'quantity': 'many'}),
        throwsFormatException,
      );
    });

    test('impossible value', () {
      expect(
        () => Wine.fromMap({'id': '1', 'name': 'X', 'quantity': -3}),
        throwsFormatException,
      );
    });

    test('unknown wine type falls back to red instead of failing', () {
      final wine = Wine.fromMap({'id': '1', 'name': 'X', 'type': 'orange'});
      expect(wine.type, WineType.red);
    });
  });

  group('purchase info', () {
    test('the purchase date has no time of day', () {
      final wine = Wine(name: 'X', purchaseDate: DateTime(2026, 3, 14, 15, 45));
      expect(wine.purchaseDate, DateTime(2026, 3, 14));
      expect(wine.toMap()['purchase_date'], '2026-03-14');
    });

    test('withQuantity and withId keep the purchase info', () {
      final wine = Wine(
        name: 'X',
        purchaseDate: DateTime(2026, 3, 14),
        purchasedFrom: 'Systembolaget',
      );
      for (final copy in [wine.withQuantity(5), wine.withId('9')]) {
        expect(copy.purchaseDate, DateTime(2026, 3, 14));
        expect(copy.purchasedFrom, 'Systembolaget');
      }
    });

    test('fromMap rejects an invalid purchase date', () {
      expect(
        () => Wine.fromMap({'id': '1', 'name': 'X', 'purchase_date': '14/3'}),
        throwsFormatException,
      );
    });

    test('search finds wines by the shop they were bought from', () {
      final wine = Wine(name: 'X', purchasedFrom: 'Vinoteket');
      expect(wine.matchesSearch('vinotek'), isTrue);
    });
  });
}
