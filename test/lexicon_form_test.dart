import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/wine_repository.dart';

import 'helpers.dart';

void main() {
  late InMemoryWineRepository repository;

  Future<void> openForm(WidgetTester tester, {String theme = 'light'}) async {
    repository = InMemoryWineRepository();
    await pumpApp(
      tester,
      await settingsWith({'locale': 'en', 'theme': theme}),
      repository: repository,
    );
    await tester.tap(find.text('Add wine').first);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> type(WidgetTester tester, String label, String text) async {
    await scrollFormTo(tester, field(label));
    await tester.enterText(field(label), text);
    await tester.pumpAndSettle();
  }

  Finder anySuggestion(String text) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('SuggestionList'),
    ),
    matching: find.text(text),
  );

  Future<void> pick(WidgetTester tester, String text) async {
    await tester.tap(anySuggestion(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('a misspelled region is suggested correctly', (tester) async {
    await openForm(tester);
    await type(tester, 'Region', 'burgonge');
    expect(anySuggestion('Bourgogne'), findsOneWidget);

    await pick(tester, 'Bourgogne');
    expect(fieldText(tester, 'Region'), 'Bourgogne');
    expect(anySuggestion('Bourgogne'), findsNothing);
  });

  testWidgets('picking a village fills in the places around it', (
    tester,
  ) async {
    await openForm(tester);
    await type(tester, 'Village or appellation', 'vosne');
    expect(find.text('Côte de Nuits · Bourgogne · France'), findsOneWidget);
    await pick(tester, 'Vosne-Romanée');

    expect(fieldText(tester, 'Village or appellation'), 'Vosne-Romanée');
    expect(fieldText(tester, 'Country'), 'France');
    expect(fieldText(tester, 'Region'), 'Bourgogne');
    expect(fieldText(tester, 'Part of region'), 'Côte de Nuits');
  });

  testWidgets('what the user typed is never replaced', (tester) async {
    await openForm(tester);
    await type(tester, 'Region', 'Burgundy');
    await type(tester, 'Village or appellation', 'vosne');
    await pick(tester, 'Vosne-Romanée');

    expect(fieldText(tester, 'Region'), 'Burgundy');
    expect(fieldText(tester, 'Part of region'), 'Côte de Nuits');
  });

  testWidgets('with a region chosen, villages there are listed', (
    tester,
  ) async {
    await openForm(tester);
    await type(tester, 'Region', 'Beaujolais');
    await type(tester, 'Village or appellation', 'mor');
    expect(anySuggestion('Morgon'), findsOneWidget);
    // Typing ignores Enter: free text is kept as typed, never auto-picked.
    await type(tester, 'Village or appellation', 'Morgonx');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'Village or appellation'), 'Morgonx');
  });

  testWidgets('grapes: the name usual in the country comes first', (
    tester,
  ) async {
    await openForm(tester);
    await type(tester, 'Country', 'Australia');
    await type(tester, 'Grapes', 'sh');
    final first = tester.widget<ListTile>(
      find
          .descendant(
            of: find.byWidgetPredicate(
              (w) => w.runtimeType.toString().startsWith('SuggestionList'),
            ),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect((first.title! as Text).data, 'Shiraz');

    await pick(tester, 'Shiraz');
    expect(find.widgetWithText(InputChip, 'Shiraz'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Shiraz'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Shiraz'), findsNothing);
  });

  testWidgets('free text becomes a grape chip on Enter', (tester) async {
    await openForm(tester);
    await type(tester, 'Grapes', 'Rara Neagră');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Rara Neagră'), findsOneWidget);
  });

  testWidgets('"Don\'t know" makes way for a named grape', (tester) async {
    await openForm(tester);
    await scrollFormTo(tester, find.text("Don't know"));
    await tester.tap(find.text("Don't know"));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, "Don't know"))
          .selected,
      isTrue,
    );

    await type(tester, 'Grapes', 'merlo');
    await pick(tester, 'Merlot');
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, "Don't know"))
          .selected,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a named blend switches on "Blend"', (tester) async {
    await openForm(tester);
    await type(tester, 'Grapes', 'bordeaux');
    await pick(tester, 'Bordeaux blend');
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Blend'))
          .selected,
      isTrue,
    );
  });

  testWidgets('classifications and sweetness are suggested', (tester) async {
    await openForm(tester);
    await type(tester, 'Classification', '1er');
    await pick(tester, 'Premier Cru');
    expect(find.widgetWithText(InputChip, 'Premier Cru'), findsOneWidget);

    await type(tester, 'Sweetness', 'halbtr');
    await pick(tester, 'halbtrocken');
    expect(fieldText(tester, 'Sweetness'), 'halbtrocken');
  });

  testWidgets('everything is saved with the wine', (tester) async {
    await openForm(tester);
    await type(tester, 'Name', 'Les Suchots');
    await type(tester, 'Village or appellation', 'vosne');
    await pick(tester, 'Vosne-Romanée');
    await type(tester, 'Vineyard', 'such');
    await pick(tester, 'Les Suchots');
    await type(tester, 'Grapes', 'pinot noir');
    await pick(tester, 'Pinot Noir');
    await type(tester, 'Classification', 'premier');
    await pick(tester, 'Premier Cru');
    await tapSave(tester);

    final wine = (await repository.fetchAll()).single;
    expect(wine.country, 'France');
    expect(wine.region, 'Bourgogne');
    expect(wine.subregion, 'Côte de Nuits');
    expect(wine.appellation, 'Vosne-Romanée');
    expect(wine.vineyard, 'Les Suchots');
    expect(wine.grapes, ['Pinot Noir']);
    expect(wine.classifications, ['Premier Cru']);
  });

  for (final theme in ['light', 'dark']) {
    testWidgets('accessibility with suggestions open, $theme theme', (
      tester,
    ) async {
      await openForm(tester, theme: theme);
      await type(tester, 'Region', 'bour');
      expect(anySuggestion('Bourgogne'), findsOneWidget);
      await expectMeetsGuidelines(tester);
    });
  }
}
