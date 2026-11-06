// Builds assets/lexicon/lexicon.json from the text files in tool/lexicon/.
//
// Run after changing a file there:
//   dart run tool/build_lexicon.dart
//
// File formats (one entry per line; `#` starts a comment; `|` separates
// columns; `,` separates items in a column):
//   countries.txt        ID | sv | da | nb | en | aliases
//   grapes.txt           Name | red/white/pink | synonyms | preferred in
//                        A synonym may end with @CC CC: the countries where
//                        it is the usual name. "preferred in" lists the
//                        countries where the grape's own name comes first.
//   blends.txt           Name | sv | da | nb | aliases
//   classifications.txt  Name | kind | countries | place ids | aliases
//   sweetness.txt        Term | dry/offDry/mediumSweet/sweet | countries
//   places_xx.txt        First line `@CC` (the country). Then one place per
//                        line: `R Name | aliases` for a region, `S` for a
//                        subregion, `A` for an appellation, `V` for a
//                        vineyard. A place lies in the nearest earlier line
//                        of a bigger level, so appellations that lie
//                        directly in a region go before its first
//                        subregion.
import 'dart:convert';
import 'dart:io';

/// Bumped by hand for every published change, so apps fetch it.
const lexiconVersion = 1;

void main() {
  final json = buildLexicon(Directory('tool/lexicon'));
  File('assets/lexicon/lexicon.json').writeAsStringSync(json);
  stdout.writeln('Wrote assets/lexicon/lexicon.json');
}

String buildLexicon(Directory source) {
  List<List<String>> rows(String file) {
    final lines = File('${source.path}/$file').readAsLinesSync();
    return [
      for (final line in lines)
        if (line.split('#').first.trim() case final text when text.isNotEmpty)
          [for (final cell in text.split('|')) cell.trim()],
    ];
  }

  String cell(List<String> row, int i) => i < row.length ? row[i] : '';
  List<String> list(String text) => [
    for (final item in text.split(','))
      if (item.trim().isNotEmpty) item.trim(),
  ];
  // Country codes may be separated by spaces or commas: "DE AT".
  List<String> codes(String text) =>
      text.split(RegExp(r'[\s,]+')).where((c) => c.isNotEmpty).toList();

  final countries = [
    for (final row in rows('countries.txt'))
      {
        'id': row[0],
        'names': {'sv': row[1], 'da': row[2], 'nb': row[3], 'en': row[4]},
        if (list(cell(row, 5)).isNotEmpty) 'aliases': list(cell(row, 5)),
      },
  ];

  final grapes = [
    for (final row in rows('grapes.txt'))
      {
        'id': slug(row[0]),
        'name': row[0],
        'color': row[1],
        if (codes(cell(row, 3)).isNotEmpty) 'preferredIn': codes(cell(row, 3)),
        if (list(cell(row, 2)).isNotEmpty)
          'synonyms': [
            for (final synonym in list(cell(row, 2)))
              if (synonym.split('@') case [final name, final countries])
                {'name': name.trim(), 'preferredIn': codes(countries)}
              else
                {'name': synonym},
          ],
      },
  ];

  final blends = [
    for (final row in rows('blends.txt'))
      {
        'id': slug(row[0]),
        'name': row[0],
        'names': {
          for (final (i, lang) in ['sv', 'da', 'nb'].indexed)
            if (cell(row, i + 1).isNotEmpty) lang: cell(row, i + 1),
        },
        if (list(cell(row, 4)).isNotEmpty) 'aliases': list(cell(row, 4)),
      },
  ];

  final classifications = [
    for (final row in rows('classifications.txt'))
      {
        'id': slug(row[0]),
        'name': row[0],
        'kind': row[1],
        if (codes(cell(row, 2)).isNotEmpty) 'countries': codes(cell(row, 2)),
        if (list(cell(row, 3)).isNotEmpty) 'places': list(cell(row, 3)),
        if (list(cell(row, 4)).isNotEmpty) 'aliases': list(cell(row, 4)),
      },
  ];

  final sweetness = [
    for (final row in rows('sweetness.txt'))
      {
        'term': row[0],
        'scale': row[1],
        if (codes(cell(row, 2)).isNotEmpty) 'countries': codes(cell(row, 2)),
      },
  ];

  final placeFiles =
      source
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith('places_'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final places = <Map<String, Object>>[];
  final ids = <String>{};
  for (final file in placeFiles) {
    places.addAll(_places(rows(file.uri.pathSegments.last), ids));
  }

  return jsonEncode({
    'format': 1,
    'version': lexiconVersion,
    'countries': countries,
    'places': places,
    'grapes': grapes,
    'blends': blends,
    'classifications': classifications,
    'sweetness': sweetness,
  });
}

const _levels = {
  'R': 'region',
  'S': 'subregion',
  'A': 'appellation',
  'V': 'vineyard',
};

List<Map<String, Object>> _places(List<List<String>> rows, Set<String> ids) {
  final country = rows.first.first.substring(1);
  final prefix = country.toLowerCase();
  final places = <Map<String, Object>>[];
  // The latest place seen at each level, to find parents.
  final latest = <int, Map<String, Object>>{};
  for (final row in rows.skip(1)) {
    final head = row[0];
    final level = _levels[head[0]];
    if (level == null || head[1] != ' ') {
      throw FormatException('Bad place line in $country', row.join(' | '));
    }
    final name = head.substring(2).trim();
    final depth = _levels.keys.toList().indexOf(head[0]);
    Map<String, Object>? parent;
    for (var d = depth - 1; d >= 0 && parent == null; d--) {
      parent = latest[d];
    }
    var id = '$prefix-${slug(name)}';
    if (ids.contains(id) && parent != null) {
      id = '$id-${(parent['id']! as String).substring(3)}';
    }
    if (!ids.add(id)) throw FormatException('Duplicate place', id);
    final aliases = row.length > 1
        ? [
            for (final a in row[1].split(','))
              if (a.trim().isNotEmpty) a.trim(),
          ]
        : <String>[];
    final place = <String, Object>{
      'id': id,
      'name': name,
      'level': level,
      if (depth == 0) 'country': country else 'parent': parent!['id']!,
      if (aliases.isNotEmpty) 'aliases': aliases,
    };
    places.add(place);
    latest[depth] = place;
    // A new place makes the smaller levels below the previous one stale.
    latest.removeWhere((d, _) => d > depth);
  }
  return places;
}

const _plain = {
  'a': 'àáâãäåāă',
  'c': 'çčć',
  'e': 'èéêëēě',
  'i': 'ìíîïī',
  'n': 'ñń',
  'o': 'òóôõöøō',
  's': 'šśş',
  'u': 'ùúûüū',
  'y': 'ýÿ',
  'z': 'žźż',
};

/// "Côte de Nuits" → "cote-de-nuits".
String slug(String text) {
  var s = text.toLowerCase().replaceAll('ß', 'ss').replaceAll('æ', 'ae');
  for (final MapEntry(key: plain, value: accented) in _plain.entries) {
    for (final char in accented.split('')) {
      s = s.replaceAll(char, plain);
    }
  }
  return s
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
