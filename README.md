# Wine Cellar

A personal wine cellar app for keeping track of your collection. Built with
[Flutter](https://flutter.dev) for iOS, Android and web, with
[Supabase](https://supabase.com) for accounts and storage.

Available in Swedish, Danish, Norwegian (Bokmål) and English.

## Features

- **Bottle locations**: Know exactly where each bottle is, by rack, shelf or position.
- **Drinking window**: See when each wine is at its best, so nothing gets opened too early or too late.
- **Search and filters**: Find wines by name, producer, region or grape, and filter by type or drinking window.
- **Stock and value**: Track bottles per wine, "drink a bottle" in one tap, and see the total value of the cellar.
- **Accounts**: Sign in to keep your cellar in sync across devices.

Planned:

- **Label scanning**: Scan a bottle to add it to your cellar automatically.
- **Food pairing**: Get suggestions for dishes that go well with each wine.

## Running the app

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then:

```bash
flutter pub get
flutter run            # pick a device, e.g. Chrome or an emulator
flutter test           # run the tests
```

Without Supabase settings the app starts in **demo mode**: no login, sample
wines, and nothing is saved.

## Connecting Supabase

1. Create a free project at [supabase.com](https://supabase.com).
2. In the project's **SQL Editor**, run
   [`supabase/migrations/0001_create_wines.sql`](supabase/migrations/0001_create_wines.sql).
   It creates the `wines` table with row level security, so each user only
   sees their own wines.
3. Under **Project Settings → API**, copy the project URL and the
   publishable key, and run:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
   ```

The publishable key is safe to ship in the app; row level security protects
the data. Never put the secret (service role) key in the app.

## Project structure

```
lib/
  main.dart              # Starts the app, in Supabase or demo mode
  app.dart               # MaterialApp, languages, login gate
  models/wine.dart       # The Wine model and drinking window logic
  data/                  # Storage (Supabase / in memory) and login
  state/                 # Cellar list, search/filters, language setting
  screens/               # Login, cellar list, wine details, form, settings
  widgets/labels.dart    # Shared labels, colors and formatting
  l10n/app_*.arb         # Translations, one file per language
supabase/migrations/     # Database schema
test/                    # Unit and widget tests
```

## Adding a language

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb` (e.g. `app_de.arb`),
   set `@@locale` and translate the values.
2. Run `flutter gen-l10n` (or just `flutter run`).
3. Add the language to `_languages` in `lib/screens/settings_screen.dart`.
