# Wine lexicon: spelling help in the wine form

## Why

Typing wine facts is hard: grape names (Tempranillo, Grüner Veltliner),
places (Vosne-Romanée, Pouilly-Fuissé) and label terms (Smaragd, 1er Cru,
Trockenbeerenauslese). Misspellings also split statistics: today "Italia",
"Italy" and "Italien" count as three countries. Carl wants a lexicon that
suggests the right spelling while typing. The app is meant for the App
Store and Google Play, so the lexicon must be fast, work offline, be safe to
publish, and be updatable without a new app release.

## Goals

1. **Suggestions while typing**: a list under the field; tapping one fills
   it in. Never auto-correct. Free text not in the lexicon is always
   accepted as typed.
2. **Typo and accent tolerant**: "burgonge" finds Bourgogne, "temperanillo"
   finds Tempranillo, "gruner" finds Grüner Veltliner, "1er cru" / "1 cru"
   / "premier" find Premier Cru.
3. **Grapes**
   - Every wine grape in commercial use, common and rare (target: at least
     1,000 varieties), with synonyms.
   - Grapes are chips: one per grape, removed with an ×.
   - Synonyms are the same grape but the **name you pick is saved**
     (Shiraz stays Shiraz). Suggestions show the link, e.g.
     "Zinfandel (= Primitivo)".
   - **Suggestion order follows the wine's country**: Australia/South
     Africa → Shiraz first; France → Syrah; Italy → Primitivo before
     Zinfandel; Spain → Garnacha, Monastrell. Country only changes the
     order, never what is shown.
   - **Blend**: a chip that can stand alone or with grapes. Known blends
     ("Bordeaux blend", "GSM", "Champagne blend") are suggestions too.
   - **Unknown**: a "Don't know" chip, meaning "unknown", which is
     different from "not filled in". It cannot be combined with grapes.
     Later the AI can offer to fill these in.
4. **Places, three levels plus vineyard**
   - Country → region → subregion → village/appellation. E.g. France →
     Bourgogne → Côte de Nuits → Vosne-Romanée; Beaujolais → (none) →
     Morgon.
   - Type the smallest name you know: "vosne" suggests
     "Vosne-Romanée · Côte de Nuits · Bourgogne · France"; tapping fills
     country, region and subregion too.
   - Or narrow from the top: with France + Bourgogne chosen, the
     appellation field suggests only Bourgogne's appellations.
   - Appellations that are levels of the same place are separate entries:
     Petit Chablis, Chablis, Chablis Premier Cru, Chablis Grand Cru;
     Vosne-Romanée, Vosne-Romanée Premier Cru.
   - **Vineyard (climat/lieu-dit/cru)**: a new free-text field. With an
     appellation chosen it suggests that appellation's known vineyards
     (e.g. Chablis Grand Cru → Les Clos, Vaudésir, Valmur, Blanchot,
     Bougros, Preuses, Grenouilles; Chablis 1er Cru → Montée de Tonnerre,
     Fourchaume, …), but any text is allowed.
5. **Classification**: a chip field, several allowed, suggestions follow
   the country and region. Covers ripeness (Kabinett … Eiswein;
   Steinfeder, Federspiel, Smaragd), site (Grand Cru, Premier Cru, VDP
   Grosse Lage/Erste Lage, Grosses Gewächs, ÖTW Erste Lage), quality and
   ageing (DOCG, DOC, IGT, Riserva, Superiore, Classico, Gran Selezione,
   Crianza, Reserva, Gran Reserva, Vino de Pago, Grand Cru Classé 1855,
   Cru Bourgeois, Vendanges Tardives, Sélection de Grains Nobles, Vintage,
   LBV, Tawny 10/20/30/40, Colheita, DAC). Abbreviations are search names:
   GG, TBA, BA, LBV, VT, SGN, 1er, GC.
6. **Sweetness**: pick the label word (Brut Nature, Extra Brut, Brut,
   Extra Dry, Sec, Demi-Sec, Doux, trocken, halbtrocken, feinherb,
   lieblich, Secco, Abboccato, Amabile, Dolce, Seco, Semiseco, Dulce, …).
   Each maps to a scale **dry / off-dry / medium-sweet / sweet**, so the
   cellar can be filtered by sweetness whatever the label language.
7. **Every field except the wine's name may be left empty.**
8. **Languages**: country names in the app's language (Frankrike,
   Frankrig, France). Region, appellation, grape and classification names
   stay as on the label (Bourgogne, not Burgund; Piemonte, not Piedmont);
   common translations are aliases for search ("Burgundy" finds
   Bourgogne).
9. **Statistics and search use the lexicon**: synonyms count as one grape
   ("Syrah / Shiraz"); "Italia", "Italy", "Italien" count as one country;
   searching "Syrah" also finds Shiraz wines.
10. **Updatable without an app release**: the app ships with the lexicon
    and fetches a newer one from Supabase at most once a day, keeping it
    on the device.

## Non-goals (for now)

- Producer names (hundreds of thousands): part of the coming AI wine
  recognition project.
- AI filling in unknown grapes, places or drinking windows: later; this
  design only leaves room for it ("Don't know" chip, lexicon ids).
- Collecting names users type that are missing from the lexicon: later.
- Vineyard suggestions outside the regions where they matter most
  (Bourgogne incl. Chablis, Barolo/Barbaresco MGA, German VDP sites,
  Champagne Grand Cru villages) in the first version.
- A lexicon editor UI: the lexicon is a JSON file edited in the repo.

## Anti-goals (failure even if it works)

- Blocking or rewriting what the user typed.
- Wrong facts (Morgon placed in Mâconnais, a synonym pointing at the wrong
  grape). Wrong data is worse than missing data.
- Typing that lags: suggestions must appear within one frame budget on a
  mid-range phone (target: under 16 ms per keystroke for the search).
- A suggestion list that hides the field being typed in or traps screen
  reader or keyboard users.
- Using a data source whose licence forbids publishing in a paid app.

## Constraints

- Flutter app, Supabase backend, four app languages (sv, da, nb, en).
- WCAG AAA text contrast and Flutter accessibility guidelines (existing
  tests) apply to the suggestion list and chips.
- Existing wines keep working: today's free-text country, region and
  grapes are kept as they are; no forced data migration.
- Lexicon data is compiled for this project from facts (names, places,
  memberships), checked against Wikidata (CC0) and official appellation
  registers (INAO for France, the Italian MASAF DOP/IGP list, Spanish
  MAPA DO list, EU eAmbrosia). Not copied from VIVC, Wikipedia prose or
  other databases with unclear licences.

## Approaches

1. **Lexicon in the app only.** Fastest and offline; but App Store review
   and users who never update delay every fix.
2. **Lexicon in Supabase only.** Updatable any time; needs internet, slow
   while typing unless cached, more to build.
3. **Import an existing database (VIVC, Wikidata) wholesale.** Largest
   coverage; VIVC includes table grapes and has unclear licence terms,
   Wikidata quality is uneven; noisy suggestions.

**Chosen: 1 + 2 together.** The lexicon ships inside the app (works
offline from first launch) and the app fetches a newer version from
Supabase when one exists. Picked because the app is going to the stores,
where releases are slow.

## Decided design

### Data: one JSON lexicon file

`assets/lexicon/lexicon.json`, also published as
`lexicon/lexicon.json` in a public Supabase Storage bucket. Shape:

```json
{
  "format": 1,
  "version": 1,
  "countries": [
    {"id": "FR", "names": {"sv": "Frankrike", "da": "Frankrig",
     "nb": "Frankrike", "en": "France"}, "aliases": ["Francia"]}
  ],
  "places": [
    {"id": "fr-bourgogne", "name": "Bourgogne", "level": "region",
     "country": "FR", "aliases": ["Burgundy", "Burgund"]},
    {"id": "fr-cote-de-nuits", "name": "Côte de Nuits",
     "level": "subregion", "parent": "fr-bourgogne"},
    {"id": "fr-vosne-romanee", "name": "Vosne-Romanée",
     "level": "appellation", "parent": "fr-cote-de-nuits"},
    {"id": "fr-la-tache", "name": "La Tâche", "level": "vineyard",
     "parent": "fr-vosne-romanee", "aliases": []}
  ],
  "grapes": [
    {"id": "syrah", "name": "Syrah", "color": "red",
     "synonyms": [{"name": "Shiraz", "preferredIn": ["AU", "ZA"]}]}
  ],
  "blends": [
    {"id": "bordeaux-blend", "name": "Bordeaux blend",
     "names": {"sv": "Bordeaux-blend"}}
  ],
  "classifications": [
    {"id": "smaragd", "name": "Smaragd", "kind": "ripeness",
     "countries": ["AT"], "places": ["at-wachau"], "aliases": []}
  ],
  "sweetness": [
    {"term": "Brut Nature", "scale": "dry", "countries": []}
  ]
}
```

- A place's country comes from its top ancestor; only regions carry
  `country`. An appellation may skip the subregion level (Morgon's parent
  is Beaujolais).
- `format` changes only when the shape changes; an app ignores a
  downloaded file whose `format` it does not know.
- `version` increases with every content change.

### Wine model and database

New nullable fields on `Wine`: `subregion`, `appellation`, `vineyard`,
`sweetness` (the label word); new `classifications` (`List<String>`),
`grapesAreBlend` (`bool`, default false), `grapesUnknown` (`bool`,
default false). `grapesUnknown` with a non-empty `grapes` is invalid
(`ArgumentError`). Text is stored as the user chose it (names, not ids),
so wines stay readable if the lexicon changes. Migration
`supabase/migrations/0005_lexicon_fields.sql` adds the columns
(`classifications text[] not null default '{}'`, booleans `not null
default false`). CSV export gets the new columns.

### Search

- Normalise: lower-case, strip accents (ü→u, â→a, ß→ss, æ→ae, ø→o),
  turn punctuation and hyphens into spaces, collapse spaces.
- Match on every word of the name and of each alias/synonym. Rank:
  whole-name prefix > word prefix > contains > typo match (edit distance
  ≤ 1 for words up to 5 letters, ≤ 2 for longer).
- Within a rank, entries for the wine's chosen country (and region, for
  places and classifications) come first, then by fame order (the order
  in the file).
- Show at most 8 suggestions. Index built once when the lexicon loads.

### Form

- Country, region, subregion, appellation, vineyard and sweetness: text
  fields with a suggestion list under them (Flutter `RawAutocomplete` or
  equivalent), keyboard and screen-reader accessible.
- Grapes and classifications: chip fields with the same suggestion list.
- Picking an appellation fills empty country, region and subregion; it
  never overwrites a value the user typed.
- A place suggestion shows its path ("Vosne-Romanée · Côte de Nuits ·
  Bourgogne · France"); a synonym shows its grape ("Shiraz (= Syrah)").
- The label scanner's results go through the same lexicon: a scanned
  name that matches gets the lexicon spelling.

### Updates

- On start, at most once per 24 h, the app fetches the Storage file's
  `version` (small `lexicon/version.json`), and downloads the full file
  only if it is newer than the one in use; it is stored on the device and
  used from the next lookup on.
- Any failure (offline, bad JSON, unknown `format`) keeps the lexicon in
  use and is logged, never shown.

### Statistics, search and display

- Grapes are counted per lexicon grape ("Syrah / Shiraz"); unmatched
  names count as typed. Countries are counted per lexicon country, shown
  in the app language.
- Cellar search matches synonyms and aliases.
- A new "Sweetness" filter next to type and drinking window.
- The wine page shows the new fields only when filled; "Don't know" shows
  as "Grapes: unknown".

## Stages

Built step by step so Carl can use it early (his choice):

1. **Europe**: all features above; data for every wine grape, every
   country (names only), and places, classifications and sweetness for
   France, Italy, Spain, Portugal, Germany and Austria. Vineyards for
   Chablis and the Burgundy Grand Crus.
2. **Rest of the world**: places and classifications for the remaining
   countries; more vineyards (Burgundy 1er Cru, Barolo/Barbaresco MGA,
   German VDP sites, Champagne villages).

## Left to the builder

- Exact widget for the suggestion list, its animation (use the existing
  motion tokens) and how it behaves near the keyboard.
- Where on the device the downloaded lexicon is stored.
- How the lexicon is split into files while editing (it may be built
  from several source files into the one published JSON by a script).
- The compilation of the data itself, in the order: grapes, countries,
  places for France/Italy/Spain/Portugal/Germany/Austria, then the rest
  of the world, classifications, sweetness, vineyards.
