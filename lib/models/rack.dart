import 'wine.dart';

/// A wine rack drawn as a grid on the cellar map: [shelves] rows with
/// [slotsPerShelf] places each. Wines are placed in it by their rack, shelf
/// and position fields.
class Rack {
  /// Throws [ArgumentError] for an empty name or a size outside 1–[maxSize].
  Rack({
    this.id,
    required String name,
    required this.shelves,
    required this.slotsPerShelf,
  }) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    _checkSize(shelves, 'shelves');
    _checkSize(slotsPerShelf, 'slotsPerShelf');
  }

  static const maxSize = 30;

  static void _checkSize(int value, String name) {
    if (value < 1 || value > maxSize) {
      throw ArgumentError.value(value, name, 'must be between 1 and $maxSize');
    }
  }

  /// Null until saved.
  final String? id;
  final String name;
  final int shelves;
  final int slotsPerShelf;

  int get capacity => shelves * slotsPerShelf;

  /// True if [wine] says it is in this rack. Names are compared without
  /// regard to case, so "a" and "A" are the same rack.
  bool holds(Wine wine) =>
      wine.rack?.trim().toLowerCase() == name.toLowerCase();

  /// Where [wine] is in this rack, counting from 1, or null if it is not in
  /// the rack or its shelf and position are not numbers inside the grid.
  ({int shelf, int slot})? placeOf(Wine wine) {
    if (!holds(wine)) return null;
    final shelf = int.tryParse(wine.shelf?.trim() ?? '');
    final slot = int.tryParse(wine.position?.trim() ?? '');
    if (shelf == null || slot == null) return null;
    if (shelf < 1 || shelf > shelves || slot < 1 || slot > slotsPerShelf) {
      return null;
    }
    return (shelf: shelf, slot: slot);
  }

  Rack withId(String id) =>
      Rack(id: id, name: name, shelves: shelves, slotsPerShelf: slotsPerShelf);

  /// Columns of the `racks` table.
  Map<String, dynamic> toMap() => {
    'name': name,
    'shelves': shelves,
    'slots_per_shelf': slotsPerShelf,
  };

  /// Throws [FormatException] for rows with missing or invalid values.
  factory Rack.fromMap(Map<String, dynamic> map) {
    try {
      return Rack(
        id: map['id'] as String?,
        name: map['name'] as String,
        shelves: map['shelves'] as int,
        slotsPerShelf: map['slots_per_shelf'] as int,
      );
    } on TypeError catch (e) {
      throw FormatException('Invalid rack: $e', map);
    } on ArgumentError catch (e) {
      throw FormatException('Invalid rack: ${e.message}', map);
    }
  }
}
