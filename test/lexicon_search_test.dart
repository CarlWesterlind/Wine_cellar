import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/lexicon/lexicon.dart';
import 'package:wine_cellar/lexicon/lexicon_search.dart';
import 'package:wine_cellar/lexicon/normalize.dart';

/// A tiny lexicon with the cases the search must handle.
final testLexicon = Lexicon.fromJson({
  'format': 1,
  'version': 1,
  'countries': [
    {
      'id': 'FR',
      'names': {
        'sv': 'Frankrike',
        'da': 'Frankrig',
        'nb': 'Frankrike',
        'en': 'France',
      },
      'aliases': ['Francia'],
    },
    {
      'id': 'IT',
      'names': {
        'sv': 'Italien',
        'da': 'Italien',
        'nb': 'Italia',
        'en': 'Italy',
      },
      'aliases': ['Italia'],
    },
    {
      'id': 'AU',
      'names': {
        'sv': 'Australien',
        'da': 'Australien',
        'nb': 'Australia',
        'en': 'Australia',
      },
    },
  ],
  'places': [
    {
      'id': 'fr-bourgogne',
      'name': 'Bourgogne',
      'level': 'region',
      'country': 'FR',
      'aliases': ['Burgundy'],
    },
    {
      'id': 'fr-cote-de-nuits',
      'name': 'Côte de Nuits',
      'level': 'subregion',
      'parent': 'fr-bourgogne',
    },
    {
      'id': 'fr-vosne-romanee',
      'name': 'Vosne-Romanée',
      'level': 'appellation',
      'parent': 'fr-cote-de-nuits',
    },
    {
      'id': 'fr-la-tache',
      'name': 'La Tâche',
      'level': 'vineyard',
      'parent': 'fr-vosne-romanee',
    },
    {
      'id': 'fr-maconnais',
      'name': 'Mâconnais',
      'level': 'subregion',
      'parent': 'fr-bourgogne',
    },
    {
      'id': 'fr-pouilly-fuisse',
      'name': 'Pouilly-Fuissé',
      'level': 'appellation',
      'parent': 'fr-maconnais',
    },
    {
      'id': 'fr-beaujolais',
      'name': 'Beaujolais',
      'level': 'region',
      'country': 'FR',
    },
    {
      'id': 'fr-morgon',
      'name': 'Morgon',
      'level': 'appellation',
      'parent': 'fr-beaujolais',
    },
    {
      'id': 'it-piemonte',
      'name': 'Piemonte',
      'level': 'region',
      'country': 'IT',
      'aliases': ['Piedmont'],
    },
    {
      'id': 'it-barolo',
      'name': 'Barolo',
      'level': 'appellation',
      'parent': 'it-piemonte',
    },
  ],
  'grapes': [
    {
      'id': 'syrah',
      'name': 'Syrah',
      'color': 'red',
      'synonyms': [
        {
          'name': 'Shiraz',
          'preferredIn': ['AU'],
        },
      ],
    },
    {
      'id': 'primitivo',
      'name': 'Primitivo',
      'color': 'red',
      'preferredIn': ['IT'],
      'synonyms': [
        {
          'name': 'Zinfandel',
          'preferredIn': ['US'],
        },
        {'name': 'Tribidrag'},
      ],
    },
    {'id': 'tempranillo', 'name': 'Tempranillo', 'color': 'red'},
    {'id': 'gruner-veltliner', 'name': 'Grüner Veltliner', 'color': 'white'},
    {'id': 'sylvaner', 'name': 'Sylvaner', 'color': 'white'},
  ],
  'blends': [
    {
      'id': 'bordeaux-blend',
      'name': 'Bordeaux blend',
      'names': {'sv': 'Bordeaux-blend'},
    },
  ],
  'classifications': [
    {
      'id': 'premier-cru',
      'name': 'Premier Cru',
      'kind': 'site',
      'countries': ['FR'],
      'aliases': ['1er Cru', '1er', '1 Cru'],
    },
    {
      'id': 'grosses-gewachs',
      'name': 'Grosses Gewächs',
      'kind': 'site',
      'countries': ['DE'],
      'aliases': ['GG'],
    },
    {
      'id': 'trockenbeerenauslese',
      'name': 'Trockenbeerenauslese',
      'kind': 'ripeness',
      'countries': ['DE', 'AT'],
      'aliases': ['TBA'],
    },
  ],
  'sweetness': [
    {'term': 'Brut', 'scale': 'dry'},
    {
      'term': 'trocken',
      'scale': 'dry',
      'countries': ['DE', 'AT'],
    },
    {
      'term': 'Doux',
      'scale': 'sweet',
      'countries': ['FR'],
    },
  ],
});

void main() {
  final search = LexiconSearch(testLexicon);
  List<String> texts(List<Suggestion<Object?>> list) => [
    for (final s in list) s.text,
  ];

  group('normalizeForSearch', () {
    test('removes accents, case, hyphens and extra spaces', () {
      expect(normalizeForSearch('Grüner-Veltliner  '), 'gruner veltliner');
      expect(normalizeForSearch('Côte-Rôtie'), 'cote rotie');
      expect(normalizeForSearch('Straße'), 'strasse');
      expect(normalizeForSearch('Ærø'), 'aero');
      expect(
        normalizeForSearch("Nuits-St-Georges, 1'er"),
        'nuits st georges 1 er',
      );
    });
  });

  group('editDistance', () {
    test('counts edits up to a limit', () {
      expect(editDistance('burgonge', 'bourgogne', 2), lessThanOrEqualTo(2));
      expect(editDistance('abc', 'xyz', 1), 2);
      expect(editDistance('syrha', 'syrah', 1), 1); // swapped letters
    });
  });

  group('suggestions', () {
    test('tolerate typos and missing accents', () {
      expect(search.places('burgonge').first.text, 'Bourgogne');
      expect(search.grapes('temperanillo').first.text, 'Tempranillo');
      expect(search.grapes('gruner').first.text, 'Grüner Veltliner');
      expect(search.places('burgundy').first.text, 'Bourgogne');
    });

    test('show where a place is', () {
      expect(
        search.places('vosne').first.detail,
        'Côte de Nuits · Bourgogne · France',
      );
      expect(search.places('morgon').first.detail, 'Beaujolais · France');
    });

    test('put the name used in the wine\'s country first', () {
      final australian = search.grapes('s', countryId: 'AU');
      expect(australian.first.text, 'Shiraz');
      expect(australian.first.detail, '= Syrah');
      expect(texts(australian), containsAll(['Shiraz', 'Syrah']));

      final french = search.grapes('s', countryId: 'FR');
      expect(texts(french), containsAll(['Shiraz', 'Syrah']));
      expect(
        texts(french).indexOf('Syrah'),
        lessThan(texts(french).indexOf('Shiraz')),
      );
    });

    test('show synonyms with their grape', () {
      final zin = search.grapes('zin', countryId: 'IT');
      expect(zin.first.text, 'Zinfandel');
      expect(zin.first.detail, '= Primitivo');
      expect(
        texts(search.grapes('primitivo', countryId: 'IT')).first,
        'Primitivo',
      );
    });

    test('find classifications by abbreviation', () {
      expect(search.classifications('1er cru').first.text, 'Premier Cru');
      expect(search.classifications('gg').first.text, 'Grosses Gewächs');
      expect(search.classifications('tba').first.text, 'Trockenbeerenauslese');
    });

    test('can be limited to one level and one area', () {
      final burgundy = search.places(
        '',
        level: PlaceLevel.appellation,
        withinId: 'fr-bourgogne',
      );
      expect(texts(burgundy), ['Vosne-Romanée', 'Pouilly-Fuissé']);
      expect(
        texts(
          search.places(
            '',
            level: PlaceLevel.vineyard,
            withinId: 'fr-vosne-romanee',
          ),
        ),
        ['La Tâche'],
      );
    });

    test('countries in the app language, found by any name', () {
      expect(search.countries('ital', 'sv').first.text, 'Italien');
      expect(search.countries('italia', 'en').first.text, 'Italy');
      expect(search.countries('frank', 'da').first.text, 'Frankrig');
    });

    test('sweetness terms and blends', () {
      expect(search.sweetness('tro').first.text, 'trocken');
      expect(search.blends('bord', 'sv').first.text, 'Bordeaux-blend');
      expect(search.blends('bord', 'en').first.text, 'Bordeaux blend');
    });

    test('never more than 8', () {
      expect(search.places('').length, lessThanOrEqualTo(8));
    });

    test('odd input gives no crash', () {
      for (final query in ['', '   ', '🍷', 'a' * 200, '((', r'\']) {
        expect(() => search.grapes(query), returnsNormally);
        expect(() => search.places(query), returnsNormally);
      }
      expect(search.grapes('🍷'), isEmpty);
    });
  });

  group('Lexicon lookups', () {
    test('find a country by any name', () {
      expect(testLexicon.countryFor('Italia')?.id, 'IT');
      expect(testLexicon.countryFor(' italien ')?.id, 'IT');
      expect(testLexicon.countryFor('Narnia'), isNull);
    });

    test('find a grape by name or synonym', () {
      expect(testLexicon.grapeFor('Shiraz')?.name, 'Syrah');
      expect(testLexicon.grapeFor('zinfandel')?.name, 'Primitivo');
      expect(testLexicon.grapeFor('Rara Neagra'), isNull);
    });

    test('find a sweetness term', () {
      expect(testLexicon.sweetnessFor('TROCKEN')?.scale, SweetnessScale.dry);
    });

    test('a broken file throws FormatException', () {
      expect(() => Lexicon.fromJson({'format': 1}), throwsFormatException);
      expect(
        () => Lexicon.fromJson({
          'format': 1,
          'version': 1,
          'countries': [],
          'places': [
            {'id': 'x', 'name': 'X', 'level': 'region'},
          ],
          'grapes': [],
          'blends': [],
          'classifications': [],
          'sweetness': [],
        }),
        throwsFormatException, // a region needs a country
      );
    });
  });
}
