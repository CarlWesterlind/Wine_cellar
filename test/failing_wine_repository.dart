import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/consumed_bottle.dart';
import 'package:wine_cellar/models/rack.dart';
import 'package:wine_cellar/models/tasting_note.dart';
import 'package:wine_cellar/models/wine.dart';

/// An in-memory repository that throws [error] from every call while it is
/// set, to test what happens when e.g. the network is down.
class FailingWineRepository extends InMemoryWineRepository {
  FailingWineRepository([super.initial]);

  Object? error;

  void _maybeFail() {
    final error = this.error;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
  }

  @override
  Future<List<Wine>> fetchAll() {
    _maybeFail();
    return super.fetchAll();
  }

  @override
  Future<Wine> add(Wine wine) {
    _maybeFail();
    return super.add(wine);
  }

  @override
  Future<Wine> update(Wine wine) {
    _maybeFail();
    return super.update(wine);
  }

  @override
  Future<void> delete(String id) {
    _maybeFail();
    return super.delete(id);
  }

  @override
  Future<List<TastingNote>> fetchNotes(String wineId) {
    _maybeFail();
    return super.fetchNotes(wineId);
  }

  @override
  Future<TastingNote> addNote(TastingNote note) {
    _maybeFail();
    return super.addNote(note);
  }

  @override
  Future<TastingNote> updateNote(TastingNote note) {
    _maybeFail();
    return super.updateNote(note);
  }

  @override
  Future<void> deleteNote(String id) {
    _maybeFail();
    return super.deleteNote(id);
  }

  @override
  Future<List<ConsumedBottle>> fetchHistory() {
    _maybeFail();
    return super.fetchHistory();
  }

  @override
  Future<ConsumedBottle> addConsumed(ConsumedBottle bottle) {
    _maybeFail();
    return super.addConsumed(bottle);
  }

  @override
  Future<void> deleteConsumed(String id) {
    _maybeFail();
    return super.deleteConsumed(id);
  }

  @override
  Future<List<Rack>> fetchRacks() {
    _maybeFail();
    return super.fetchRacks();
  }

  @override
  Future<Rack> addRack(Rack rack) {
    _maybeFail();
    return super.addRack(rack);
  }

  @override
  Future<Rack> updateRack(Rack rack) {
    _maybeFail();
    return super.updateRack(rack);
  }

  @override
  Future<void> deleteRack(String id) {
    _maybeFail();
    return super.deleteRack(id);
  }
}
