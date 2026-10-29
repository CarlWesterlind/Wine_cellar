import 'package:flutter/foundation.dart';

import '../data/wine_repository.dart';
import '../models/wine.dart';

/// Holds the user's wines and the current search and filters.
class CellarController extends ChangeNotifier {
  CellarController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final WineRepository _repository;
  final DateTime Function() _clock;

  List<Wine> _wines = const [];
  bool _loading = false;
  Object? _error;

  String _query = '';
  WineType? _typeFilter;
  DrinkingStatus? _statusFilter;

  bool get loading => _loading;
  Object? get error => _error;
  String get query => _query;
  WineType? get typeFilter => _typeFilter;
  DrinkingStatus? get statusFilter => _statusFilter;
  int get currentYear => _clock().year;

  bool get isEmpty => _wines.isEmpty;

  /// Wines matching the search and filters, sorted by name.
  List<Wine> get visibleWines {
    final year = currentYear;
    return _wines
        .where((w) => w.matchesSearch(_query))
        .where((w) => _typeFilter == null || w.type == _typeFilter)
        .where(
          (w) =>
              _statusFilter == null || w.drinkingStatus(year) == _statusFilter,
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  int get totalBottles => _wines.fold(0, (sum, w) => sum + w.quantity);

  double get totalValue => _wines.fold(0, (sum, w) => sum + w.totalValue);

  Wine? byId(String id) {
    for (final wine in _wines) {
      if (wine.id == id) return wine;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _wines = await _repository.fetchAll();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setTypeFilter(WineType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(DrinkingStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Adds [wine] if it has no id yet, otherwise updates it.
  Future<Wine> save(Wine wine) async {
    final saved = wine.id == null
        ? await _repository.add(wine)
        : await _repository.update(wine);
    _wines = [
      for (final w in _wines)
        if (w.id != saved.id) w,
      saved,
    ];
    notifyListeners();
    return saved;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _wines = _wines.where((w) => w.id != id).toList();
    notifyListeners();
  }

  /// Removes one bottle from the stock.
  Future<void> drinkOne(Wine wine) async {
    if (wine.quantity == 0) return;
    await save(wine.withQuantity(wine.quantity - 1));
  }
}
