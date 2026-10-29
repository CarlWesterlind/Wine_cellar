import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:wine_cellar/models/tasting_note.dart';
import 'package:wine_cellar/models/wine.dart';

import 'failing_wine_repository.dart';
import 'helpers.dart';

void main() {
  late FailingWineRepository repository;

  setUp(() async {
    repository = FailingWineRepository([
      Wine(
        name: 'Barolo',
        quantity: 3,
        purchaseDate: DateTime(2026, 3, 14),
        purchasedFrom: 'Systembolaget',
      ),
    ]);
    final barolo = (await repository.fetchAll()).single;
    await repository.addNote(
      TastingNote(
        wineId: barolo.id!,
        date: DateTime(2026, 10, 12),
        rating: 4,
        text: 'Still tight, wait a few years.',
      ),
    );
  });

  Future<void> openBarolo(WidgetTester tester, {String locale = 'en'}) async {
    await pumpApp(
      tester,
      await settingsWith({'locale': locale}),
      repository: repository,
    );
    await tester.tap(find.text('Barolo'));
    await tester.pumpAndSettle();
  }

  /// Scrolls the wine details down until [finder] is on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );

  group('wine details', () {
    testWidgets('show purchase info and notes in the chosen language', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openBarolo(tester, locale: 'sv');

      expect(find.text('14 mars 2026 · Systembolaget'), findsOneWidget);
      await scrollTo(tester, find.text('Still tight, wait a few years.'));
      expect(find.text('12 okt. 2026'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('4 stjärnor')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a new note is added with date, rating and text', (
      tester,
    ) async {
      await openBarolo(tester);
      await scrollTo(tester, find.text('New note'));
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();

      // Saving an empty note is not allowed.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Lovely with lamb.');
      await tester.tap(find.byTooltip('5 stars'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = await repository.fetchNotes('1');
      expect(saved, hasLength(2));
      final added = saved.firstWhere((n) => n.text == 'Lovely with lamb.');
      expect(added.rating, 5);
      expect(added.date, DateUtils.dateOnly(DateTime.now()));

      await scrollTo(tester, find.text('Lovely with lamb.'));
      expect(find.text('Lovely with lamb.'), findsOneWidget);
    });

    testWidgets('tapping the same star again removes the rating', (
      tester,
    ) async {
      await openBarolo(tester);
      await scrollTo(tester, find.text('Still tight, wait a few years.'));
      await tester.tap(find.text('Still tight, wait a few years.'));
      await tester.pumpAndSettle();
      expect(find.text('Edit note'), findsOneWidget);

      await tester.tap(find.byTooltip('4 stars')); // The current rating.
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect((await repository.fetchNotes('1')).single.rating, isNull);
    });

    testWidgets('cancelling the dialog changes nothing', (tester) async {
      await openBarolo(tester);
      await scrollTo(tester, find.text('New note'));
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Never saved');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await repository.fetchNotes('1'), hasLength(1));
      expect(find.text('Never saved'), findsNothing);
    });

    testWidgets('a note is deleted after confirming', (tester) async {
      await openBarolo(tester);
      await scrollTo(tester, find.byIcon(Icons.more_vert));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Delete this note?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await repository.fetchNotes('1'), isEmpty);
      expect(find.textContaining('No notes yet'), findsOneWidget);
    });

    testWidgets('a failed save shows a message and keeps the old notes', (
      tester,
    ) async {
      await openBarolo(tester);
      await scrollTo(tester, find.text('New note'));
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Lost?');

      repository.error = StateError('offline');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Lost?'), findsNothing);
      expect(find.text('Still tight, wait a few years.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notes that fail to load can be retried', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      repository.error = StateError('offline');
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Try again'));
      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );

      repository.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Still tight, wait a few years.'));
      expect(find.text('Still tight, wait a few years.'), findsOneWidget);
    });

    testWidgets('deleting the wine also deletes its notes', (tester) async {
      await openBarolo(tester);
      await tester.tap(find.byTooltip('Delete wine'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await repository.fetchAll(), isEmpty);
      expect(await repository.fetchNotes('1'), isEmpty);
    });
  });

  group('wine form', () {
    Future<void> scrollFormTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find
              .descendant(
                of: find.byType(Form),
                matching: find.byType(Scrollable),
              )
              .first,
        );

    testWidgets('a purchase date can be picked and is saved', (tester) async {
      await pumpApp(tester, await settingsWith({'locale': 'en'}));
      await tester.tap(find.text('Add wine'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'X');

      await scrollFormTo(tester, find.text('Purchase date'));
      await tester.tap(find.widgetWithText(InkWell, 'Purchase date'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('1'),
        ),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expected = DateTime(now.year, now.month, 1);
      expect(
        find.text(DateFormat.yMMMd('en').format(expected)),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bought from'),
        'Vinoteket',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
      expect(
        find.text('${DateFormat.yMMMd('en').format(expected)} · Vinoteket'),
        findsOneWidget,
      );
    });

    testWidgets('the purchase date cannot be in the future', (tester) async {
      await pumpApp(tester, await settingsWith({'locale': 'en'}));
      await tester.tap(find.text('Add wine'));
      await tester.pumpAndSettle();
      await scrollFormTo(tester, find.text('Purchase date'));
      await tester.tap(find.widgetWithText(InkWell, 'Purchase date'));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, DateUtils.dateOnly(DateTime.now()));
    });

    testWidgets(
      'editing a wine keeps its purchase info, and it can be cleared',
      (tester) async {
        await openBarolo(tester);
        await tester.tap(find.byTooltip('Edit wine'));
        await tester.pumpAndSettle();
        await scrollFormTo(tester, find.text('Mar 14, 2026'));
        expect(find.text('Mar 14, 2026'), findsOneWidget);
        expect(find.text('Systembolaget'), findsOneWidget);

        // Saving without changes keeps everything.
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        var barolo = (await repository.fetchAll()).single;
        expect(barolo.purchaseDate, DateTime(2026, 3, 14));
        expect(barolo.purchasedFrom, 'Systembolaget');

        // Clearing the date removes it.
        await tester.tap(find.byTooltip('Edit wine'));
        await tester.pumpAndSettle();
        await scrollFormTo(tester, find.byTooltip('Clear date'));
        await tester.tap(find.byTooltip('Clear date'));
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        barolo = (await repository.fetchAll()).single;
        expect(barolo.purchaseDate, isNull);
        expect(barolo.purchasedFrom, 'Systembolaget');
      },
    );

    testWidgets('a very old purchase date does not crash the date picker', (
      tester,
    ) async {
      repository = FailingWineRepository([
        Wine(name: 'Old', purchaseDate: DateTime(1850, 1, 1)),
      ]);
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Old'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit wine'));
      await tester.pumpAndSettle();
      await scrollFormTo(tester, find.text('Jan 1, 1850'));
      await tester.tap(find.widgetWithText(InkWell, 'Purchase date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
