# Wine Lexicon, Stage 1 (Europe) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spelling suggestions for grapes, places, classifications and sweetness in the wine form, backed by a lexicon that ships in the app and updates from Supabase.

**Architecture:** Lexicon data is written as compact text files under `tool/lexicon/` and built by `dart run tool/build_lexicon.dart` into `assets/lexicon/lexicon.json`. `lib/lexicon/` parses it, builds a search index and loads updates. The form uses the search through autocomplete text fields and chip fields; stats and cellar search use it to merge synonyms.

**Tech Stack:** Flutter 3.47 / Dart 3.13, supabase_flutter, shared_preferences.

**Spec:** `docs/superpowers/specs/2026-11-06-wine-lexicon-design.md`

## Global Constraints

- Never auto-correct; free text is always accepted as typed.
- Every field except the wine's name may be empty.
- Names are stored as chosen (not ids); synonyms keep the chosen name.
- Country names shown in the app language (sv, da, nb, en); all other names as on the label.
- At most 8 suggestions; search under 16 ms per keystroke.
- Typo tolerance: edit distance ≤ 1 for words up to 5 letters, ≤ 2 longer.
- Update check at most once per 24 h; failures keep the lexicon in use, are logged, never shown.
- Text contrast 7:1 and Flutter accessibility guidelines in both themes.
- Data compiled for this project; no copying from VIVC or Wikipedia prose.
- Stage 1 data: all wine grapes (≥ 1,000), all countries (names), places/classifications/sweetness for FR, IT, ES, PT, DE, AT; vineyards for Chablis and Burgundy Grand Crus.

## Review Focus

- Existing wines typed before the lexicon ("Italia", "Italy") must group as one country in statistics.
- Adding a grape chip while "Don't know" is set must replace "Don't know", not throw `ArgumentError`.
- Picking an appellation must not overwrite a country/region the user already typed differently.
- A downloaded lexicon with bad JSON or an unknown `format` must leave the bundled one in use.
- Odd input (empty, only spaces, emoji, 200 characters) must give no suggestions or sane ones, never crash.

---

### Task 1: Lexicon model and search

**Files:**
- Create: `lib/lexicon/lexicon.dart`, `lib/lexicon/normalize.dart`, `lib/lexicon/lexicon_search.dart`
- Test: `test/lexicon_search_test.dart` (uses a small inline JSON lexicon)

**Interfaces:**
- Produces:
  - `enum PlaceLevel { region, subregion, appellation, vineyard }`, `enum SweetnessScale { dry, offDry, mediumSweet, sweet }`
  - `class Lexicon { factory Lexicon.fromJson(Map<String, dynamic>); int get format; int get version; List<LexCountry> countries; List<LexPlace> places; List<LexGrape> grapes; List<LexBlend> blends; List<LexClassification> classifications; List<LexSweetness> sweetness; LexPlace? placeById(String id); List<LexPlace> pathOf(LexPlace place) /* top first */; String? countryIdOf(LexPlace place); LexCountry? countryFor(String text) /* by any name/alias, normalized */; LexGrape? grapeFor(String name) /* by name or synonym */; LexSweetness? sweetnessFor(String term); }` — throws `FormatException` on bad shape.
  - `String normalizeForSearch(String text)`; `int editDistance(String a, String b, int max)` (returns `max + 1` when above).
  - `class Suggestion<T> { final String text; final String? detail; final T entry; }`
  - `class LexiconSearch { LexiconSearch(Lexicon lexicon); List<Suggestion<LexGrape>> grapes(String query, {String? countryId}); List<Suggestion<LexPlace>> places(String query, {PlaceLevel? level, String? countryId, String? withinId}); List<Suggestion<LexCountry>> countries(String query, String languageCode); List<Suggestion<LexClassification>> classifications(String query, {String? countryId, String? placeId}); List<Suggestion<LexSweetness>> sweetness(String query, {String? countryId}); List<Suggestion<LexBlend>> blends(String query, String languageCode); }`

- [ ] **Step 1: Failing tests** in `test/lexicon_search_test.dart`:
  - `normalizeForSearch('Grüner-Veltliner  ')` == `'gruner veltliner'`; `'Côte-Rôtie'` → `'cote rotie'`; `'Straße'` → `'strasse'`; `'Ærø'` → `'aero'`.
  - `editDistance('burgonge','bourgogne',2) <= 2`; `editDistance('abc','xyz',1) == 2`.
  - `search.places('burgonge').first.text == 'Bourgogne'`; `search.grapes('temperanillo').first.text == 'Tempranillo'`; `search.grapes('gruner').first.text == 'Grüner Veltliner'`.
  - `search.places('vosne').first.detail == 'Côte de Nuits · Bourgogne · France'` (en).
  - `search.grapes('sy', countryId: 'AU').first.text == 'Shiraz'` and its `detail == '= Syrah'`; with `countryId: 'FR'` first is `'Syrah'`; both lists contain both names.
  - `search.grapes('zin', countryId: 'IT')` contains `'Zinfandel'` with detail `'= Primitivo'`.
  - `search.classifications('1er cru').first.text == 'Premier Cru'`; `'gg'` → `'Grosses Gewächs'`; `'tba'` → `'Trockenbeerenauslese'`.
  - `search.places('', level: PlaceLevel.appellation, withinId: 'fr-bourgogne')` lists only places under Bourgogne.
  - `search.places('morgon').first.detail == 'Beaujolais · France'`.
  - Review focus: `search.grapes('')`, `('   ')`, `('🍷')`, `('a' * 200)` return lists without throwing.
  - `lexicon.countryFor('Italia')?.id == 'IT'`, `countryFor('Italien')?.id == 'IT'`; `lexicon.grapeFor('Shiraz')?.name == 'Syrah'`.
  - `Lexicon.fromJson({'format': 1})` throws `FormatException`.
- [ ] **Step 2: Run** `flutter test test/lexicon_search_test.dart` — FAIL (missing files).
- [ ] **Step 3: Implement.** Index: for every entry, store normalized names (name + aliases/synonyms) and their words. Rank buckets: 0 whole-name prefix, 1 word prefix, 2 contains, 3 typo match on any word (`editDistance` with the spec's limits, comparing the query's last word against same-length-±2 prefixes of words). Within a bucket: preferred country/place first, then file order. One suggestion per entry+name; at most 8.
- [ ] **Step 4: Run** the tests — PASS; also a timing test: 1,000 queries over the real lexicon (Task 2) under 16 ms average (add in Task 2).
- [ ] **Step 5: Commit** `Lexicon model and search`.

### Task 2: Lexicon data, Europe

**Files:**
- Create: `tool/build_lexicon.dart`; `tool/lexicon/countries.txt`, `grapes.txt`, `blends.txt`, `classifications.txt`, `sweetness.txt`, `places_fr.txt`, `places_it.txt`, `places_es.txt`, `places_pt.txt`, `places_de.txt`, `places_at.txt`; `assets/lexicon/lexicon.json` (generated)
- Modify: `pubspec.yaml` (asset)
- Test: `test/lexicon_data_test.dart`

**Interfaces:**
- Consumes: `Lexicon.fromJson` (Task 1).
- Produces: `assets/lexicon/lexicon.json` with `format: 1`, `version: 1`.

Source formats (one entry per line, `#` comments, `|` separates columns, `,` separates list items):
- `countries.txt`: `ID | sv | da | nb | en | aliases`
- `grapes.txt`: `Name | red/white/pink | synonym@CC CC, synonym, …` (`@` lists countries where that name comes first)
- `blends.txt`: `Name | sv | da | nb | aliases`
- `classifications.txt`: `Name | kind | countries | place ids | aliases`
- `sweetness.txt`: `Term | dry/offDry/mediumSweet/sweet | countries`
- `places_xx.txt`: first line `@CC`; then `R Name | aliases`, `S Name`, `A Name`, `V Name`; parent is the nearest earlier line of a higher level (an `A` right after an `R` hangs on the region). Ids: `cc-slug(name)`, with the parent's slug appended on collision.

- [ ] **Step 1: Failing test** `test/lexicon_data_test.dart`:
  - built JSON equals `buildLexicon()` output from the sources (generated file is up to date);
  - ids unique; every `parent`, `place id` and country code exists; levels nest (vineyard under appellation, etc.);
  - every country has four non-empty names; ≥ 1,000 grapes; no name/synonym shared by two grapes;
  - spot facts: Morgon under Beaujolais; Vosne-Romanée under Côte de Nuits; Pouilly-Fuissé under Mâconnais; Chablis Grand Cru has exactly the 7 climats; Smaragd only for AT; Shiraz → Syrah; Primitivo has synonym Zinfandel and Tribidrag; Barolo under Piemonte; Rioja country ES.
  - search speed over the real lexicon (from Task 1 step 4).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Write** `tool/build_lexicon.dart` (`String buildLexicon(Directory source)` + `main` writing the asset) and the data files. Check names against Wikidata and the official registers named in the spec.
- [ ] **Step 4: Run** `dart run tool/build_lexicon.dart && flutter test test/lexicon_data_test.dart` — PASS.
- [ ] **Step 5: Commit** `Lexicon data: grapes, countries and Europe`.

### Task 3: Loading and updating the lexicon

**Files:**
- Create: `lib/lexicon/lexicon_store.dart`; `supabase/migrations/0005_lexicon_fields.sql` (bucket part); `tool/publish_lexicon.md` (how to upload)
- Modify: `lib/data/cellar_services.dart`, `lib/main.dart`, `test/helpers.dart`
- Test: `test/lexicon_store_test.dart`

**Interfaces:**
- Produces: `typedef LexiconFetcher = Future<String?> Function(String file)` (returns body or null); `class LexiconStore extends ChangeNotifier { LexiconStore({required Future<String> Function() loadBundled, LexiconFetcher? fetch, SharedPreferences? prefs, DateTime Function()? clock}); Lexicon get lexicon; LexiconSearch get search; Future<void> load(); Future<void> checkForUpdate(); }`; `CellarServices.lexicon` (`LexiconStore`).
- Prefs keys: `lexicon_json`, `lexicon_checked_at`.

- [ ] **Step 1: Failing tests:** loads bundled; uses cached newer version over bundled; ignores cached older version; `checkForUpdate` downloads only when `version.json` is newer, stores it, notifies; does nothing within 24 h of last check; bad JSON / `format: 2` / fetch throws → lexicon unchanged, no exception.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.** Supabase fetch: public bucket `lexicon`, files `version.json` (`{"format":1,"version":N}`) and `lexicon.json`. Migration creates the public bucket. Demo mode: no fetch.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `Load the lexicon and fetch updates from Supabase`.

### Task 4: New wine fields

**Files:**
- Modify: `lib/models/wine.dart`, `supabase/migrations/0005_lexicon_fields.sql`, `lib/screens/export_cellar.dart`, `lib/screens/wine_detail_screen.dart`, `lib/l10n/app_*.arb`
- Test: `test/wine_test.dart`, `test/history_stats_map_screens_test.dart`

**Interfaces:**
- Produces on `Wine`: `String? subregion, appellation, vineyard, sweetness; List<String> classifications; bool grapesAreBlend; bool grapesUnknown`; columns `subregion, appellation, vineyard, sweetness text`, `classifications text[] not null default '{}'`, `grapes_blend, grapes_unknown boolean not null default false`.

- [ ] **Step 1: Failing tests:** map round trip of all new fields; `Wine(grapes: ['Syrah'], grapesUnknown: true)` throws `ArgumentError`; old rows without the columns parse with defaults; detail page shows "Grapes: unknown" for `grapesUnknown`; CSV has the new columns.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `Wine fields for appellation, vineyard, classification and sweetness`.

### Task 5: Suggestions in the form

**Files:**
- Create: `lib/widgets/suggestion_field.dart` (`SuggestionField`), `lib/widgets/chip_suggestion_field.dart` (`ChipSuggestionField`)
- Modify: `lib/screens/add_edit_wine_screen.dart`, `lib/l10n/app_*.arb`
- Test: `test/lexicon_form_test.dart`

**Interfaces:**
- Consumes: `LexiconSearch` (Task 1), `CellarServices.lexicon` (Task 3), new `Wine` fields (Task 4).
- Produces: `SuggestionField<T>({required String label, required TextEditingController controller, required List<Suggestion<T>> Function(String) suggest, ValueChanged<Suggestion<T>>? onPicked})`; `ChipSuggestionField<T>({required String label, required List<String> values, required ValueChanged<List<String>> onChanged, required List<Suggestion<T>> Function(String) suggest, List<String> specialChips = const []})`.

- [ ] **Step 1: Failing widget tests:** typing "burgonge" in Region shows "Bourgogne", tapping fills it; typing "vosne" in Appellation and tapping fills empty Country (shown "France"), Region "Bourgogne", Subregion "Côte de Nuits"; with Region already "Burgundy" typed it is kept (review focus); grapes: "sy" with country Australia shows "Shiraz" first, tapping adds a chip, × removes it; "Don't know" chip then adding "Merlot" replaces it (review focus); "Blend" + "Merlot" both kept; classification "1er" suggests "Premier Cru"; free text "Rara Neagră" added as chip on Enter; save stores all new fields; accessibility guidelines pass with a suggestion list open, light and dark.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement** with `RawAutocomplete`, the existing motion tokens and 48 px rows. **Step 4: Run** — PASS, plus the full suite.
- [ ] **Step 5: Commit** `Spelling suggestions in the wine form`.

### Task 6: Statistics, search and sweetness filter

**Files:**
- Modify: `lib/models/cellar_stats.dart`, `lib/state/cellar_controller.dart`, `lib/models/wine.dart` (`matchesSearch`), `lib/screens/stats_screen.dart`, `lib/screens/cellar_list_screen.dart`
- Test: `test/history_stats_map_models_test.dart`, `test/history_and_racks_controller_test.dart`

**Interfaces:**
- Consumes: `Lexicon.grapeFor`, `Lexicon.countryFor`, `Lexicon.sweetnessFor`.
- Produces: `CellarStats(wines, year:, lexicon:)`; `Wine.matchesSearch(query, {Lexicon? lexicon})`; `CellarController.setSweetnessFilter(SweetnessScale?)`.

- [ ] **Step 1: Failing tests:** Syrah + Shiraz wines → one grape bar "Syrah / Shiraz"; "Italia" + "Italy" wines → one country shown in the app language (review focus); search "syrah" finds a Shiraz wine; sweetness filter "dry" keeps a "Brut" and a "trocken" wine, drops "Doux".
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `Statistics and search understand synonyms; sweetness filter`.

### Task 7: Label scanner fills the new fields

**Files:**
- Modify: `supabase/functions/scan-label/schema.ts`, `claude.ts`, `*_test.ts`; `lib/models/label_scan.dart`, `lib/screens/add_edit_wine_screen.dart`
- Test: `supabase/functions/scan-label/schema_test.ts`, `test/label_scan_flow_test.dart`

- [ ] **Step 1: Failing tests:** schema accepts and `sanitize` keeps `subregion, appellation, vineyard, classifications, sweetness, grapes_blend`; app maps a scanned "burgundy" region to "Bourgogne" and "shiraz" to the lexicon's "Shiraz" spelling.
- [ ] **Step 2: Run** `deno test` and `flutter test` — FAIL. **Step 3: Implement.** **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `Label scanner fills appellation, classification and sweetness`.
