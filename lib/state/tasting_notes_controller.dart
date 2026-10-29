import 'package:flutter/foundation.dart';

import '../data/wine_repository.dart';
import '../errors/error_messages.dart';
import '../models/tasting_note.dart';

/// Holds the tasting notes of one wine.
class TastingNotesController extends ChangeNotifier {
  TastingNotesController(this._repository, this.wineId);

  final WineRepository _repository;
  final String wineId;

  /// In the order they were saved.
  List<TastingNote> _notes = const [];
  bool _loading = false;
  Object? _error;
  bool _disposed = false;

  bool get loading => _loading;
  Object? get error => _error;

  /// Newest date first. Notes from the same day: last saved first.
  List<TastingNote> get notes {
    final sorted = _notes.reversed.toList();
    mergeSort(sorted, compare: TastingNote.newestFirst); // Stable sort.
    return sorted;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notes = await _repository.fetchNotes(wineId);
    } catch (error, stack) {
      logError(error, stack);
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Adds [note] if it has no id yet, otherwise updates it.
  Future<void> save(TastingNote note) async {
    if (note.wineId != wineId) {
      throw ArgumentError.value(note.wineId, 'note.wineId', 'wrong wine');
    }
    if (note.id == null) {
      final saved = await _repository.addNote(note);
      _notes = [..._notes, saved];
    } else {
      final saved = await _repository.updateNote(note);
      _notes = [for (final n in _notes) n.id == saved.id ? saved : n];
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repository.deleteNote(id);
    _notes = _notes.where((n) => n.id != id).toList();
    notifyListeners();
  }

  // A load can finish after the screen is closed; don't notify then.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
