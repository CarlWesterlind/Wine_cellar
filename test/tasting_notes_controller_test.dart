import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/photo_storage.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/tasting_note.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/cellar_controller.dart';
import 'package:wine_cellar/state/tasting_notes_controller.dart';

import 'failing_wine_repository.dart';

void main() {
  late FailingWineRepository repository;
  late String wineId;
  late TastingNotesController notes;

  TastingNote note(String text, DateTime date, {int? rating}) =>
      TastingNote(wineId: wineId, date: date, rating: rating, text: text);

  setUp(() async {
    repository = FailingWineRepository([Wine(name: 'Barolo')]);
    wineId = (await repository.fetchAll()).single.id!;
    notes = TastingNotesController(repository, wineId);
    await notes.load();
  });

  List<String> texts() => notes.notes.map((n) => n.text).toList();

  test('notes are sorted newest date first', () async {
    await notes.save(note('middle', DateTime(2026, 2, 1)));
    await notes.save(note('oldest', DateTime(2025, 1, 1)));
    await notes.save(note('newest', DateTime(2026, 9, 1)));
    expect(texts(), ['newest', 'middle', 'oldest']);
  });

  test('notes from the same day show the last saved first', () async {
    final day = DateTime(2026, 3, 14);
    for (final text in ['first', 'second', 'third', 'fourth', 'fifth']) {
      await notes.save(note(text, day));
    }
    expect(texts(), ['fifth', 'fourth', 'third', 'second', 'first']);
  });

  test('save updates an existing note in place', () async {
    await notes.save(note('old text', DateTime(2026, 3, 14)));
    final saved = notes.notes.single;
    await notes.save(
      TastingNote(
        id: saved.id,
        wineId: wineId,
        date: saved.date,
        rating: 5,
        text: 'new text',
      ),
    );
    expect(texts(), ['new text']);
    expect(notes.notes.single.rating, 5);
    expect(await repository.fetchNotes(wineId), hasLength(1));
  });

  test('delete removes the note', () async {
    await notes.save(note('keep', DateTime(2026, 1, 1)));
    await notes.save(note('remove', DateTime(2026, 1, 2)));
    await notes.delete(notes.notes.first.id!);
    expect(texts(), ['keep']);
  });

  test('a note for another wine is rejected with ArgumentError', () async {
    final other = TastingNote(
      wineId: 'other',
      date: DateTime(2026, 1, 1),
      text: 'x',
    );
    await expectLater(notes.save(other), throwsArgumentError);
  });

  test('only this wine\'s notes are loaded', () async {
    final otherWine = await repository.add(Wine(name: 'Rioja'));
    await repository.addNote(
      TastingNote(wineId: otherWine.id!, date: DateTime(2026, 1, 1), text: 'x'),
    );
    await notes.load();
    expect(notes.notes, isEmpty);
  });

  group('when the repository fails', () {
    test('load stores the error and can be retried', () async {
      repository.error = StateError('offline');
      await notes.load();
      expect(notes.error, isA<StateError>());
      expect(notes.loading, isFalse);

      repository.error = null;
      await notes.load();
      expect(notes.error, isNull);
    });

    test('save and delete pass the error on and change nothing', () async {
      await notes.save(note('keep', DateTime(2026, 1, 1)));
      repository.error = StateError('offline');

      await expectLater(
        notes.save(note('new', DateTime(2026, 1, 2))),
        throwsStateError,
      );
      await expectLater(notes.delete(notes.notes.single.id!), throwsStateError);
      expect(texts(), ['keep']);
    });
  });

  group('closing a screen while it is loading does not throw', () {
    test('tasting notes', () async {
      final slow = _SlowRepository();
      final controller = TastingNotesController(slow, 'w1');
      final loading = controller.load();
      controller.dispose();
      slow.finish();
      await expectLater(loading, completes);
    });

    test('cellar', () async {
      final slow = _SlowRepository();
      final controller = CellarController(slow, InMemoryPhotoStorage());
      final loading = controller.load();
      controller.dispose();
      slow.finish();
      await expectLater(loading, completes);
    });
  });
}

/// Loads only when [finish] is called.
class _SlowRepository extends InMemoryWineRepository {
  final _done = Completer<void>();

  void finish() => _done.complete();

  @override
  Future<List<Wine>> fetchAll() async {
    await _done.future;
    return super.fetchAll();
  }

  @override
  Future<List<TastingNote>> fetchNotes(String wineId) async {
    await _done.future;
    return super.fetchNotes(wineId);
  }
}
