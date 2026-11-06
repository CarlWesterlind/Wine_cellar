import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';

import 'helpers.dart';

void main() {
  Future<void> openWine(WidgetTester tester, Wine wine) async {
    await pumpApp(
      tester,
      await settingsWith({'locale': 'en'}),
      repository: InMemoryWineRepository([wine]),
    );
    await tester.tap(find.text(wine.name));
    await tester.pumpAndSettle();
  }

  testWidgets('the wine page shows the new fields when filled', (tester) async {
    await openWine(
      tester,
      Wine(
        name: 'Les Suchots',
        country: 'France',
        region: 'Bourgogne',
        subregion: 'Côte de Nuits',
        appellation: 'Vosne-Romanée',
        vineyard: 'Les Suchots',
        grapes: ['Pinot Noir'],
        classifications: ['Premier Cru'],
        sweetness: 'Brut',
      ),
    );
    expect(find.text('Côte de Nuits'), findsOneWidget);
    expect(find.text('Vosne-Romanée'), findsOneWidget);
    expect(find.text('Premier Cru'), findsOneWidget);
    // The label word, and what it means.
    await scrollTo(tester, find.text('Brut · Dry'));
    expect(find.text('Brut · Dry'), findsOneWidget);
  });

  testWidgets('unknown grapes and blends are spelled out', (tester) async {
    await openWine(tester, Wine(name: 'Mystery', grapesUnknown: true));
    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('a blend lists its grapes after "Blend"', (tester) async {
    await openWine(
      tester,
      Wine(
        name: 'Claret',
        grapes: ['Merlot', 'Cabernet Franc'],
        grapesAreBlend: true,
      ),
    );
    expect(find.text('Blend: Merlot, Cabernet Franc'), findsOneWidget);
  });

  testWidgets('empty fields are not shown', (tester) async {
    await openWine(tester, Wine(name: 'Plain'));
    for (final label in [
      'Part of region',
      'Vineyard',
      'Classification',
      'Sweetness',
      'Grapes',
    ]) {
      expect(find.text(label), findsNothing);
    }
    expect(find.byType(Card), findsWidgets);
  });
}
