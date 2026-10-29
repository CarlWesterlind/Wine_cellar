import 'package:flutter/foundation.dart';

import '../data/wine_repository.dart';
import '../models/tasting_note.dart';
import 'loading_notifier.dart';

/// Holds the tasting notes of one wine.
class TastingNotesController extends LoadingNotifier {
  TastingNotesController(this._repository, this.wineId);

  final WineRepository _repository;
  final String wineId;

  /// In the order they were saved.
  List<TastingNote> _saved = const [];

  /// [_saved] sorted for display.
  List<TastingNote> _sorted = const [];

  /// Newest date first. Notes from the same day: last saved first.
  List<TastingNote> get notes => _sorted;

  void _setNotes(List<TastingNote> notes) {
    _saved = notes;
    final sorted = notes.reversed.toList();
    mergeSort(sorted, compare: TastingNote.newestFirst); // Keeps ties in order.
    _sorted = List.unmodifiable(sorted);
  }

  Future<void> load() =>
      runLoad(() async => _setNotes(await _repository.fetchNotes(wineId)));

  /// Adds [note] if it has no id yet, otherwise updates it.
  Future<void> save(TastingNote note) async {
    if (note.wineId != wineId) {
      throw ArgumentError.value(note.wineId, 'note.wineId', 'wrong wine');
    }
    if (note.id == null) {
      final added = await _repository.addNote(note);
      _setNotes([..._saved, added]);
    } else {
      final updated = await _repository.updateNote(note);
      _setNotes([for (final n in _saved) n.id == updated.id ? updated : n]);
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repository.deleteNote(id);
    _setNotes(_saved.where((n) => n.id != id).toList());
    notifyListeners();
  }
}
