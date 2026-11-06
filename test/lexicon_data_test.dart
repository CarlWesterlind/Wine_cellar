import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/lexicon/lexicon.dart';
import 'package:wine_cellar/lexicon/lexicon_search.dart';
import 'package:wine_cellar/lexicon/normalize.dart';

import '../tool/build_lexicon.dart';

void main() {
  final built = buildLexicon(Directory('tool/lexicon'));
  final lexicon = Lexicon.fromJson(jsonDecode(built) as Map<String, dynamic>);

  LexPlace place(String name, {PlaceLevel? level}) => lexicon.places.firstWhere(
    (p) => p.name == name && (level == null || p.level == level),
    orElse: () => throw StateError('No place $name'),
  );
  List<String> pathNames(String name, {PlaceLevel? level}) => [
    for (final p in lexicon.pathOf(place(name, level: level))) p.name,
  ];

  test('the asset is up to date (run: dart run tool/build_lexicon.dart)', () {
    expect(File('assets/lexicon/lexicon.json').readAsStringSync(), built);
  });

  group('structure', () {
    test('every country has a name in all four languages', () {
      for (final country in lexicon.countries) {
        for (final lang in ['sv', 'da', 'nb', 'en']) {
          expect(
            country.names[lang],
            isNotEmpty,
            reason: '${country.id} $lang',
          );
        }
      }
    });

    test('every place lies in a known country', () {
      final ids = {for (final c in lexicon.countries) c.id};
      for (final p in lexicon.places) {
        expect(ids, contains(lexicon.countryIdOf(p)), reason: p.id);
      }
    });

    test('ids are unique', () {
      for (final list in [
        lexicon.grapes.map((g) => g.id),
        lexicon.blends.map((b) => b.id),
        lexicon.classifications.map((c) => c.id),
        lexicon.countries.map((c) => c.id),
      ]) {
        final ids = list.toList();
        expect(ids.toSet().length, ids.length);
      }
    });

    test('country codes and place ids used anywhere exist', () {
      final countries = {for (final c in lexicon.countries) c.id};
      for (final g in lexicon.grapes) {
        for (final code in [
          ...g.preferredIn,
          for (final s in g.synonyms) ...s.preferredIn,
        ]) {
          expect(countries, contains(code), reason: g.name);
        }
      }
      for (final c in lexicon.classifications) {
        for (final code in c.countries) {
          expect(countries, contains(code), reason: c.name);
        }
        for (final id in c.places) {
          expect(lexicon.placeById(id), isNotNull, reason: '${c.name}: $id');
        }
      }
      for (final s in lexicon.sweetness) {
        for (final code in s.countries) {
          expect(countries, contains(code), reason: s.term);
        }
      }
    });

    test('at least 1,000 grapes, and no name belongs to two grapes', () {
      expect(lexicon.grapes.length, greaterThanOrEqualTo(1000));
      final owner = <String, String>{};
      for (final g in lexicon.grapes) {
        for (final name in g.allNames.map(normalizeForSearch).toSet()) {
          expect(owner[name], anyOf(isNull, g.id), reason: name);
          owner[name] = g.id;
        }
      }
    });

    test('grape colours are red, white or pink', () {
      for (final g in lexicon.grapes) {
        expect(['red', 'white', 'pink'], contains(g.color), reason: g.name);
      }
    });
  });

  group('facts', () {
    test('places lie where they should', () {
      expect(pathNames('Morgon'), ['Morgon', 'Beaujolais']);
      expect(pathNames('Vosne-Romanée'), [
        'Vosne-Romanée',
        'Côte de Nuits',
        'Bourgogne',
      ]);
      expect(pathNames('Pouilly-Fuissé'), [
        'Pouilly-Fuissé',
        'Mâconnais',
        'Bourgogne',
      ]);
      expect(pathNames('Barolo', level: PlaceLevel.appellation), [
        'Barolo',
        'Piemonte',
      ]);
      expect(
        lexicon.countryIdOf(place('Rioja', level: PlaceLevel.appellation)),
        'ES',
      );
      expect(pathNames('Wachau'), ['Wachau', 'Niederösterreich']);
      expect(pathNames('Wehlener Sonnenuhr').skip(1).first, 'Wehlen');
      expect(pathNames('La Tâche')[1], 'Vosne-Romanée');
      expect(lexicon.countryIdOf(place('Porto')), 'PT');
    });

    test('Chablis has its four levels and seven Grands Crus', () {
      for (final name in [
        'Petit Chablis',
        'Chablis',
        'Chablis Premier Cru',
        'Chablis Grand Cru',
      ]) {
        expect(place(name, level: PlaceLevel.appellation), isNotNull);
      }
      final grandCru = place('Chablis Grand Cru');
      final climats = lexicon.places
          .where((p) => p.parentId == grandCru.id)
          .map((p) => p.name)
          .toSet();
      expect(climats, {
        'Blanchot',
        'Bougros',
        'Grenouilles',
        'Les Clos',
        'Preuses',
        'Valmur',
        'Vaudésir',
      });
    });

    test('synonyms point at the right grape', () {
      expect(lexicon.grapeFor('Shiraz')?.name, 'Syrah');
      expect(lexicon.grapeFor('Primitivo')?.name, 'Zinfandel');
      expect(lexicon.grapeFor('Tribidrag')?.name, 'Zinfandel');
      expect(lexicon.grapeFor('Garnacha')?.name, 'Grenache');
      expect(lexicon.grapeFor('Cannonau')?.name, 'Grenache');
      expect(lexicon.grapeFor('Monastrell')?.name, 'Mourvèdre');
      expect(lexicon.grapeFor('Tinta Roriz')?.name, 'Tempranillo');
      expect(lexicon.grapeFor('Spätburgunder')?.name, 'Pinot Noir');
      expect(lexicon.grapeFor('Pinot Grigio')?.name, 'Pinot Gris');
      expect(lexicon.grapeFor('Steen')?.name, 'Chenin Blanc');
      expect(lexicon.grapeFor('Kékfrankos')?.name, 'Blaufränkisch');
      expect(lexicon.grapeFor('Alvarinho')?.name, 'Albariño');
      expect(lexicon.grapeFor('Ugni Blanc')?.name, 'Ugni Blanc');
      expect(lexicon.grapeFor('Trebbiano Toscano')?.name, 'Ugni Blanc');
      expect(lexicon.grapeFor('Johannisberg')?.name, 'Sylvaner');
    });

    test('Smaragd belongs to the Wachau only', () {
      final smaragd = lexicon.classifications.firstWhere(
        (c) => c.name == 'Smaragd',
      );
      expect(smaragd.countries, ['AT']);
      expect(smaragd.places, ['at-wachau']);
    });

    test('sweetness words map to the right scale', () {
      expect(lexicon.sweetnessFor('Brut')?.scale, SweetnessScale.dry);
      expect(lexicon.sweetnessFor('halbtrocken')?.scale, SweetnessScale.offDry);
      expect(lexicon.sweetnessFor('Doux')?.scale, SweetnessScale.sweet);
      expect(lexicon.sweetnessFor('Secco')?.scale, SweetnessScale.dry);
    });
  });

  group('search over the real lexicon', () {
    final search = LexiconSearch(lexicon);

    test('finds what people type', () {
      expect(search.places('burgonge').first.text, 'Bourgogne');
      expect(search.places('vosne').first.text, 'Vosne-Romanée');
      expect(search.places('chablis 1er').first.text, 'Chablis Premier Cru');
      expect(search.grapes('temperanillo').first.text, 'Tempranillo');
      expect(search.grapes('gruner').first.text, 'Grüner Veltliner');
      expect(search.grapes('s', countryId: 'AU').first.text, 'Shiraz');
      expect(search.classifications('smarag').first.text, 'Smaragd');
      expect(search.classifications('1er cru').first.text, 'Premier Cru');
      expect(search.countries('itali', 'sv').first.text, 'Italien');
    });

    test('is fast enough to run on every keystroke', () {
      final queries = ['b', 'bo', 'bou', 'bour', 'burgonge', 'sauv', 'xyzq'];
      final watch = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        for (final q in queries) {
          search.places(q);
          search.grapes(q);
        }
      }
      final perQuery = watch.elapsedMicroseconds / (20 * queries.length * 2);
      // Generous in debug-mode tests; release builds are several times faster.
      expect(perQuery, lessThan(16000));
    });
  });
}
