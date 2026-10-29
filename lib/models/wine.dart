enum WineType { red, white, rose, sparkling, dessert, fortified }

/// Where a wine is relative to its drinking window in a given year.
enum DrinkingStatus { unknown, tooEarly, ready, pastPeak }

class Wine {
  const Wine({
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
    this.notes,
  });

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

  final String? notes;

  bool get hasLocation => rack != null || shelf != null || position != null;

  double get totalValue => (price ?? 0) * quantity;

  DrinkingStatus drinkingStatus(int year) {
    final from = drinkFrom, until = drinkUntil;
    if (from == null && until == null) return DrinkingStatus.unknown;
    if (from != null && year < from) return DrinkingStatus.tooEarly;
    if (until != null && year > until) return DrinkingStatus.pastPeak;
    return DrinkingStatus.ready;
  }

  Wine withQuantity(int quantity) => Wine(
    id: id,
    name: name,
    producer: producer,
    vintage: vintage,
    type: type,
    country: country,
    region: region,
    grapes: grapes,
    quantity: quantity,
    price: price,
    rack: rack,
    shelf: shelf,
    position: position,
    drinkFrom: drinkFrom,
    drinkUntil: drinkUntil,
    notes: notes,
  );

  Wine withId(String id) => Wine(
    id: id,
    name: name,
    producer: producer,
    vintage: vintage,
    type: type,
    country: country,
    region: region,
    grapes: grapes,
    quantity: quantity,
    price: price,
    rack: rack,
    shelf: shelf,
    position: position,
    drinkFrom: drinkFrom,
    drinkUntil: drinkUntil,
    notes: notes,
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
    'notes': notes,
  };

  factory Wine.fromMap(Map<String, dynamic> map) => Wine(
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
    notes: map['notes'] as String?,
  );

  /// True if [query] appears in the name, producer, region, country or a grape.
  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      producer,
      region,
      country,
      ...grapes,
    ].whereType<String>().any((field) => field.toLowerCase().contains(q));
  }
}
