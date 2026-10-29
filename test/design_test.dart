import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/tasting_note.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/widgets/motion_widgets.dart';

import 'helpers.dart';

void main() {
  Future<InMemoryWineRepository> cellarWithNotes() async {
    final repository = InMemoryWineRepository([
      Wine(
        name: 'Barolo',
        producer: 'Scavino',
        vintage: 2019,
        quantity: 3,
        drinkFrom: 2020,
        drinkUntil: 2040,
        purchaseDate: DateTime(2026, 3, 14),
      ),
      Wine(name: 'Chablis', type: WineType.white, quantity: 6),
    ]);
    final barolo = (await repository.fetchAll()).first;
    await repository.addNote(
      TastingNote(
        wineId: barolo.id!,
        date: DateTime(2026, 10, 12),
        rating: 4,
        text: 'Lovely.',
      ),
    );
    return repository;
  }

  for (final theme in ['light', 'dark']) {
    group('accessibility guidelines in the $theme theme', () {
      testWidgets('the cellar list', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(
          tester,
          await settingsWith({'locale': 'en', 'theme': theme}),
          repository: await cellarWithNotes(),
        );

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('the wine details', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(
          tester,
          await settingsWith({'locale': 'en', 'theme': theme}),
          repository: await cellarWithNotes(),
        );
        await tester.tap(find.text('Barolo 2019'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('the wine form', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(
          tester,
          await settingsWith({'locale': 'en', 'theme': theme}),
          repository: await cellarWithNotes(),
        );
        await tester.tap(find.text('Add wine'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('the note dialog', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(
          tester,
          await settingsWith({'locale': 'en', 'theme': theme}),
          repository: await cellarWithNotes(),
        );
        await tester.tap(find.text('Barolo 2019'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('New note'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('New note'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });
    });
  }

  testWidgets('each wine card is read out as one sentence', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      await settingsWith({'locale': 'sv'}),
      repository: await cellarWithNotes(),
    );

    expect(
      find.bySemanticsLabel(
        'Barolo 2019, Scavino, 3 flaskor, Redo att drickas',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the theme can be switched and is remembered', (tester) async {
    await pumpApp(
      tester,
      await settingsWith({'locale': 'en'}),
      repository: await cellarWithNotes(),
    );
    expect(
      Theme.of(tester.element(find.text('Barolo 2019'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme'), 'dark');
  });

  group('animations', () {
    testWidgets('cards fade in when the list appears', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: await cellarWithNotes(),
        settle: false,
      );
      await tester.pump(); // Wines loaded.
      await tester.pump(const Duration(milliseconds: 16));

      final fades = find.descendant(
        of: find.byType(FadeSlideIn),
        matching: find.byType(FadeTransition),
      );
      expect(fades, findsWidgets);
      final opacity = tester.widget<FadeTransition>(fades.first).opacity;
      expect(opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(opacity.value, 1);
    });

    testWidgets('nothing animates when the phone asks for reduced motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: await cellarWithNotes(),
        settle: false,
      );
      await tester.pump(); // Wines loaded.

      // Everything is fully visible on the very first frame.
      final fades = tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(FadeSlideIn),
          matching: find.byType(FadeTransition),
        ),
      );
      for (final fade in fades) {
        expect(fade.opacity.value, 1);
      }
      expect(find.byType(FadeSlideIn), findsWidgets);
    });

    testWidgets('the bottle count rolls to the new number', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: await cellarWithNotes(),
      );
      await tester.tap(find.text('Barolo 2019'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drink a bottle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Mid-animation both numbers are on screen…
      expect(find.text('3 bottles'), findsOneWidget);
      expect(find.text('2 bottles'), findsOneWidget);

      // …and afterwards only the new one.
      await tester.pumpAndSettle();
      expect(find.text('3 bottles'), findsNothing);
      expect(find.text('2 bottles'), findsOneWidget);
    });
  });

  group('helpful empty states', () {
    testWidgets('an empty cellar explains what to do', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: InMemoryWineRepository(),
      );

      expect(find.text('Your cellar is empty'), findsOneWidget);
      // One clear button, no duplicate floating button.
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text('Add wine'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    });

    testWidgets('no search results offers a way back', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: await cellarWithNotes(),
      );
      await tester.enterText(find.byType(TextField), 'zinfandel');
      await tester.pumpAndSettle();
      expect(find.text('No wines match your search.'), findsOneWidget);

      await tester.tap(find.text('Show all wines'));
      await tester.pumpAndSettle();
      expect(find.text('Barolo 2019'), findsOneWidget);
      expect(find.text('Chablis'), findsOneWidget);
      expect(find.text('zinfandel'), findsNothing); // Search box cleared.
    });

    testWidgets('the search can be cleared with one tap', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: await cellarWithNotes(),
      );
      await tester.enterText(find.byType(TextField), 'chab');
      await tester.pumpAndSettle();
      expect(find.text('Barolo 2019'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Barolo 2019'), findsOneWidget);
    });
  });
}
