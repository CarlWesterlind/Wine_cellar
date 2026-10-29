import 'dart:typed_data';

import '../data/photo_storage.dart';
import '../data/wine_repository.dart';
import '../errors/error_messages.dart';
import '../models/wine.dart';
import 'loading_notifier.dart';

/// Holds the user's wines, their photos, and the current search and
/// filters.
class CellarController extends LoadingNotifier {
  CellarController(this._repository, this._photos, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final WineRepository _repository;
  final PhotoStorage _photos;
  final DateTime Function() _clock;

  List<Wine> _wines = const [];

  String _query = '';
  WineType? _typeFilter;
  DrinkingStatus? _statusFilter;

  /// [visibleWines], kept until the wines or filters change.
  List<Wine>? _visible;

  /// Where the wines are stored; also used for their tasting notes.
  WineRepository get repository => _repository;

  String get query => _query;
  WineType? get typeFilter => _typeFilter;
  DrinkingStatus? get statusFilter => _statusFilter;
  int get currentYear => _clock().year;

  bool get isEmpty => _wines.isEmpty;

  /// Wines matching the search and filters, sorted by name.
  List<Wine> get visibleWines => _visible ??= _filterAndSort();

  List<Wine> _filterAndSort() {
    final year = currentYear;
    final matching = _wines.where((wine) {
      if (!wine.matchesSearch(_query)) return false;
      if (_typeFilter != null && wine.type != _typeFilter) return false;
      if (_statusFilter != null && wine.drinkingStatus(year) != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
    matching.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return matching;
  }

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
    notifyListeners();
  }

  Future<void> load() => runLoad(() async {
    _wines = await _repository.fetchAll();
    _visible = null;
  });

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

  /// Removes one bottle from the stock.
  Future<void> drinkOne(Wine wine) async {
    if (wine.quantity == 0) return;
    await save(wine.withQuantity(wine.quantity - 1));
  }

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
