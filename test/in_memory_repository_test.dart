import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/tasting_note.dart';
import 'package:wine_cellar/models/wine.dart';

void main() {
  test('deleting a wine also deletes its notes', () async {
    final repository = InMemoryWineRepository([
      Wine(name: 'Barolo'),
      Wine(name: 'Rioja'),
    ]);
    final [barolo, rioja] = await repository.fetchAll();
    for (final wine in [barolo, rioja]) {
      await repository.addNote(
        TastingNote(wineId: wine.id!, date: DateTime(2026, 1, 1), text: 'x'),
      );
    }

    await repository.delete(barolo.id!);

    expect(await repository.fetchNotes(barolo.id!), isEmpty);
    expect(await repository.fetchNotes(rioja.id!), hasLength(1));
  });

  test('a note cannot be added to a wine that does not exist', () async {
    final repository = InMemoryWineRepository();
    await expectLater(
      repository.addNote(
        TastingNote(wineId: 'nope', date: DateTime(2026, 1, 1), text: 'x'),
      ),
      throwsStateError,
    );
  });

  test('updating a note that does not exist fails', () async {
    final repository = InMemoryWineRepository([Wine(name: 'Barolo')]);
    final wine = (await repository.fetchAll()).single;
    await expectLater(
      repository.updateNote(
        TastingNote(
          id: 'nope',
          wineId: wine.id!,
          date: DateTime(2026, 1, 1),
          text: 'x',
        ),
      ),
      throwsStateError,
    );
  });

  test('wines and notes never share an id', () async {
    final repository = InMemoryWineRepository([Wine(name: 'Barolo')]);
    final wine = (await repository.fetchAll()).single;
    final note = await repository.addNote(
      TastingNote(wineId: wine.id!, date: DateTime(2026, 1, 1), text: 'x'),
    );
    final second = await repository.add(Wine(name: 'Rioja'));
    expect({wine.id, note.id, second.id}, hasLength(3));
  });

  test('the demo cellar has sample wines with notes', () async {
    final repository = InMemoryWineRepository.demo();
    final wines = await repository.fetchAll();
    expect(wines, hasLength(4));
    final barolo = wines.firstWhere((w) => w.name == 'Barolo Cannubi');
    expect(await repository.fetchNotes(barolo.id!), hasLength(2));
    expect(barolo.purchasedFrom, 'Systembolaget');
  });
}
