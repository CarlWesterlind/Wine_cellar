import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/auth_service.dart';
import 'data/wine_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/cellar_list_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';
import 'theme/motion.dart';

class WineCellarApp extends StatelessWidget {
  const WineCellarApp({
    super.key,
    required this.settings,
    required this.createRepository,
    this.auth,
  });

  final AppSettings settings;

  /// Creates the wine storage for the signed-in user.
  final WineRepository Function() createRepository;

  /// Null in demo mode, where there is no login.
  final AuthService? auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        themeAnimationDuration: Motion.medium,
        themeAnimationCurve: Motion.easeOut,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: resolveLocale,
        home: _home(),
      ),
    );
  }

  Widget _home() {
    final auth = this.auth;
    if (auth == null) {
      return CellarListScreen(
        repository: createRepository(),
        settings: settings,
        demoMode: true,
      );
    }
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) => snapshot.data!
          ? CellarListScreen(
              // A fresh repository and screen state for every sign-in.
              key: ValueKey(auth.email),
              repository: createRepository(),
              settings: settings,
              auth: auth,
            )
          : LoginScreen(auth: auth),
    );
  }
}

/// Picks the app language from the device language. Norwegian devices may
/// report `no` or `nn`; both get Bokmål. Anything unsupported gets English.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  final code = switch (device?.languageCode) {
    'no' || 'nn' => 'nb',
    final other => other,
  };
  return supported.firstWhere(
    (l) => l.languageCode == code,
    orElse: () => const Locale('en'),
  );
}
