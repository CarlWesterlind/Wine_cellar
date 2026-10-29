/// A sommelier's notes on a wine, suggested by AI from the label.
class SommelierInfo {
  const SommelierInfo({
    this.tastingProfile,
    this.foodPairings = const [],
    this.servingTemperature,
    this.decanting,
    this.producerInfo,
  });

  final String? tastingProfile;
  final List<String> foodPairings;
  final String? servingTemperature;
  final String? decanting;

  /// A few sentences about the producer.
  final String? producerInfo;

  bool get isEmpty =>
      tastingProfile == null &&
      foodPairings.isEmpty &&
      servingTemperature == null &&
      decanting == null &&
      producerInfo == null;

  /// The `sommelier` column of the `wines` table.
  Map<String, dynamic> toMap() => {
    'tasting_profile': tastingProfile,
    'food_pairings': foodPairings,
    'serving_temperature': servingTemperature,
    'decanting': decanting,
    'producer_info': producerInfo,
  };

  /// Reads the `sommelier` column, or the same fields in a label scan.
  /// Blank text becomes null. Throws [TypeError] for values of the wrong
  /// type; callers turn that into a [FormatException].
  factory SommelierInfo.fromMap(Map<String, dynamic> map) {
    String? text(Object? value) {
      final trimmed = (value as String?)?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return SommelierInfo(
      tastingProfile: text(map['tasting_profile']),
      foodPairings: [
        for (final food in map['food_pairings'] as List<dynamic>? ?? const [])
          ?text(food),
      ],
      servingTemperature: text(map['serving_temperature']),
      decanting: text(map['decanting']),
      producerInfo: text(map['producer_info']),
    );
  }
}
