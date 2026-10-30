import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/l10n/app_localizations.dart';
import 'package:wine_cellar/models/rack.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/screens/export_cellar.dart';

import 'helpers.dart';

void main() {
  late InMemoryWineRepository repository;

  setUp(() {
    repository = InMemoryWineRepository([
      Wine(
        name: 'Barolo',
        quantity: 3,
        price: 650,
        country: 'Italia',
        grapes: ['Nebbiolo'],
      ),
      Wine(
        name: 'Chablis',
        type: WineType.white,
        quantity: 1,
        price: 249.5,
        country: 'France',
      ),
    ]);
  });

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('drinking a bottle', () {
    testWidgets('saves occasion and rating, and shows up in the history', (
      tester,
    ) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Drink a bottle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Occasion or company'),
        'Friday with Anna',
      );
      await tester.tap(find.byTooltip('4 stars'));
      await tester.tap(find.widgetWithText(FilledButton, 'Drink'));
      await tester.pumpAndSettle();

      expect(find.text('2 bottles'), findsOneWidget);
      expect(find.text('One bottle of Barolo drunk'), findsOneWidget);
      expect(find.text('Drunk 1 bottle'), findsOneWidget);
      expect(find.textContaining('Friday with Anna'), findsWidgets);
      // The rating became a tasting note, with the occasion as its text.
      final notes = await repository.fetchNotes(
        (await repository.fetchAll()).first.id!,
      );
      expect(notes.single.rating, 4);
      expect(notes.single.text, 'Friday with Anna');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await openTab(tester, 'History');
      expect(find.text('Barolo'), findsOneWidget);
      expect(find.textContaining('Friday with Anna'), findsOneWidget);
    });

    testWidgets('cancelling the sheet drinks nothing', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drink a bottle'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // Outside the sheet.
      await tester.pumpAndSettle();

      expect(find.text('3 bottles'), findsOneWidget);
      expect(await repository.fetchHistory(), isEmpty);
    });

    testWidgets('undo puts the bottle back', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();
      await drinkABottle(tester);
      expect(find.text('2 bottles'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('3 bottles'), findsOneWidget);
      expect(find.text('Drunk 1 bottle'), findsNothing);
      expect(await repository.fetchHistory(), isEmpty);
    });
  });

  group('history', () {
    testWidgets('explains itself while empty', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'History');
      expect(find.text('No bottles drunk yet'), findsOneWidget);
    });

    testWidgets('a bottle can be put back after confirming', (tester) async {
      final wine = (await repository.fetchAll()).last;
      await repository.update(wine.withQuantity(0));
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Chablis'));
      await tester.pumpAndSettle();
      expect(find.text('0 bottles'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Drink from Barolo, then put it back from the history.
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();
      await drinkABottle(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await openTab(tester, 'History');

      await tester.tap(find.byTooltip('Put back in cellar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Put back in cellar'));
      await tester.pumpAndSettle();

      expect(find.text('No bottles drunk yet'), findsOneWidget);
      expect((await repository.fetchAll()).first.quantity, 3);
    });
  });

  group('statistics', () {
    testWidgets('shows the totals and bottles per type and country', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'Statistics');

      expect(find.bySemanticsLabel('Bottles: 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Wines: 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Cellar value: 2,199.50'), findsOneWidget);
      expect(find.bySemanticsLabel('Red: 3 bottles'), findsOneWidget);
      await scrollTo(tester, find.text('Bottles by country'));
      expect(find.bySemanticsLabel('Italia: 3 bottles'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('explains itself when the cellar is empty', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: InMemoryWineRepository(),
      );
      await openTab(tester, 'Statistics');
      expect(find.text('No statistics yet'), findsOneWidget);
    });
  });

  group('cellar map', () {
    testWidgets('a rack is created, filled and opened', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'Map');
      expect(find.text('No racks yet'), findsOneWidget);

      await tester.tap(find.text('New rack'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'A');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shelves'),
        '2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Places per shelf'),
        '3',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Rack A'), findsOneWidget);
      expect(find.text('0 of 6 places used'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Shelf 2, place 3, empty'));
      await tester.pumpAndSettle();
      expect(find.text('Place a wine on shelf 2, place 3'), findsOneWidget);
      await tester.tap(find.text('Chablis'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 6 places used'), findsOneWidget);
      final chablis = (await repository.fetchAll()).last;
      expect((chablis.rack, chablis.shelf, chablis.position), ('A', '2', '3'));

      await tester.tap(find.bySemanticsLabel('Shelf 2, place 3: Chablis'));
      await tester.pumpAndSettle();
      expect(find.text('Rack A · Shelf 2 · Position 3'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the rack form refuses bad sizes and a taken name', (
      tester,
    ) async {
      await repository.addRack(Rack(name: 'A', shelves: 1, slotsPerShelf: 1));
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'Map');

      await tester.tap(find.byTooltip('New rack'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'a');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shelves'),
        '0',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Places per shelf'),
        '31',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('There is already a rack with this name'),
        findsOneWidget,
      );
      expect(find.text('Enter a number from 1 to 30'), findsNWidgets(2));
      expect(await repository.fetchRacks(), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wines in the rack without a place are listed', (tester) async {
      await repository.addRack(Rack(name: 'A', shelves: 1, slotsPerShelf: 1));
      final barolo = (await repository.fetchAll()).first;
      await repository.update(barolo.withRack('a'));
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'Map');

      expect(find.text('In this rack, without a place'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Barolo'), findsOneWidget);
    });

    testWidgets('a rack can be deleted, keeping its wines', (tester) async {
      await repository.addRack(Rack(name: 'A', shelves: 1, slotsPerShelf: 1));
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await openTab(tester, 'Map');

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete rack'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No racks yet'), findsOneWidget);
      expect(await repository.fetchAll(), hasLength(2));
    });
  });

  group('export', () {
    testWidgets('shares every wine as a CSV file', (tester) async {
      Uint8List? shared;
      String? name;
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
        shareFile:
            (bytes, {required fileName, required mimeType, origin}) async {
              shared = bytes;
              name = fileName;
              expect(mimeType, 'text/csv');
            },
      );
      // Filters don't limit the export.
      await tester.enterText(find.byType(TextField), 'Chablis');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Export to spreadsheet'));
      await tester.pumpAndSettle();

      expect(name, 'wine-cellar.csv');
      final text = utf8.decode(shared!);
      // A byte order mark first, so Excel reads å, æ and ø.
      expect(shared!.take(3), [0xEF, 0xBB, 0xBF]);
      expect(text, startsWith('Name;Producer;Vintage;Type'));
      expect(text, contains('\r\nBarolo;;;Red;Italia;;Nebbiolo;3;650;'));
      expect(text, contains('\r\nChablis;;;White;France;;;1;249.5;'));
    });

    testWidgets('a failed share shows a message, not a crash', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
        shareFile: (bytes, {required fileName, required mimeType, origin}) =>
            throw StateError('no share sheet'),
      );
      await tester.tap(find.byTooltip('Export to spreadsheet'));
      await tester.pumpAndSettle();

      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    test('uses a decimal comma and Nordic column names in Swedish', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('sv'));
      final csv = utf8.decode(
        cellarCsv(l10n, 'sv', [
          Wine(name: 'Rioja', price: 249.5, purchaseDate: DateTime(2026, 3, 4)),
        ]),
      );
      expect(csv, startsWith('Namn;Producent;'));
      expect(csv, contains(';249,5;'));
      expect(csv, contains(';2026-03-04;'));
    });
  });

  for (final theme in ['light', 'dark']) {
    group('accessibility guidelines in the $theme theme', () {
      Future<void> pumpWithRack(WidgetTester tester) async {
        final rack = await repository.addRack(
          Rack(name: 'A', shelves: 2, slotsPerShelf: 4),
        );
        final barolo = (await repository.fetchAll()).first;
        await repository.update(
          barolo.withLocation(rack: rack.name, shelf: '1', position: '2'),
        );
        await pumpApp(
          tester,
          await settingsWith({'locale': 'en', 'theme': theme}),
          repository: repository,
        );
      }

      for (final tab in ['Map', 'Statistics', 'History']) {
        testWidgets('the $tab tab', (tester) async {
          await pumpWithRack(tester);
          await openTab(tester, tab);
          await expectMeetsGuidelines(tester);
        });
      }

      testWidgets('the drink sheet', (tester) async {
        await pumpWithRack(tester);
        await tester.tap(find.text('Barolo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Drink a bottle'));
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      });

      testWidgets('the rack form', (tester) async {
        await pumpWithRack(tester);
        await openTab(tester, 'Map');
        await tester.tap(find.byTooltip('New rack'));
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      });
    });
  }
}
