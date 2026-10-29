import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/photo_storage.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/cellar_controller.dart';

import 'failing_wine_repository.dart';

void main() {
  late InMemoryWineRepository repository;
  late CellarController cellar;

  setUp(() async {
    repository = InMemoryWineRepository([
      Wine(
        name: 'Rioja',
        type: WineType.red,
        quantity: 2,
        price: 100,
        drinkUntil: 2020,
      ),
      Wine(
        name: 'chablis',
        type: WineType.white,
        quantity: 3,
        price: 50,
        drinkFrom: 2024,
      ),
      Wine(name: 'Barolo', type: WineType.red, quantity: 1, drinkFrom: 2030),
    ]);
    cellar = CellarController(
      repository,
      InMemoryPhotoStorage(),
      clock: () => DateTime(2025),
    );
    await cellar.load();
  });

  List<String> names() => cellar.visibleWines.map((w) => w.name).toList();

  test('sorts wines by name, ignoring case', () {
    expect(names(), ['Barolo', 'chablis', 'Rioja']);
  });

  test('sums bottles and value', () {
    expect(cellar.totalBottles, 6);
    expect(cellar.totalValue, 350);
  });

  test('filters by search, type and drinking status together', () {
    cellar.setTypeFilter(WineType.red);
    expect(names(), ['Barolo', 'Rioja']);

    cellar.setStatusFilter(DrinkingStatus.tooEarly);
    expect(names(), ['Barolo']);

    cellar
      ..setTypeFilter(null)
      ..setStatusFilter(null)
      ..setQuery('chab');
    expect(names(), ['chablis']);
  });

  test('save adds new wines and updates existing ones', () async {
    final added = await cellar.save(Wine(name: 'Champagne'));
    expect(added.id, isNotNull);
    expect(names(), contains('Champagne'));

    await cellar.save(added.withQuantity(12));
    expect(cellar.byId(added.id!)!.quantity, 12);
    expect(await repository.fetchAll(), hasLength(4));
  });

  test('drinkOne removes a bottle but never goes below zero', () async {
    final barolo = cellar.visibleWines.first;
    await cellar.drinkOne(barolo);
    final empty = cellar.byId(barolo.id!)!;
    expect(empty.quantity, 0);

    await cellar.drinkOne(empty);
    expect(cellar.byId(barolo.id!)!.quantity, 0);
  });

  test('delete removes the wine', () async {
    final rioja = cellar.visibleWines.last;
    await cellar.delete(rioja);
    expect(names(), ['Barolo', 'chablis']);
    expect(await repository.fetchAll(), hasLength(2));
  });

  group('when the repository fails', () {
    late FailingWineRepository failing;
    late CellarController failingCellar;

    setUp(() async {
      failing = FailingWineRepository([Wine(name: 'Barolo', quantity: 2)]);
      failingCellar = CellarController(failing, InMemoryPhotoStorage());
      await failingCellar.load();
    });

    test('load stores the error instead of throwing', () async {
      failing.error = StateError('offline');
      await failingCellar.load();
      expect(failingCellar.error, isA<StateError>());
      expect(failingCellar.loading, isFalse);

      // Trying again after the problem is gone clears the error.
      failing.error = null;
      await failingCellar.load();
      expect(failingCellar.error, isNull);
      expect(failingCellar.visibleWines, hasLength(1));
    });

    test(
      'save, delete and drinkOne pass the error on and change nothing',
      () async {
        final barolo = failingCellar.visibleWines.single;
        failing.error = StateError('offline');

        await expectLater(
          failingCellar.save(Wine(name: 'New')),
          throwsStateError,
        );
        await expectLater(failingCellar.delete(barolo), throwsStateError);
        await expectLater(failingCellar.drinkOne(barolo), throwsStateError);

        expect(failingCellar.visibleWines.map((w) => w.name), ['Barolo']);
        expect(failingCellar.byId(barolo.id!)!.quantity, 2);
      },
    );
  });

  group('photos', () {
    late InMemoryPhotoStorage photos;
    late FailingWineRepository failing;
    late CellarController photoCellar;
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1]);
    final otherJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 2]);

    setUp(() async {
      photos = InMemoryPhotoStorage();
      failing = FailingWineRepository();
      photoCellar = CellarController(failing, photos);
      await photoCellar.load();
    });

    test('a new photo is stored and linked to the wine', () async {
      final saved = await photoCellar.save(Wine(name: 'X'), newPhoto: jpeg);
      expect(await photos.load(saved.photoPath!), jpeg);
    });

    test('replacing a photo deletes the old one', () async {
      final first = await photoCellar.save(Wine(name: 'X'), newPhoto: jpeg);
      final second = await photoCellar.save(first, newPhoto: otherJpeg);
      expect(second.photoPath, isNot(first.photoPath));
      expect(photos.count, 1);
    });

    test('removing the photo deletes it', () async {
      final saved = await photoCellar.save(Wine(name: 'X'), newPhoto: jpeg);
      await photoCellar.save(
        Wine(id: saved.id, name: 'X'), // No photoPath.
      );
      expect(photos.count, 0);
    });

    test('saving without a new photo keeps the photo', () async {
      final saved = await photoCellar.save(Wine(name: 'X'), newPhoto: jpeg);
      await photoCellar.drinkOne(saved);
      expect(photos.count, 1);
    });

    test('if the wine fails to save, the new photo is removed again', () async {
      failing.error = StateError('offline');
      await expectLater(
        photoCellar.save(Wine(name: 'X'), newPhoto: jpeg),
        throwsStateError,
      );
      expect(photos.count, 0);
    });

    test('deleting a wine deletes its photo', () async {
      final saved = await photoCellar.save(Wine(name: 'X'), newPhoto: jpeg);
      await photoCellar.delete(saved);
      expect(photos.count, 0);
      expect(photoCellar.isEmpty, isTrue);
    });
  });

  test('the visible list is updated when filters change', () {
    final before = cellar.visibleWines;
    expect(identical(before, cellar.visibleWines), isTrue); // Reused.
    cellar.setQuery('rioja');
    expect(cellar.visibleWines.map((w) => w.name), ['Rioja']);
    cellar.clearFilters();
    expect(cellar.visibleWines, hasLength(3));
  });
}
