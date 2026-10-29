import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../state/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, this.auth});

  final AppSettings settings;
  final AuthService? auth;

  /// Each language is shown in its own language.
  static const _languages = {
    'sv': 'Svenska',
    'da': 'Dansk',
    'nb': 'Norsk (bokmål)',
    'en': 'English',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = this.auth;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              title: Text(
                l10n.appearance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) =>
                    settings.setThemeMode(selection.single),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<String?>(
              groupValue: settings.locale?.languageCode,
              onChanged: (code) =>
                  settings.setLocale(code == null ? null : Locale(code)),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    title: Text(l10n.systemLanguage),
                  ),
                  for (final MapEntry(key: code, value: name)
                      in _languages.entries)
                    RadioListTile<String?>(value: code, title: Text(name)),
                ],
              ),
            ),
            if (auth != null) ...[
              const Divider(),
              if (auth.email != null)
                ListTile(title: Text(l10n.signedInAs(auth.email!))),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.signOut),
                onTap: () async {
                  final signedOut = await tryOrShowError(context, auth.signOut);
                  if (signedOut && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
