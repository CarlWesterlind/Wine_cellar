import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/auth_service.dart';
import 'data/cellar_services.dart';
import 'data/label_scanner.dart';
import 'data/photo_storage.dart';
import 'data/supabase_wine_repository.dart';
import 'errors/error_messages.dart';
import 'lexicon/lexicon_store.dart';
import 'state/app_settings.dart';

// Pass with --dart-define. Without them the app runs in demo mode.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  catchUnhandledErrors();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings(prefs);
  Future<String> loadBundled() =>
      rootBundle.loadString('assets/lexicon/lexicon.json');

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    final lexicon = LexiconStore(loadBundled: loadBundled);
    unawaited(lexicon.load());
    runApp(
      WineCellarApp(
        settings: settings,
        createServices: () => CellarServices.demo(lexicon),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  final client = Supabase.instance.client;
  final lexicon = LexiconStore(
    loadBundled: loadBundled,
    // Published in the public `lexicon` bucket; see tool/publish_lexicon.md.
    fetch: (file) async =>
        utf8.decode(await client.storage.from('lexicon').download(file)),
    prefs: prefs,
  );
  unawaited(lexicon.load().then((_) => lexicon.checkForUpdate()));
  runApp(
    WineCellarApp(
      settings: settings,
      auth: SupabaseAuthService(client.auth),
      createServices: () => CellarServices(
        wines: SupabaseWineRepository(client),
        photos: SupabasePhotoStorage(client),
        scanner: SupabaseLabelScanner(client.functions),
        lexicon: lexicon,
      ),
    ),
  );
}

/// Safety net for errors that no try/catch handled: they are logged instead
/// of crashing the app. In release builds a broken widget shows a small icon
/// instead of an error screen with a stack trace.
void catchUnhandledErrors() {
  FlutterError.onError = (details) {
    logError(details.exception, details.stack);
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logError(error, stack);
    return true; // Handled; keep the app running.
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (_) =>
        const Center(child: Icon(Icons.error_outline, color: Colors.grey));
  }
}
