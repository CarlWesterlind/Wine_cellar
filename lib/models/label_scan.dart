import '../lexicon/lexicon.dart';
import 'sommelier_info.dart';
import 'wine.dart';

enum ScanConfidence { high, medium, low }

/// What the AI read from a label photo. Every field may be missing.
class LabelScan {
  const LabelScan({
    this.name,
    this.producer,
    this.vintage,
    this.type,
    this.country,
    this.region,
    this.subregion,
    this.appellation,
    this.vineyard,
    this.grapes = const [],
    this.grapesAreBlend = false,
    this.classifications = const [],
    this.sweetness,
    this.drinkFrom,
    this.drinkUntil,
    this.sommelier,
    this.confidence = ScanConfidence.medium,
  });

  final String? name;
  final String? producer;
  final int? vintage;
  final WineType? type;
  final String? country;
  final String? region;
  final String? subregion;
  final String? appellation;
  final String? vineyard;
  final List<String> grapes;
  final bool grapesAreBlend;
  final List<String> classifications;
  final String? sweetness;
  final int? drinkFrom;
  final int? drinkUntil;
  final SommelierInfo? sommelier;
  final ScanConfidence confidence;

  /// This scan with names respelled by the given functions, e.g. to the
  /// lexicon's spelling. A function returning null keeps the name as read.
  LabelScan respelled({
    String? Function(String)? country,
    String? Function(String, PlaceLevel)? place,
    String? Function(String)? grape,
    String? Function(String)? classification,
    String? Function(String)? sweetnessTerm,
  }) {
    String? spell(String? text, String? Function(String)? respell) =>
        text == null ? null : respell?.call(text) ?? text;
    String? spellPlace(String? text, PlaceLevel level) =>
        text == null ? null : place?.call(text, level) ?? text;
    return LabelScan(
      name: name,
      producer: producer,
      vintage: vintage,
      type: type,
      country: spell(this.country, country),
      region: spellPlace(region, PlaceLevel.region),
      subregion: spellPlace(subregion, PlaceLevel.subregion),
      appellation: spellPlace(appellation, PlaceLevel.appellation),
      vineyard: spellPlace(vineyard, PlaceLevel.vineyard),
      grapes: [for (final g in grapes) spell(g, grape)!],
      grapesAreBlend: grapesAreBlend,
      classifications: [
        for (final c in classifications) spell(c, classification)!,
      ],
      sweetness: spell(sweetness, sweetnessTerm),
      drinkFrom: drinkFrom,
      drinkUntil: drinkUntil,
      sommelier: sommelier,
      confidence: confidence,
    );
  }

  /// Reads the `scan` object from the scan-label function. Throws
  /// [FormatException] if it doesn't have the expected shape.
  factory LabelScan.fromMap(Map<String, dynamic> map) {
    try {
      final sommelier = SommelierInfo.fromMap({
        ...?map['sommelier'] as Map<String, dynamic>?,
        'producer_info': map['producer_info'],
      });
      return LabelScan(
        name: map['name'] as String?,
        producer: map['producer'] as String?,
        vintage: map['vintage'] as int?,
        type: WineType.values.asNameMap()[map['type']],
        country: map['country'] as String?,
        region: map['region'] as String?,
        // Missing from answers of older versions of the function.
        subregion: map['subregion'] as String?,
        appellation: map['appellation'] as String?,
        vineyard: map['vineyard'] as String?,
        grapes: (map['grapes'] as List<dynamic>? ?? const []).cast<String>(),
        grapesAreBlend: map['grapes_blend'] as bool? ?? false,
        classifications: (map['classifications'] as List<dynamic>? ?? const [])
            .cast<String>(),
        sweetness: map['sweetness'] as String?,
        drinkFrom: map['drink_from'] as int?,
        drinkUntil: map['drink_until'] as int?,
        sommelier: sommelier.isEmpty ? null : sommelier,
        confidence:
            ScanConfidence.values.asNameMap()[map['confidence']] ??
            ScanConfidence.low,
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid label scan: $e', map);
    }
  }
}
