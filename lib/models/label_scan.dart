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
    this.grapes = const [],
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
  final List<String> grapes;
  final int? drinkFrom;
  final int? drinkUntil;
  final SommelierInfo? sommelier;
  final ScanConfidence confidence;

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
        grapes: (map['grapes'] as List<dynamic>? ?? const []).cast<String>(),
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
