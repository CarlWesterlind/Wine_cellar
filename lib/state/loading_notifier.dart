import 'package:flutter/foundation.dart';

import '../errors/error_messages.dart';

/// Shared by the controllers that load data: a loading flag, the last load
/// error, and no notifications after [dispose] (a load can finish after its
/// screen has closed).
abstract class LoadingNotifier extends ChangeNotifier {
  bool _loading = false;
  Object? _error;
  bool _disposed = false;

  bool get loading => _loading;

  /// Why the last load failed, or null.
  Object? get error => _error;

  /// Runs [fetch], keeping [loading] and [error] up to date. Errors are
  /// stored, not thrown, so the screen can show them with a retry button.
  @protected
  Future<void> runLoad(Future<void> Function() fetch) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await fetch();
    } catch (error, stack) {
      logError(error, stack);
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
