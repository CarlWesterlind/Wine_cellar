import '../lexicon/lexicon.dart';
import '../lexicon/normalize.dart';
import 'wine.dart';

/// Numbers about the bottles in the cellar. Only wines with bottles left
/// count. With a [Lexicon], grape synonyms count as one grape and a country
/// counts once however it was spelled, named in [languageCode].
class CellarStats {
  factory CellarStats(
    Iterable<Wine> wines, {
    required int year,
    Lexicon? lexicon,
    String languageCode = 'en',
  }) {
    final inStock = [
      for (final wine in wines)
        if (wine.quantity > 0) wine,
    ];
    final byType = Tally<WineType>();
    final byCountry = NameTally();
    final byGrape = NameTally();
    final byStatus = Tally<DrinkingStatus>();
    final grapeLabel = _grapeLabels(inStock, lexicon);
    var pricedBottles = 0;
    for (final wine in inStock) {
      byType.add(wine.type, wine.quantity);
      final country = wine.country;
      byCountry.addName(
        country == null
            ? null
            : lexicon?.countryFor(country)?.nameIn(languageCode) ?? country,
        wine.quantity,
      );
      // A blend counts for each of its grapes.
      for (final grape in wine.grapes) {
        byGrape.addName(grapeLabel(grape), wine.quantity);
      }
      byStatus.add(wine.drinkingStatus(year), wine.quantity);
      if (wine.price != null) pricedBottles += wine.quantity;
    }
    final value = inStock.fold(0.0, (sum, wine) => sum + wine.totalValue);
    return CellarStats._(
      wines: inStock.length,
      bottles: inStock.fold(0, (sum, wine) => sum + wine.quantity),
      value: value,
      averagePrice: pricedBottles == 0 ? null : value / pricedBottles,
      byType: byType,
      byCountry: byCountry,
      byGrape: byGrape,
      byStatus: byStatus,
      lastYear: [
        for (final wine in inStock)
          if (wine.drinkUntil == year) wine,
      ],
    );
  }

  /// Names each grape for the statistics: all names the wines use for the
  /// same lexicon grape, e.g. "Syrah / Shiraz".
  static String Function(String) _grapeLabels(
    List<Wine> wines,
    Lexicon? lexicon,
  ) {
    String key(String grape) =>
        lexicon?.grapeFor(grape)?.id ?? normalizeForSearch(grape);
    final spellings = <String, List<String>>{};
    for (final wine in wines) {
      for (final grape in wine.grapes) {
        final names = spellings.putIfAbsent(key(grape), () => []);
        if (!names.any(
          (n) => normalizeForSearch(n) == normalizeForSearch(grape),
        )) {
          names.add(grape.trim());
        }
      }
    }
    return (grape) => spellings[key(grape)]!.join(' / ');
  }

  CellarStats._({
    required this.wines,
    required this.bottles,
    required this.value,
    required this.averagePrice,
    required this.byType,
    required this.byCountry,
    required this.byGrape,
    required this.byStatus,
    required this.lastYear,
  });

  /// Wines with at least one bottle.
  final int wines;
  final int bottles;

  /// Price × bottles, for wines with a price.
  final double value;

  /// Per bottle, among bottles with a price; null if none has one.
  final double? averagePrice;

  final Tally<WineType> byType;
  final NameTally byCountry;
  final NameTally byGrape;
  final Tally<DrinkingStatus> byStatus;

  /// Wines whose drinking window ends this year.
  final List<Wine> lastYear;
}

/// Counts bottles per key, e.g. per wine type.
class Tally<K> {
  final _counts = <K, int>{};

  void add(K key, int count) => _counts[key] = (_counts[key] ?? 0) + count;

  int operator [](K key) => _counts[key] ?? 0;

  bool get isEmpty => _counts.isEmpty;

  /// The largest counts first; equal counts in the order first added.
  List<MapEntry<K, int>> get sorted {
    // List.sort is not stable, so sort by position as well.
    final indexed = _counts.entries.indexed.toList()
      ..sort((a, b) {
        final byCount = b.$2.value.compareTo(a.$2.value);
        return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
      });
    return [for (final (_, entry) in indexed) entry];
  }

  /// The [count] largest entries, and the sum of the rest (0 if none).
  (List<MapEntry<K, int>>, int) top(int count) {
    final all = sorted;
    if (all.length <= count) return (all, 0);
    final rest = all.skip(count).fold(0, (sum, e) => sum + e.value);
    return (all.take(count).toList(), rest);
  }
}

/// A [Tally] of typed names, e.g. countries. "France" and " france" count
/// as one, shown with the spelling seen first. Blank names are skipped.
class NameTally extends Tally<String> {
  final _spellings = <String, String>{};

  void addName(String? name, int count) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    add(_spellings.putIfAbsent(trimmed.toLowerCase(), () => trimmed), count);
  }
}
