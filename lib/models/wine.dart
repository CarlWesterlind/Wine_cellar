import 'dates.dart';

enum WineType { red, white, rose, sparkling, dessert, fortified }

/// Where a wine is relative to its drinking window in a given year.
enum DrinkingStatus { unknown, tooEarly, ready, pastPeak }

class Wine {
  /// Throws [ArgumentError] if a value is impossible, e.g. an empty name or a
  /// negative number of bottles.
  Wine({
    this.id,
    required this.name,
    this.producer,
    this.vintage,
    this.type = WineType.red,
    this.country,
    this.region,
    this.grapes = const [],
    this.quantity = 1,
    this.price,
    this.rack,
    this.shelf,
    this.position,
    this.drinkFrom,
    this.drinkUntil,
    DateTime? purchaseDate,
    this.purchasedFrom,
  }) : purchaseDate = purchaseDate == null ? null : dateOnly(purchaseDate) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must not be negative');
    }
    if (price != null && price! < 0) {
      throw ArgumentError.value(price, 'price', 'must not be negative');
    }
    if (drinkFrom != null && drinkUntil != null && drinkFrom! > drinkUntil!) {
      throw ArgumentError.value(
        drinkUntil,
        'drinkUntil',
        'must not be earlier than drinkFrom ($drinkFrom)',
      );
    }
  }

  /// Null until the wine has been saved.
  final String? id;
  final String name;
  final String? producer;
  final int? vintage;
  final WineType type;
  final String? country;
  final String? region;
  final List<String> grapes;
  final int quantity;

  /// Price per bottle.
  final double? price;

  // Location in the cellar.
  final String? rack;
  final String? shelf;
  final String? position;

  // Drinking window, as years.
  final int? drinkFrom;
  final int? drinkUntil;

  /// The day the bottles were bought, without time of day.
  final DateTime? purchaseDate;

  /// Shop or importer the bottles were bought from.
  final String? purchasedFrom;

  bool get hasLocation => rack != null || shelf != null || position != null;

  bool get hasPurchaseInfo => purchaseDate != null || purchasedFrom != null;

  double get totalValue => (price ?? 0) * quantity;

  DrinkingStatus drinkingStatus(int year) {
    final from = drinkFrom, until = drinkUntil;
    if (from == null && until == null) return DrinkingStatus.unknown;
    if (from != null && year < from) return DrinkingStatus.tooEarly;
    if (until != null && year > until) return DrinkingStatus.pastPeak;
    return DrinkingStatus.ready;
  }

  Wine withQuantity(int quantity) => _copy(quantity: quantity);

  Wine withId(String id) => _copy(id: id);

  Wine _copy({String? id, int? quantity}) => Wine(
    id: id ?? this.id,
    name: name,
    producer: producer,
    vintage: vintage,
    type: type,
    country: country,
    region: region,
    grapes: grapes,
    quantity: quantity ?? this.quantity,
    price: price,
    rack: rack,
    shelf: shelf,
    position: position,
    drinkFrom: drinkFrom,
    drinkUntil: drinkUntil,
    purchaseDate: purchaseDate,
    purchasedFrom: purchasedFrom,
  );

  /// Columns of the `wines` table (see supabase/migrations). `id` and
  /// `user_id` are set by the database.
  Map<String, dynamic> toMap() => {
    'name': name,
    'producer': producer,
    'vintage': vintage,
    'type': type.name,
    'country': country,
    'region': region,
    'grapes': grapes,
    'quantity': quantity,
    'price': price,
    'rack': rack,
    'shelf': shelf,
    'position': position,
    'drink_from': drinkFrom,
    'drink_until': drinkUntil,
    'purchase_date': purchaseDate == null ? null : toIsoDate(purchaseDate!),
    'purchased_from': purchasedFrom,
  };

  /// Reads a row from the database. Throws [FormatException] if the row is
  /// missing fields or has values of the wrong type.
  factory Wine.fromMap(Map<String, dynamic> map) {
    try {
      final purchaseDate = map['purchase_date'] as String?;
      return Wine(
        id: map['id'] as String?,
        name: map['name'] as String,
        producer: map['producer'] as String?,
        vintage: map['vintage'] as int?,
        type: WineType.values.asNameMap()[map['type']] ?? WineType.red,
        country: map['country'] as String?,
        region: map['region'] as String?,
        grapes: (map['grapes'] as List<dynamic>? ?? const []).cast<String>(),
        quantity: map['quantity'] as int? ?? 0,
        price: (map['price'] as num?)?.toDouble(),
        rack: map['rack'] as String?,
        shelf: map['shelf'] as String?,
        position: map['position'] as String?,
        drinkFrom: map['drink_from'] as int?,
        drinkUntil: map['drink_until'] as int?,
        purchaseDate: purchaseDate == null ? null : parseIsoDate(purchaseDate),
        purchasedFrom: map['purchased_from'] as String?,
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid wine data: $e', map);
    } on ArgumentError catch (e) {
      throw FormatException('Invalid wine data: ${e.message}', map);
    }
  }

  /// True if [query] appears in the name, producer, region, country, a grape
  /// or the shop it was bought from.
  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      producer,
      region,
      country,
      purchasedFrom,
      ...grapes,
    ].whereType<String>().any((field) => field.toLowerCase().contains(q));
  }
}
