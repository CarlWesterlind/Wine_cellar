import 'package:wine_cellar/data/wine_repository.dart';
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
}
