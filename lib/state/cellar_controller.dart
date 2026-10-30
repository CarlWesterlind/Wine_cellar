import 'package:flutter/foundation.dart';

import '../data/photo_storage.dart';
import '../data/wine_repository.dart';
import '../errors/error_messages.dart';
import '../models/cellar_stats.dart';
import '../models/consumed_bottle.dart';
import '../models/rack.dart';
import '../models/wine.dart';
import 'loading_notifier.dart';

/// Holds the user's wines, their photos and drinking history, the racks of
/// the cellar map, and the current search and filters.
class CellarController extends LoadingNotifier {
  CellarController(this._repository, this._photos, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final WineRepository _repository;
  final PhotoStorage _photos;
  final DateTime Function() _clock;

  List<Wine> _wines = const [];
  List<ConsumedBottle> _history = const [];
  List<Rack> _racks = const [];

  String _query = '';
  WineType? _typeFilter;
  DrinkingStatus? _statusFilter;

  /// [visibleWines], kept until the wines or filters change.
  List<Wine>? _visible;
  CellarStats? _stats;

  /// Where the wines are stored; also used for their tasting notes.
  WineRepository get repository => _repository;

  String get query => _query;
  WineType? get typeFilter => _typeFilter;
  DrinkingStatus? get statusFilter => _statusFilter;
  int get currentYear => _clock().year;

  bool get isEmpty => _wines.isEmpty;

  /// Wines matching the search and filters, sorted by name.
  List<Wine> get visibleWines => _visible ??= _filterAndSort();

  /// Every wine, sorted by name.
  List<Wine> get allWines => _sortByName(_wines);

  List<Wine> _filterAndSort() {
    final year = currentYear;
    final matching = _wines.where((wine) {
      if (!wine.matchesSearch(_query)) return false;
      if (_typeFilter != null && wine.type != _typeFilter) return false;
      if (_statusFilter != null && wine.drinkingStatus(year) != _statusFilter) {
        return false;
      }
      return true;
    });
    return _sortByName(matching);
  }

  static List<Wine> _sortByName(Iterable<Wine> wines) =>
      wines.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Bottles drunk, newest first.
  List<ConsumedBottle> get history => _history;

  /// Bottles drunk of one wine, newest first.
  List<ConsumedBottle> historyOf(String wineId) =>
      _history.where((b) => b.wineId == wineId).toList();

  /// Sorted by name.
  List<Rack> get racks => _racks;

  CellarStats get stats => _stats ??= CellarStats(_wines, year: currentYear);

  int get totalBottles => _wines.fold(0, (sum, w) => sum + w.quantity);

  double get totalValue => _wines.fold(0, (sum, w) => sum + w.totalValue);

  Wine? byId(String id) {
    for (final wine in _wines) {
      if (wine.id == id) return wine;
    }
    return null;
  }

  /// Something changed that affects [visibleWines].
  void _changed() {
    _visible = null;
    _stats = null;
    notifyListeners();
  }

  Future<void> load() => runLoad(() async {
    final (wines, history, racks) = await (
      _repository.fetchAll(),
      _repository.fetchHistory(),
      _repository.fetchRacks(),
    ).wait;
    _wines = wines;
    _setHistory(history.reversed);
    _setRacks(racks);
    _visible = null;
    _stats = null;
  });

  /// Sorts [history], given last saved first, by date. Bottles from the
  /// same day stay last saved first.
  void _setHistory(Iterable<ConsumedBottle> history) {
    final sorted = history.toList();
    mergeSort(sorted, compare: ConsumedBottle.newestFirst);
    _history = List.unmodifiable(sorted);
  }

  void _setRacks(Iterable<Rack> racks) {
    final sorted = racks.toList();
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _racks = List.unmodifiable(sorted);
  }

  void setQuery(String query) {
    _query = query;
    _changed();
  }

  void setTypeFilter(WineType? type) {
    _typeFilter = type;
    _changed();
  }

  void setStatusFilter(DrinkingStatus? status) {
    _statusFilter = status;
    _changed();
  }

  void clearFilters() {
    _query = '';
    _typeFilter = null;
    _statusFilter = null;
    _changed();
  }

  /// Adds [wine] if it has no id yet, otherwise updates it. A [newPhoto]
  /// is stored and replaces the wine's photo. A photo the wine no longer
  /// uses is deleted.
  Future<Wine> save(Wine wine, {Uint8List? newPhoto}) async {
    final oldPhoto = wine.id == null ? null : byId(wine.id!)?.photoPath;
    String? uploaded;
    if (newPhoto != null) {
      uploaded = await _photos.save(newPhoto);
      wine = wine.withPhotoPath(uploaded);
    }

    final Wine saved;
    try {
      saved = wine.id == null
          ? await _repository.add(wine)
          : await _repository.update(wine);
    } catch (_) {
      // Don't leave a photo behind that no wine uses.
      if (uploaded != null) await _deletePhotoQuietly(uploaded);
      rethrow;
    }

    if (oldPhoto != null && oldPhoto != saved.photoPath) {
      await _deletePhotoQuietly(oldPhoto);
    }
    _wines = [
      for (final w in _wines)
        if (w.id != saved.id) w,
      saved,
    ];
    _changed();
    return saved;
  }

  /// Deletes [wine] with its tasting notes and photo.
  Future<void> delete(Wine wine) async {
    await _repository.delete(wine.id!);
    if (wine.photoPath != null) await _deletePhotoQuietly(wine.photoPath!);
    _wines = _wines.where((w) => w.id != wine.id).toList();
    _changed();
  }

  /// Removes one bottle from the stock and adds it to the history. Throws
  /// [StateError] if there are no bottles left.
  Future<ConsumedBottle> drinkOne(
    Wine wine, {
    DateTime? date,
    String? occasion,
  }) async {
    if (wine.quantity == 0) throw StateError('No bottles of ${wine.name}');
    final bottle = await _repository.addConsumed(
      ConsumedBottle(
        wineId: wine.id!,
        date: date ?? _clock(),
        occasion: occasion,
      ),
    );
    try {
      await save(wine.withQuantity(wine.quantity - 1));
    } catch (_) {
      // Don't keep history for a bottle that is still in stock.
      await _repository.deleteConsumed(bottle.id!).catchError(logError);
      rethrow;
    }
    _setHistory([bottle, ..._history]);
    _changed();
    return bottle;
  }

  /// Takes [bottle] out of the history and puts it back in stock.
  Future<void> undoDrink(ConsumedBottle bottle) async {
    await _repository.deleteConsumed(bottle.id!);
    _setHistory(_history.where((b) => b.id != bottle.id));
    // Show the shorter history even if the stock update fails.
    _changed();
    final wine = byId(bottle.wineId);
    if (wine != null) await save(wine.withQuantity(wine.quantity + 1));
  }

  /// Adds [rack] if it has no id yet, otherwise updates it. A renamed rack
  /// takes its wines along.
  Future<Rack> saveRack(Rack rack) async {
    final before = _racks.where((r) => r.id == rack.id).firstOrNull;
    final saved = rack.id == null
        ? await _repository.addRack(rack)
        : await _repository.updateRack(rack);
    if (before != null && before.name != saved.name) {
      for (final wine in _wines.where(before.holds).toList()) {
        await save(wine.withRack(saved.name));
      }
    }
    _setRacks([..._racks.where((r) => r.id != saved.id), saved]);
    _changed();
    return saved;
  }

  Future<void> deleteRack(Rack rack) async {
    await _repository.deleteRack(rack.id!);
    _setRacks(_racks.where((r) => r.id != rack.id));
    _changed();
  }

  /// Moves [wine] to [shelf] and [slot] of [rack].
  Future<Wine> place(
    Wine wine,
    Rack rack, {
    required int shelf,
    required int slot,
  }) => save(
    wine.withLocation(rack: rack.name, shelf: '$shelf', position: '$slot'),
  );

  /// A photo that fails to delete only wastes space, so the error is logged
  /// rather than shown.
  Future<void> _deletePhotoQuietly(String path) async {
    try {
      await _photos.delete(path);
    } catch (error, stack) {
      logError(error, stack);
    }
  }
}
