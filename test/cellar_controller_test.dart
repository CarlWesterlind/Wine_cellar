import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/cellar_controller.dart';

void main() {
  late InMemoryWineRepository repository;
  late CellarController cellar;

  setUp(() async {
    repository = InMemoryWineRepository(const [
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
    cellar = CellarController(repository, clock: () => DateTime(2025));
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
    final added = await cellar.save(const Wine(name: 'Champagne'));
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
    await cellar.delete(rioja.id!);
    expect(names(), ['Barolo', 'chablis']);
    expect(await repository.fetchAll(), hasLength(2));
  });
}
