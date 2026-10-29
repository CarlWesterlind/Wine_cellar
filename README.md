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
- **Purchase info**: When and where you bought each wine.
- **Tasting notes**: A dated log of notes per wine, with an optional 1–5 star rating.
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
2. In the project's **SQL Editor**, run each file in
   [`supabase/migrations/`](supabase/migrations/) in order (`0001_…`, then
   `0002_…`). They create the `wines` and `tasting_notes` tables with row
   level security, so each user only sees their own data. When a new
   migration is added later, run just that one.
3. Copy `supabase.example.json` to `supabase.json` and fill in the project
   URL and publishable key from **Project Settings → API**. `supabase.json`
   is ignored by git, so your keys stay on your computer.
4. Run the app with the keys:

   ```bash
   flutter run --dart-define-from-file=supabase.json
   ```

   In VS Code, pick **Wine Cellar (Supabase)** in the Run and Debug panel.

The publishable key is safe to ship in the app; row level security protects
the data. Never put the secret (service role) key in the app.

## Project structure

```
lib/
  main.dart                       # Starts the app, in Supabase or demo mode
  app.dart                        # MaterialApp, languages, login gate
  models/
    wine.dart                     # Wine, WineType, DrinkingStatus
    tasting_note.dart             # A dated note with an optional rating
    dates.dart                    # Dates without time of day
  data/
    auth_service.dart             # Login (AuthService, SupabaseAuthService)
    wine_repository.dart          # Wine storage interface + in-memory version
    supabase_wine_repository.dart # Wine storage in Supabase
  state/
    cellar_controller.dart        # The wine list, search and filters
    tasting_notes_controller.dart # The notes of one wine
    language_settings.dart        # The chosen app language
  screens/
    login_screen.dart
    cellar_list_screen.dart       # Start screen: all wines
    wine_detail_screen.dart       # One wine, with its notes
    tasting_note_dialog.dart      # Write or edit a note
    add_edit_wine_screen.dart     # Form for adding or editing a wine
    settings_screen.dart          # Language and sign out
  widgets/
    display_helpers.dart          # Display names, colors and formatting
    rating_stars.dart             # 1–5 stars, tappable or read-only
  l10n/app_*.arb                  # Translations, one file per language
supabase/migrations/              # Database schema
test/                             # Unit and widget tests
```

## Keeping the code tidy

- **Editor**: open the folder in VS Code and install the recommended
  extensions when asked (Dart, Flutter, spell checker, Error Lens). Files are
  formatted and imports sorted every time you save. In Android Studio or
  IntelliJ, install the **Flutter** plugin and turn on *Format code on save*.
- **Lint rules**: `analysis_options.yaml` lists the style and safety rules.
  Run `flutter analyze` to check, and `dart fix --apply` to fix many issues
  automatically.
- **CI**: GitHub Actions (`.github/workflows/ci.yml`) checks formatting,
  analysis and tests on every push.

## Adding a language

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb` (e.g. `app_de.arb`),
   set `@@locale` and translate the values.
2. Run `flutter gen-l10n` (or just `flutter run`).
3. Add the language to `_languages` in `lib/screens/settings_screen.dart`.
