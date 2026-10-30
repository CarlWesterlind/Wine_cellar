import '../models/consumed_bottle.dart';
import '../models/rack.dart';
import '../models/tasting_note.dart';
import '../models/wine.dart';

/// Storage for the signed-in user's wines, their tasting notes and drinking
/// history, and the racks of the cellar map.
abstract interface class WineRepository {
  Future<List<Wine>> fetchAll();

  /// Saves a new wine and returns it with its id set.
  Future<Wine> add(Wine wine);

  Future<Wine> update(Wine wine);

  /// Deletes the wine with all its tasting notes and history.
  Future<void> delete(String id);

  /// The tasting notes of one wine, oldest saved first.
  Future<List<TastingNote>> fetchNotes(String wineId);

  /// Saves a new note and returns it with its id set.
  Future<TastingNote> addNote(TastingNote note);

  Future<TastingNote> updateNote(TastingNote note);

  Future<void> deleteNote(String id);

  /// Every bottle drunk, from all wines.
  Future<List<ConsumedBottle>> fetchHistory();

  /// Saves a new history entry and returns it with its id set.
  Future<ConsumedBottle> addConsumed(ConsumedBottle bottle);

  Future<void> deleteConsumed(String id);

  Future<List<Rack>> fetchRacks();

  /// Saves a new rack and returns it with its id set.
  Future<Rack> addRack(Rack rack);

  Future<Rack> updateRack(Rack rack);

  /// Deletes the rack. Its wines keep their location text.
  Future<void> deleteRack(String id);
}

/// Keeps wines in memory. Used in demo mode and in tests.
class InMemoryWineRepository implements WineRepository {
  InMemoryWineRepository([Iterable<Wine> initial = const []]) {
    for (final wine in initial) {
      _add(wine);
    }
  }

  /// Sample wines with a few tasting notes, for demo mode.
  factory InMemoryWineRepository.demo() {
    final repository = InMemoryWineRepository(sampleWines);
    final barolo = repository._wines.values.first;
    final rioja = repository._wines.values.last;
    for (final rack in [
      Rack(name: 'A', shelves: 4, slotsPerShelf: 6),
      Rack(name: 'B', shelves: 3, slotsPerShelf: 8),
    ]) {
      repository._addRack(rack);
    }
    repository._addConsumed(
      ConsumedBottle(
        wineId: rioja.id!,
        date: DateTime(2025, 12, 24),
        occasion: 'Julafton',
      ),
    );
    for (final note in [
      TastingNote(
        wineId: barolo.id!,
        date: DateTime(2026, 3, 14),
        text: 'Köpt efter provning hos importören. Lovande, men behöver tid.',
      ),
      TastingNote(
        wineId: barolo.id!,
        date: DateTime(2026, 10, 12),
        rating: 4,
        text: 'Körsbär, ros och tjära. Fortfarande stramt – vänta 2–3 år.',
      ),
      TastingNote(
        wineId: rioja.id!,
        date: DateTime(2025, 12, 24),
        rating: 5,
        text: 'Perfekt till julskinkan. Mjuk vanilj och torkad frukt.',
      ),
    ]) {
      repository._addNote(note);
    }
    return repository;
  }

  final _wines = <String, Wine>{};
  final _notes = <String, TastingNote>{};
  final _history = <String, ConsumedBottle>{};
  final _racks = <String, Rack>{};
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
  Future<void> delete(String id) async {
    _wines.remove(id);
    _notes.removeWhere((_, note) => note.wineId == id);
    _history.removeWhere((_, bottle) => bottle.wineId == id);
  }

  @override
  Future<List<TastingNote>> fetchNotes(String wineId) async =>
      _notes.values.where((note) => note.wineId == wineId).toList();

  TastingNote _addNote(TastingNote note) {
    if (!_wines.containsKey(note.wineId)) {
      throw StateError('No wine with id ${note.wineId}');
    }
    final saved = note.withId('${_nextId++}');
    _notes[saved.id!] = saved;
    return saved;
  }

  @override
  Future<TastingNote> addNote(TastingNote note) async => _addNote(note);

  @override
  Future<TastingNote> updateNote(TastingNote note) async {
    if (!_notes.containsKey(note.id)) {
      throw StateError('No tasting note with id ${note.id}');
    }
    _notes[note.id!] = note;
    return note;
  }

  @override
  Future<void> deleteNote(String id) async => _notes.remove(id);

  @override
  Future<List<ConsumedBottle>> fetchHistory() async => _history.values.toList();

  ConsumedBottle _addConsumed(ConsumedBottle bottle) {
    if (!_wines.containsKey(bottle.wineId)) {
      throw StateError('No wine with id ${bottle.wineId}');
    }
    final saved = bottle.withId('${_nextId++}');
    _history[saved.id!] = saved;
    return saved;
  }

  @override
  Future<ConsumedBottle> addConsumed(ConsumedBottle bottle) async =>
      _addConsumed(bottle);

  @override
  Future<void> deleteConsumed(String id) async => _history.remove(id);

  @override
  Future<List<Rack>> fetchRacks() async => _racks.values.toList();

  Rack _addRack(Rack rack) {
    final saved = rack.withId('${_nextId++}');
    _racks[saved.id!] = saved;
    return saved;
  }

  @override
  Future<Rack> addRack(Rack rack) async => _addRack(rack);

  @override
  Future<Rack> updateRack(Rack rack) async {
    if (!_racks.containsKey(rack.id)) {
      throw StateError('No rack with id ${rack.id}');
    }
    _racks[rack.id!] = rack;
    return rack;
  }

  @override
  Future<void> deleteRack(String id) async => _racks.remove(id);
}

final sampleWines = [
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
    purchaseDate: DateTime(2026, 3, 14),
    purchasedFrom: 'Systembolaget',
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
    purchaseDate: DateTime(2019, 11, 2),
    purchasedFrom: 'Vinoteket',
  ),
];
