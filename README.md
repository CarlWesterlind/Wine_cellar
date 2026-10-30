# Wine Cellar

A personal wine cellar app for keeping track of your collection. Built with
[Flutter](https://flutter.dev) for iOS, Android and web, with
[Supabase](https://supabase.com) for accounts and storage.

Available in Swedish, Danish, Norwegian (Bokmål) and English.

## Features

- **Bottle locations**: Know exactly where each bottle is, by rack, shelf or position.
- **Cellar map**: Draw each rack as a grid of shelves and places. Every
  wine shows as a dot in its color; tap an empty place to put a wine there.
- **Drinking history**: "Drink a bottle" asks for the date and occasion, with
  an optional rating and note, and keeps a history you can undo from.
- **Statistics**: Bottles, wines, value and average price; bottles per
  drinking-window status, type, country and grape; and the wines whose last
  year to drink is this year.
- **Export**: Share the whole cellar as a CSV file that opens in Excel,
  Numbers or Google Sheets.
- **Drinking window**: See when each wine is at its best, so nothing gets opened too early or too late.
- **Search and filters**: Find wines by name, producer, region or grape, and filter by type or drinking window.
- **Stock and value**: Track bottles per wine and see the total value of the cellar.
- **Purchase info**: When and where you bought each wine.
- **Tasting notes**: A dated log of notes per wine, with an optional 1–5 star rating.
- **Accounts**: Sign in to keep your cellar in sync across devices.
- **Light and dark mode**: Follows the phone, or pick one in Settings.
- **Accessible**: High-contrast colors (WCAG AAA, 7:1 for text), screen
  reader labels, large tap targets, and no motion when the phone asks for
  reduced motion.

- **Label scanning**: Photograph the front (and optionally the back) label,
  and Claude fills in name, producer, vintage, type, region, grapes and a
  drinking window. Only empty fields are filled, and every AI value is
  marked until you change it.
- **Sommelier notes**: The same scan suggests tasting notes, food pairings,
  serving temperature, decanting and a few lines about the producer, shown
  as AI suggestions on the wine page.
- **Bottle photos**: Stored privately per user.

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
   `0002_…` and so on). They create the tables with row level security, so each user only sees their own data. When a new
   migration is added later, run just that one.
3. Copy `supabase.example.json` to `supabase.json` and fill in the project
   URL and publishable key from **Project Settings → API**. `supabase.json`
   is ignored by git, so your keys stay on your computer.
4. Set up label scanning (optional - everything else works without it):

   ```bash
   supabase functions deploy scan-label
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   ```

   The Claude API key stays on the server; the app never sees it. Each user
   can scan 50 labels per day (`DAILY_LIMIT` in
   `supabase/functions/scan-label/index.ts`). A scan costs roughly half a
   krona with Claude Opus 5.5 (estimate: up to two photos of at most
   1600 px plus the answer).
5. Run the app with the keys:

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
    consumed_bottle.dart          # A bottle drunk: date and occasion
    rack.dart                     # A rack on the cellar map
    cellar_stats.dart             # Numbers for the statistics view
    csv.dart                      # Writes spreadsheet (CSV) text
    sommelier_info.dart           # AI tasting notes, food pairing etc.
    label_scan.dart               # What the AI read from a label
    dates.dart                    # Dates without time of day
    number_input.dart             # Reading numbers typed in the form
  data/
    cellar_services.dart          # Bundles the services below per user
    label_scanner.dart            # Label scanning (server, or demo example)
    images.dart                   # Recognises JPEG, PNG and WebP
    photo_storage.dart            # Bottle photos (Supabase Storage / memory)
    photo_picker.dart             # Camera and photo library
    file_sharer.dart              # The phone's share sheet
    auth_service.dart             # Login (AuthService, SupabaseAuthService)
    wine_repository.dart          # Storage interface + in-memory version
    supabase_wine_repository.dart # Storage in Supabase
  state/
    loading_notifier.dart         # Shared loading/error handling
    cellar_controller.dart        # Wines, photos, history, racks, filters
    tasting_notes_controller.dart # The notes of one wine
    app_settings.dart             # Language and light/dark choice
  screens/
    login_screen.dart
    home_screen.dart              # Bottom bar: cellar, map, stats, history
    cellar_list_screen.dart       # Start screen: all wines
    cellar_map_screen.dart        # Racks drawn as grids
    rack_dialog.dart              # Create or edit a rack
    stats_screen.dart             # Statistics
    history_screen.dart           # Bottles drunk
    drink_sheet.dart              # "Drink a bottle": date, occasion, note
    export_cellar.dart            # CSV export
    wine_detail_screen.dart       # One wine, with its notes
    tasting_note_dialog.dart      # Write or edit a note
    add_edit_wine_screen.dart     # Form for adding or editing a wine
    settings_screen.dart          # Language and sign out
  theme/
    app_theme.dart                # Colors, shapes and page transitions
    motion.dart                   # Animation timing and easing
  widgets/
    common.dart                   # Banner, messages, confirm dialog, date field
    label_photo_section.dart      # Photo and "photograph the label" in form
    display_helpers.dart          # Display names, colors and formatting
    motion_widgets.dart           # Press, fade-in and rolling-number effects
    rating_stars.dart             # 1–5 stars, tappable or read-only
    sommelier_card.dart           # The AI sommelier notes
    wine_photo.dart               # Loads and fades in a bottle photo
  l10n/app_*.arb                  # Translations, one file per language
supabase/
  migrations/                     # Database schema, run in order
  functions/scan-label/           # Edge Function: reads labels with Claude
    handler.ts                    # Login, validation, daily limit, errors
    claude.ts                     # The Claude request and prompt
    schema.ts                     # Answer format and clean-up
    *_test.ts                     # Tests: `deno test` in this folder
test/                             # Unit and widget tests
```

## Design

The design follows Emil Kowalski's design engineering principles:

- **Motion with a purpose**: short (150–280 ms) ease-out animations for
  things that appear, so the app feels responsive, never slow. Cards shrink
  slightly when pressed, lists fade in, and numbers roll when they change.
- **Respect the user**: when the phone's *reduce motion* setting is on,
  nothing animates (`Motion.of` returns zero).
- **Readable**: every text/background color pair is checked in
  `test/theme_test.dart`, and every screen is checked against Flutter's
  contrast, label and tap-target guidelines in `test/design_test.dart`, in
  both light and dark mode.

All timing lives in `lib/theme/motion.dart` and all colors in
`lib/theme/app_theme.dart`, so the look can be adjusted in one place.

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
