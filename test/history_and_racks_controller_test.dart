import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/photo_storage.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/rack.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/cellar_controller.dart';

import 'failing_wine_repository.dart';

/// Fails only when a wine is updated, after the history entry is saved.
class _FailingUpdate extends InMemoryWineRepository {
  _FailingUpdate(super.initial);

  @override
  Future<Wine> update(Wine wine) async => throw StateError('offline');
}

void main() {
  late InMemoryWineRepository repository;
  late CellarController cellar;
  late Wine barolo;

  setUp(() async {
    repository = InMemoryWineRepository([
      Wine(name: 'Barolo', quantity: 3, drinkUntil: 2026),
      Wine(name: 'Chablis', type: WineType.white, quantity: 1),
    ]);
    cellar = CellarController(
      repository,
      InMemoryPhotoStorage(),
      clock: () => DateTime(2026, 10, 30, 20),
    );
    await cellar.load();
    barolo = cellar.allWines.first;
  });

  group('drinking history', () {
    test('drinking saves the date and occasion and lowers the stock', () async {
      final bottle = await cellar.drinkOne(barolo, occasion: 'Friday');

      expect(bottle.date, DateTime(2026, 10, 30));
      expect(bottle.occasion, 'Friday');
      expect(cellar.byId(barolo.id!)!.quantity, 2);
      expect(cellar.history, [bottle]);
      expect(await repository.fetchHistory(), hasLength(1));
    });

    test(
      'is sorted newest first; same day shows the last drunk first',
      () async {
        final old = await cellar.drinkOne(barolo, date: DateTime(2024, 1, 1));
        final first = await cellar.drinkOne(cellar.byId(barolo.id!)!);
        final second = await cellar.drinkOne(cellar.allWines.last);
        expect(cellar.history, [second, first, old]);

        // The same order after loading again.
        await cellar.load();
        expect(cellar.history.map((b) => b.id), [second.id, first.id, old.id]);
      },
    );

    test('historyOf gives one wine', () async {
      await cellar.drinkOne(barolo);
      await cellar.drinkOne(cellar.allWines.last);
      expect(cellar.historyOf(barolo.id!), hasLength(1));
    });

    test('undo removes the entry and puts the bottle back', () async {
      final bottle = await cellar.drinkOne(barolo);
      await cellar.undoDrink(bottle);
      expect(cellar.history, isEmpty);
      expect(cellar.byId(barolo.id!)!.quantity, 3);
      expect(await repository.fetchHistory(), isEmpty);
    });

    test('a failed stock update removes the history entry again', () async {
      final failing = _FailingUpdate([Wine(name: 'Barolo', quantity: 2)]);
      final failingCellar = CellarController(failing, InMemoryPhotoStorage());
      await failingCellar.load();

      await expectLater(
        failingCellar.drinkOne(failingCellar.allWines.single),
        throwsStateError,
      );
      expect(failingCellar.history, isEmpty);
      expect(await failing.fetchHistory(), isEmpty);
      expect(failingCellar.allWines.single.quantity, 2);
    });

    test('deleting a wine deletes its history', () async {
      await cellar.drinkOne(barolo);
      await cellar.delete(cellar.byId(barolo.id!)!);
      expect(await repository.fetchHistory(), isEmpty);
    });

    test('statistics follow the stock', () async {
      expect(cellar.stats.bottles, 4);
      await cellar.drinkOne(barolo);
      expect(cellar.stats.bottles, 3);
      expect(cellar.stats.lastYear.single.name, 'Barolo');
    });
  });

  group('racks', () {
    test('are kept sorted by name', () async {
      await cellar.saveRack(Rack(name: 'b', shelves: 2, slotsPerShelf: 2));
      await cellar.saveRack(Rack(name: 'A', shelves: 2, slotsPerShelf: 2));
      expect(cellar.racks.map((r) => r.name), ['A', 'b']);

      await cellar.load();
      expect(cellar.racks.map((r) => r.name), ['A', 'b']);
    });

    test('can be changed and deleted', () async {
      final rack = await cellar.saveRack(
        Rack(name: 'A', shelves: 2, slotsPerShelf: 2),
      );
      await cellar.saveRack(
        Rack(id: rack.id, name: 'A', shelves: 5, slotsPerShelf: 2),
      );
      expect(cellar.racks.single.shelves, 5);

      await cellar.deleteRack(cellar.racks.single);
      expect(cellar.racks, isEmpty);
      expect(await repository.fetchRacks(), isEmpty);
    });

    test('place moves a wine into a rack', () async {
      final rack = await cellar.saveRack(
        Rack(name: 'A', shelves: 2, slotsPerShelf: 3),
      );
      await cellar.place(barolo, rack, shelf: 2, slot: 3);
      final placed = cellar.byId(barolo.id!)!;
      expect((placed.rack, placed.shelf, placed.position), ('A', '2', '3'));
      expect(rack.placeOf(placed), (shelf: 2, slot: 3));
    });

    test('renaming a rack keeps its wines in it', () async {
      final rack = await cellar.saveRack(
        Rack(name: 'A', shelves: 2, slotsPerShelf: 3),
      );
      await cellar.place(barolo, rack, shelf: 1, slot: 2);
      await cellar.saveRack(
        Rack(id: rack.id, name: 'Kitchen', shelves: 2, slotsPerShelf: 3),
      );

      final moved = cellar.byId(barolo.id!)!;
      expect((moved.rack, moved.shelf, moved.position), ('Kitchen', '1', '2'));
      expect((await repository.fetchAll()).first.rack, 'Kitchen');
      // Wines in other racks are left alone.
      expect(cellar.allWines.last.rack, isNull);
    });

    test('a failed load keeps the error for a retry', () async {
      final failing = FailingWineRepository()..error = StateError('offline');
      final failingCellar = CellarController(failing, InMemoryPhotoStorage());
      await failingCellar.load();
      expect(failingCellar.error, isStateError);
      expect(failingCellar.racks, isEmpty);
    });
  });
}
