import 'normalize.dart';

/// How big a place is: a region holds subregions and appellations, an
/// appellation holds vineyards.
enum PlaceLevel { region, subregion, appellation, vineyard }

/// The simple sweetness scale that label words like "Brut" or "trocken"
/// map to.
enum SweetnessScale { dry, offDry, mediumSweet, sweet }

class LexCountry {
  LexCountry({required this.id, required this.names, this.aliases = const []});

  /// ISO code, e.g. "FR".
  final String id;

  /// Language code ("sv", "da", "nb", "en") to the country's name.
  final Map<String, String> names;
  final List<String> aliases;

  /// The name in [languageCode], or English.
  String nameIn(String languageCode) => names[languageCode] ?? names['en']!;
}

class LexPlace {
  LexPlace({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    this.countryId,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final PlaceLevel level;

  /// Null for regions.
  final String? parentId;

  /// Set on regions only; other places get it from their region.
  final String? countryId;
  final List<String> aliases;
}

/// Another name for a grape, e.g. Shiraz for Syrah.
class LexSynonym {
  LexSynonym({required this.name, this.preferredIn = const []});

  final String name;

  /// Countries where this name is the usual one and is suggested first.
  final List<String> preferredIn;
}

class LexGrape {
  LexGrape({
    required this.id,
    required this.name,
    required this.color,
    this.preferredIn = const [],
    this.synonyms = const [],
  });

  final String id;
  final String name;

  /// "red", "white" or "pink" (the skin).
  final String color;
  final List<String> preferredIn;
  final List<LexSynonym> synonyms;

  Iterable<String> get allNames => [name, for (final s in synonyms) s.name];
}

/// A named blend of grapes, e.g. "Bordeaux blend" or "GSM".
class LexBlend {
  LexBlend({
    required this.id,
    required this.name,
    this.names = const {},
    this.aliases = const [],
  });

  final String id;

  /// The English name; [names] holds other languages.
  final String name;
  final Map<String, String> names;
  final List<String> aliases;

  String nameIn(String languageCode) => names[languageCode] ?? name;
}

/// A label term about ripeness, site, quality or ageing, e.g. Smaragd,
/// Premier Cru or Gran Reserva.
class LexClassification {
  LexClassification({
    required this.id,
    required this.name,
    required this.kind,
    this.countries = const [],
    this.places = const [],
    this.aliases = const [],
  });

  final String id;
  final String name;

  /// "ripeness", "site", "quality" or "ageing".
  final String kind;

  /// Where the term is used; empty means anywhere.
  final List<String> countries;
  final List<String> places;
  final List<String> aliases;
}

/// A sweetness word from a label, e.g. "Brut" or "halbtrocken".
class LexSweetness {
  LexSweetness({
    required this.term,
    required this.scale,
    this.countries = const [],
  });

  final String term;
  final SweetnessScale scale;
  final List<String> countries;
}

/// Grapes, places, classifications and sweetness words, for spelling help.
/// Read from `assets/lexicon/lexicon.json`, built by
/// `tool/build_lexicon.dart`.
class Lexicon {
  Lexicon._({
    required this.format,
    required this.version,
    required this.countries,
    required this.places,
    required this.grapes,
    required this.blends,
    required this.classifications,
    required this.sweetness,
  }) {
    for (final place in places) {
      if (_places.containsKey(place.id)) {
        throw FormatException('Duplicate place id', place.id);
      }
      _places[place.id] = place;
    }
    for (final place in places) {
      _checkParent(place);
      for (final name in [place.name, ...place.aliases]) {
        _placesByName
            .putIfAbsent(normalizeForSearch(name), () => [])
            .add(place);
      }
    }
    for (final country in countries) {
      for (final name in [...country.names.values, ...country.aliases]) {
        _countriesByName.putIfAbsent(normalizeForSearch(name), () => country);
      }
    }
    for (final grape in grapes) {
      for (final name in grape.allNames) {
        _grapesByName.putIfAbsent(normalizeForSearch(name), () => grape);
      }
    }
    for (final term in sweetness) {
      _sweetnessByTerm.putIfAbsent(normalizeForSearch(term.term), () => term);
    }
  }

  /// The file format this app can read.
  static const supportedFormat = 1;

  /// Throws [FormatException] if [json] is not a valid lexicon.
  factory Lexicon.fromJson(Map<String, dynamic> json) {
    try {
      List<String> strings(Object? list) =>
          (list as List<dynamic>? ?? const []).cast<String>();
      Map<String, String> names(Object? map) =>
          (map as Map<String, dynamic>? ?? const {}).cast<String, String>();
      List<Map<String, dynamic>> items(String key) =>
          (json[key] as List<dynamic>).cast<Map<String, dynamic>>();

      return Lexicon._(
        format: json['format'] as int,
        version: json['version'] as int,
        countries: [
          for (final c in items('countries'))
            LexCountry(
              id: c['id'] as String,
              names: names(c['names']),
              aliases: strings(c['aliases']),
            ),
        ],
        places: [
          for (final p in items('places'))
            LexPlace(
              id: p['id'] as String,
              name: p['name'] as String,
              level: PlaceLevel.values.byName(p['level'] as String),
              parentId: p['parent'] as String?,
              countryId: p['country'] as String?,
              aliases: strings(p['aliases']),
            ),
        ],
        grapes: [
          for (final g in items('grapes'))
            LexGrape(
              id: g['id'] as String,
              name: g['name'] as String,
              color: g['color'] as String,
              preferredIn: strings(g['preferredIn']),
              synonyms: [
                for (final s
                    in (g['synonyms'] as List<dynamic>? ?? const [])
                        .cast<Map<String, dynamic>>())
                  LexSynonym(
                    name: s['name'] as String,
                    preferredIn: strings(s['preferredIn']),
                  ),
              ],
            ),
        ],
        blends: [
          for (final b in items('blends'))
            LexBlend(
              id: b['id'] as String,
              name: b['name'] as String,
              names: names(b['names']),
              aliases: strings(b['aliases']),
            ),
        ],
        classifications: [
          for (final c in items('classifications'))
            LexClassification(
              id: c['id'] as String,
              name: c['name'] as String,
              kind: c['kind'] as String,
              countries: strings(c['countries']),
              places: strings(c['places']),
              aliases: strings(c['aliases']),
            ),
        ],
        sweetness: [
          for (final s in items('sweetness'))
            LexSweetness(
              term: s['term'] as String,
              scale: SweetnessScale.values.byName(s['scale'] as String),
              countries: strings(s['countries']),
            ),
        ],
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid lexicon: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Invalid lexicon: ${e.message}');
    }
  }

  final int format;
  final int version;
  final List<LexCountry> countries;
  final List<LexPlace> places;
  final List<LexGrape> grapes;
  final List<LexBlend> blends;
  final List<LexClassification> classifications;
  final List<LexSweetness> sweetness;

  final _places = <String, LexPlace>{};
  final _placesByName = <String, List<LexPlace>>{};
  final _countriesByName = <String, LexCountry>{};
  final _grapesByName = <String, LexGrape>{};
  final _sweetnessByTerm = <String, LexSweetness>{};

  void _checkParent(LexPlace place) {
    final parentId = place.parentId;
    if (place.level == PlaceLevel.region) {
      if (place.countryId == null || parentId != null) {
        throw FormatException(
          'A region needs a country and no parent',
          place.id,
        );
      }
      return;
    }
    final parent = parentId == null ? null : _places[parentId];
    if (parent == null || parent.level.index >= place.level.index) {
      throw FormatException('Missing or wrong parent', place.id);
    }
  }

  LexPlace? placeById(String id) => _places[id];

  /// [place] and the places it lies in, the region last.
  List<LexPlace> pathOf(LexPlace place) {
    final path = [place];
    var current = place;
    while (current.parentId != null) {
      current = _places[current.parentId]!;
      path.add(current);
    }
    return path;
  }

  /// The place called [name] (or one of its other names), preferring
  /// [level] and places inside [withinId] when several share the name.
  LexPlace? placeNamed(String name, {PlaceLevel? level, String? withinId}) {
    final matches = _placesByName[normalizeForSearch(name)] ?? const [];
    final candidates = [
      for (final p in matches)
        if (level == null || p.level == level) p,
    ];
    if (withinId != null) {
      for (final p in candidates) {
        if (pathOf(p).any((a) => a.id == withinId)) return p;
      }
    }
    return candidates.firstOrNull;
  }

  /// The country [place] lies in.
  String countryIdOf(LexPlace place) => pathOf(place).last.countryId!;

  LexCountry? countryById(String id) =>
      countries.where((c) => c.id == id).firstOrNull;

  /// The country called [text] in any language or spelling, e.g. "Italia".
  LexCountry? countryFor(String text) =>
      _countriesByName[normalizeForSearch(text)];

  /// The grape called [name], by its own name or a synonym.
  LexGrape? grapeFor(String name) => _grapesByName[normalizeForSearch(name)];

  LexSweetness? sweetnessFor(String term) =>
      _sweetnessByTerm[normalizeForSearch(term)];
}
