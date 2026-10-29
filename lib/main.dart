import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/auth_service.dart';
import 'data/supabase_wine_repository.dart';
import 'data/wine_repository.dart';
import 'state/settings_controller.dart';

// Pass with --dart-define. Without them the app runs in demo mode.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController(await SharedPreferences.getInstance());

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(
      WineCellarApp(
        settings: settings,
        createRepository: () => InMemoryWineRepository(demoWines),
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
