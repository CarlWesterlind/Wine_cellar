import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/auth_service.dart';
import 'data/supabase_wine_repository.dart';
import 'data/wine_repository.dart';
import 'errors/error_messages.dart';
import 'state/language_settings.dart';

// Pass with --dart-define. Without them the app runs in demo mode.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  catchUnhandledErrors();
  final settings = LanguageSettings(await SharedPreferences.getInstance());

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(
      WineCellarApp(
        settings: settings,
        createRepository: () => InMemoryWineRepository(sampleWines),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  final client = Supabase.instance.client;
  runApp(
    WineCellarApp(
      settings: settings,
      auth: SupabaseAuthService(client.auth),
      createRepository: () => SupabaseWineRepository(client),
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
