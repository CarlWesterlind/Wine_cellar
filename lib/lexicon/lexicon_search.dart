import 'lexicon.dart';
import 'normalize.dart';

/// One line in a suggestion list: [text] to fill in, an optional [detail]
/// shown after it (where a place lies, which grape a synonym belongs to),
/// and the lexicon [entry] it came from.
class Suggestion<T> {
  const Suggestion(this.text, this.entry, {this.detail});

  final String text;
  final String? detail;
  final T entry;

  @override
  String toString() => detail == null ? text : '$text ($detail)';
}

/// Something that can be suggested: one name of one lexicon entry, with
/// the normalized names that find it.
class _Option<T> {
  _Option(this.entry, this.order, List<String> names, {this.synonymOf})
    : searchNames = [for (final name in names) normalizeForSearch(name)],
      text = names.first;

  final T entry;

  /// Position in the lexicon file; well-known entries come first there.
  final int order;
  final String text;
  final List<String> searchNames;

  /// For a grape synonym, the grape's own name.
  final String? synonymOf;
}

/// Finds lexicon entries for what the user has typed so far, forgiving
/// typos, accents and case.
class LexiconSearch {
  LexiconSearch(this.lexicon)
    : _grapes = [
        for (final (i, grape) in lexicon.grapes.indexed) ...[
          _Option(grape, i, [grape.name]),
          for (final synonym in grape.synonyms)
            _Option(grape, i, [synonym.name], synonymOf: grape.name),
        ],
      ],
      _places = [
        for (final (i, place) in lexicon.places.indexed)
          _Option(place, i, [place.name, ...place.aliases]),
      ],
      _countries = [
        for (final (i, country) in lexicon.countries.indexed)
          _Option(country, i, [
            country.names['en']!,
            ...country.names.values,
            ...country.aliases,
          ]),
      ],
      _blends = [
        for (final (i, blend) in lexicon.blends.indexed)
          _Option(blend, i, [
            blend.name,
            ...blend.names.values,
            ...blend.aliases,
          ]),
      ],
      _classifications = [
        for (final (i, c) in lexicon.classifications.indexed)
          _Option(c, i, [c.name, ...c.aliases]),
      ],
      _sweetness = [
        for (final (i, s) in lexicon.sweetness.indexed) _Option(s, i, [s.term]),
      ];

  final Lexicon lexicon;

  /// At most this many suggestions are shown.
  static const limit = 8;

  final List<_Option<LexGrape>> _grapes;
  final List<_Option<LexPlace>> _places;
  final List<_Option<LexCountry>> _countries;
  final List<_Option<LexBlend>> _blends;
  final List<_Option<LexClassification>> _classifications;
  final List<_Option<LexSweetness>> _sweetness;

  /// Grapes and their synonyms. Names usual in [countryId] come first, e.g.
  /// Shiraz before Syrah for Australia.
  List<Suggestion<LexGrape>> grapes(String query, {String? countryId}) =>
      _search(
        query,
        _grapes,
        priority: (option) {
          final grape = option.entry;
          final preferredIn = option.synonymOf == null
              ? grape.preferredIn
              : grape.synonyms
                    .firstWhere((s) => s.name == option.text)
                    .preferredIn;
          return countryId != null && preferredIn.contains(countryId) ? 0 : 1;
        },
        toSuggestion: (option) => Suggestion(
          option.text,
          option.entry,
          detail: option.synonymOf == null ? null : '= ${option.synonymOf}',
        ),
      );

  /// Places, optionally only of one [level] and only inside [withinId].
  /// Places in [countryId] come first. The detail shows where the place
  /// lies, with the country in [languageCode].
  List<Suggestion<LexPlace>> places(
    String query, {
    PlaceLevel? level,
    String? countryId,
    String? withinId,
    String languageCode = 'en',
  }) => _search(
    query,
    _places,
    where: (option) {
      final place = option.entry;
      if (level != null && place.level != level) return false;
      if (withinId != null &&
          !lexicon.pathOf(place).skip(1).any((p) => p.id == withinId)) {
        return false;
      }
      return true;
    },
    priority: (option) =>
        countryId != null && lexicon.countryIdOf(option.entry) == countryId
        ? 0
        : 1,
    toSuggestion: (option) {
      final place = option.entry;
      final country = lexicon.countryById(lexicon.countryIdOf(place));
      return Suggestion(
        place.name,
        place,
        detail: [
          for (final p in lexicon.pathOf(place).skip(1)) p.name,
          if (country != null) country.nameIn(languageCode),
        ].join(' · '),
      );
    },
  );

  /// Countries found by any of their names, shown in [languageCode].
  List<Suggestion<LexCountry>> countries(String query, String languageCode) =>
      _search(
        query,
        _countries,
        toSuggestion: (option) =>
            Suggestion(option.entry.nameIn(languageCode), option.entry),
      );

  List<Suggestion<LexBlend>> blends(String query, String languageCode) =>
      _search(
        query,
        _blends,
        toSuggestion: (option) =>
            Suggestion(option.entry.nameIn(languageCode), option.entry),
      );

  /// Classifications; those used at [placeId] come first, then those of
  /// [countryId], then those used anywhere.
  List<Suggestion<LexClassification>> classifications(
    String query, {
    String? countryId,
    String? placeId,
  }) {
    final place = placeId == null ? null : lexicon.placeById(placeId);
    final placeIds = place == null
        ? const <String>{}
        : {for (final p in lexicon.pathOf(place)) p.id};
    return _search(
      query,
      _classifications,
      priority: (option) {
        final c = option.entry;
        if (c.places.any(placeIds.contains)) return 0;
        if (countryId != null && c.countries.contains(countryId)) return 1;
        return c.countries.isEmpty ? 2 : 3;
      },
      toSuggestion: (option) => Suggestion(option.entry.name, option.entry),
    );
  }

  /// Sweetness words; those used in [countryId] come first.
  List<Suggestion<LexSweetness>> sweetness(String query, {String? countryId}) =>
      _search(
        query,
        _sweetness,
        priority: (option) {
          final countries = option.entry.countries;
          if (countryId != null && countries.contains(countryId)) return 0;
          return countries.isEmpty ? 1 : 2;
        },
        toSuggestion: (option) => Suggestion(option.entry.term, option.entry),
      );

  List<Suggestion<T>> _search<T>(
    String query,
    List<_Option<T>> options, {
    bool Function(_Option<T>)? where,
    int Function(_Option<T>)? priority,
    required Suggestion<T> Function(_Option<T>) toSuggestion,
  }) {
    final q = normalizeForSearch(query);
    // Text with no letters or digits (an emoji, punctuation) finds nothing.
    if (q.isEmpty && query.trim().isNotEmpty) return const [];

    final matches = <(int, int, int, _Option<T>)>[];
    for (final option in options) {
      if (where != null && !where(option)) continue;
      int? best;
      for (final name in option.searchNames) {
        final rank = _rank(name, q);
        if (rank != null && (best == null || rank < best)) best = rank;
        if (best == 0) break;
      }
      if (best == null) continue;
      matches.add((best, priority?.call(option) ?? 0, option.order, option));
    }
    matches.sort((a, b) {
      for (final (x, y) in [(a.$1, b.$1), (a.$2, b.$2), (a.$3, b.$3)]) {
        if (x != y) return x.compareTo(y);
      }
      return 0;
    });

    final seen = <String>{};
    final result = <Suggestion<T>>[];
    for (final (_, _, _, option) in matches) {
      final suggestion = toSuggestion(option);
      if (!seen.add(suggestion.text)) continue;
      result.add(suggestion);
      if (result.length == limit) break;
    }
    return result;
  }

  /// How well [name] matches [q], both normalized: 0 starts with it,
  /// 1 a word starts with it, 2 contains it, 3 close with a typo, or null.
  static int? _rank(String name, String q) {
    if (q.isEmpty || name.startsWith(q)) return 0;
    if (name.contains(' $q')) return 1;
    if (name.contains(q)) return 2;
    if (q.length < 3) return null;
    final max = q.length <= 5 ? 1 : 2;
    // Compare with the start of each word, a little shorter or longer.
    for (var start = 0; start < name.length; start++) {
      if (start > 0 && name[start - 1] != ' ') continue;
      if (name[start] != q[0]) continue;
      for (var length = q.length - max; length <= q.length + max; length++) {
        if (length < 1 || start + length > name.length) continue;
        final part = name.substring(start, start + length);
        if (editDistance(q, part, max) <= max) return 3;
      }
    }
    return null;
  }
}
