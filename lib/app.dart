import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/auth_service.dart';
import 'data/cellar_services.dart';
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
    required this.createServices,
    this.auth,
  });

  final AppSettings settings;

  /// Creates storage and services for the signed-in user.
  final CellarServices Function() createServices;

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
      return _Session(createServices: createServices, settings: settings);
    }
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) => snapshot.data!
          ? _Session(
              // A new session, with fresh services, for every sign-in.
              key: ValueKey(auth.email),
              createServices: createServices,
              settings: settings,
              auth: auth,
            )
          : LoginScreen(auth: auth),
    );
  }
}

/// The cellar of one signed-in user (or of demo mode). Creates the services
/// once, so that changing the theme or language, which rebuilds the app,
/// keeps them and their cached photos.
class _Session extends StatefulWidget {
  const _Session({
    super.key,
    required this.createServices,
    required this.settings,
    this.auth,
  });

  final CellarServices Function() createServices;
  final AppSettings settings;
  final AuthService? auth;

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  late final _services = widget.createServices();

  @override
  Widget build(BuildContext context) => CellarListScreen(
    services: _services,
    settings: widget.settings,
    auth: widget.auth,
  );
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
