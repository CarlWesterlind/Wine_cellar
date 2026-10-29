import '../models/wine.dart';

/// Storage for the signed-in user's wines.
abstract interface class WineRepository {
  Future<List<Wine>> fetchAll();

  /// Saves a new wine and returns it with its id set.
  Future<Wine> add(Wine wine);

  Future<Wine> update(Wine wine);

  Future<void> delete(String id);
}

/// Keeps wines in memory. Used in demo mode and in tests.
class InMemoryWineRepository implements WineRepository {
  InMemoryWineRepository([Iterable<Wine> initial = const []]) {
    for (final wine in initial) {
      _add(wine);
    }
  }

  final _wines = <String, Wine>{};
  var _nextId = 1;

  Wine _add(Wine wine) {
    final saved = wine.withId('${_nextId++}');
    _wines[saved.id!] = saved;
    return saved;
  }

  @override
  Future<List<Wine>> fetchAll() async => _wines.values.toList();

  @override
  Future<Wine> add(Wine wine) async => _add(wine);

  @override
  Future<Wine> update(Wine wine) async {
    if (!_wines.containsKey(wine.id)) {
      throw StateError('No wine with id ${wine.id}');
    }
    _wines[wine.id!] = wine;
    return wine;
  }

  @override
  Future<void> delete(String id) async => _wines.remove(id);
}

const demoWines = [
  Wine(
    name: 'Barolo Cannubi',
    producer: 'Paolo Scavino',
    vintage: 2019,
    type: WineType.red,
    country: 'Italia',
    region: 'Piemonte',
    grapes: ['Nebbiolo'],
    quantity: 3,
    price: 650,
    rack: 'A',
    shelf: '2',
    position: '4',
    drinkFrom: 2027,
    drinkUntil: 2040,
  ),
  Wine(
    name: 'Chablis Premier Cru Montée de Tonnerre',
    producer: 'William Fèvre',
    vintage: 2022,
    type: WineType.white,
    country: 'France',
    region: 'Bourgogne',
    grapes: ['Chardonnay'],
    quantity: 6,
    price: 349,
    rack: 'B',
    shelf: '1',
    drinkFrom: 2024,
    drinkUntil: 2032,
  ),
  Wine(
    name: 'Brut Réserve',
    producer: 'Billecart-Salmon',
    type: WineType.sparkling,
    country: 'France',
    region: 'Champagne',
    grapes: ['Pinot Noir', 'Chardonnay', 'Pinot Meunier'],
    quantity: 2,
    price: 499,
    rack: 'C',
  ),
  Wine(
    name: 'Rioja Reserva',
    producer: 'La Rioja Alta',
    vintage: 2012,
    type: WineType.red,
    country: 'España',
    region: 'Rioja',
    grapes: ['Tempranillo'],
    quantity: 1,
    price: 279,
    drinkFrom: 2016,
    drinkUntil: 2024,
  ),
];
