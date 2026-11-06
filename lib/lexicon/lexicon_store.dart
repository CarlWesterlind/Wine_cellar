import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/error_messages.dart';
import 'lexicon.dart';
import 'lexicon_search.dart';

/// Downloads a published lexicon file ("version.json" or "lexicon.json")
/// and returns its text, or null if there is none.
typedef LexiconFetcher = Future<String?> Function(String file);

/// Holds the lexicon in use: the one shipped with the app, or a newer one
/// downloaded earlier. Checks for a newer one at most once a day. Nothing
/// that goes wrong here is shown to the user; the lexicon in use stays.
class LexiconStore extends ChangeNotifier {
  LexiconStore({
    required this._loadBundled,
    this._fetch,
    this._prefs,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// A store that already has [lexicon], for tests and previews.
  LexiconStore.ready(Lexicon lexicon)
    : _loadBundled = null,
      _fetch = null,
      _prefs = null,
      _clock = DateTime.now {
    _use(lexicon);
  }

  static const _jsonKey = 'lexicon_json';
  static const _checkedKey = 'lexicon_checked_at';
  static const checkInterval = Duration(hours: 24);

  final Future<String> Function()? _loadBundled;
  final LexiconFetcher? _fetch;
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  Lexicon? _lexicon;
  LexiconSearch? _search;

  /// Null until [load] has finished.
  Lexicon? get lexicon => _lexicon;

  /// Null until [load] has finished; the form then shows no suggestions.
  LexiconSearch? get search => _search;

  void _use(Lexicon lexicon) {
    _lexicon = lexicon;
    _search = LexiconSearch(lexicon);
  }

  /// Loads the shipped lexicon, or a newer one saved on the device.
  Future<void> load() async {
    final loadBundled = _loadBundled;
    if (loadBundled == null) return;
    try {
      var lexicon = _parse(await loadBundled())!;
      final saved = _parse(_prefs?.getString(_jsonKey));
      if (saved != null && saved.version > lexicon.version) lexicon = saved;
      _use(lexicon);
      notifyListeners();
    } catch (error, stack) {
      logError(error, stack);
    }
  }

  /// Downloads a newer lexicon if one has been published, at most once per
  /// [checkInterval].
  Future<void> checkForUpdate() async {
    final fetch = _fetch, prefs = _prefs;
    if (fetch == null || prefs == null) return;
    final now = _clock();
    final checked = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
    if (checked != null && now.difference(checked) < checkInterval) return;
    await prefs.setString(_checkedKey, now.toIso8601String());
    try {
      final info = jsonDecode(await fetch('version.json') ?? '{}');
      if (info is! Map<String, dynamic> ||
          info['format'] != Lexicon.supportedFormat ||
          info['version'] is! int ||
          (info['version'] as int) <= (_lexicon?.version ?? 0)) {
        return;
      }
      final text = await fetch('lexicon.json');
      final lexicon = _parse(text);
      if (lexicon == null || lexicon.version <= (_lexicon?.version ?? 0)) {
        return;
      }
      await prefs.setString(_jsonKey, text!);
      _use(lexicon);
      notifyListeners();
    } catch (error, stack) {
      logError(error, stack);
    }
  }

  /// Null for missing text or a file in a format this app can't read.
  static Lexicon? _parse(String? text) {
    if (text == null) return null;
    try {
      final lexicon = Lexicon.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      return lexicon.format == Lexicon.supportedFormat ? lexicon : null;
    } catch (error, stack) {
      logError(error, stack);
      return null;
    }
  }
}
