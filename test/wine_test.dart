import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/models/wine.dart';

void main() {
  group('drinkingStatus', () {
    const wine = Wine(name: 'Test', drinkFrom: 2025, drinkUntil: 2030);

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
      expect(
        const Wine(name: 'X').drinkingStatus(2025),
        DrinkingStatus.unknown,
      );
    });

    test('handles an open-ended window', () {
      const fromOnly = Wine(name: 'X', drinkFrom: 2030);
      expect(fromOnly.drinkingStatus(2029), DrinkingStatus.tooEarly);
      expect(fromOnly.drinkingStatus(2050), DrinkingStatus.ready);
      const untilOnly = Wine(name: 'X', drinkUntil: 2020);
      expect(untilOnly.drinkingStatus(2000), DrinkingStatus.ready);
      expect(untilOnly.drinkingStatus(2021), DrinkingStatus.pastPeak);
    });
  });

  test('toMap and fromMap round-trip every field', () {
    const wine = Wine(
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
      notes: 'Decant',
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
    const wine = Wine(
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
}
