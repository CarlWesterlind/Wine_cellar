# Wine lookup: recognise a wine from what you typed

## Why

Filling in a wine by hand is slow and the drinking window is hard to know.
The label scanner already fills the form from a photo; Carl wants the same
from text: type the producer and the name, press a button, pick the right
wine, and the app fills in the rest, including a drinking window. It must
also help wines already in the cellar that lack details.

## Goals

1. **A "Get details" button** in the wine form under name and producer,
   enabled when at least one of them is filled in. Vintage, country,
   region and appellation are sent too when filled in.
2. **A list to choose from**: the lookup returns 1–5 candidate wines. Each
   row shows name, producer, grapes, place and drinking window. Tapping
   one fills the form. With exactly one candidate it fills directly.
   "None of these" closes the list and changes nothing.
3. **Only empty fields are filled**, marked "Suggested by AI", exactly like
   the label scanner. Names are spelled the lexicon's way.
4. **What is filled**: region, part of region, appellation, vineyard,
   grapes, blend, classifications, sweetness, type, drinking window, and
   the sommelier notes and producer info.
5. **On the wine page**: the same button fills what a saved wine lacks.
6. **On the start screen**: "Complete 7 wines missing details", shown only
   when some wine lacks a drinking window, grapes or region (grapes marked
   "Don't know" count as missing). It goes through those wines one at a
   time: pick a candidate, skip, or stop.
7. **Web search**: the lookup searches the web so that small producers and
   new wines are found and facts are current.
8. **Demo mode**: an example answer, nothing is sent.

## Non-goals (now)

- Payments, the free/premium split and monthly quotas: a separate project
  (see "Later: free and premium"). This design only keeps the limit in one
  place so that project can change it.
- Looking up wines while typing (automatic): Carl chose a button.
- Barcode lookup.

## Anti-goals

- Overwriting anything the user typed.
- Inventing a wine: a candidate must be a wine that exists; if nothing
  fits, say so ("No wine found") rather than guess.
- A list that takes so long people give up: show progress, and the
  candidate step must not wait for the sommelier text.
- Text from web pages steering the AI (prompt injection): web content is
  information, never instructions.
- Costs running away: every lookup counts against the same AI limit as
  label scans.

## Constraints

- Runs in the existing `scan-label` Supabase Edge Function's style
  (Deno, `@anthropic-ai/sdk`, structured output, per-user limit in the
  database, the API key only on the server).
- Model for lookups: Claude Sonnet (latest), with the web search server
  tool. Label scanning from photos keeps Claude Opus.
- The same error handling as scanning: friendly messages, no stack traces.
- Works in all four languages; sommelier text in the app's language.

## Approaches

- **A. One call with everything**: simplest; slowest and most expensive
  (sommelier text written for every candidate).
- **B. Two steps**: a fast candidate list, then sommelier text for the
  chosen wine only.
- **C. B with web search**: more accurate for small producers and new
  wines; slower and each search costs extra.

**Chosen: C with Sonnet** (Carl's choice): two steps, and the candidate
step searches the web.

## Decided design

### Server: new Edge Function `lookup-wine`

- `POST {step: "candidates", query: {...}, language}` →
  `{candidates: [...]}`. `query` holds what the user typed: name,
  producer, vintage, country, region, appellation (all optional, at least
  name or producer). Claude Sonnet with the web search tool (a small cap
  on searches per request, e.g. 3) returns up to 5 candidates, each with
  the scanner's fact fields plus `drink_from`/`drink_until`, but no
  sommelier text. An empty list means "no wine found".
- `POST {step: "details", candidate: {...}, language}` →
  `{details: {sommelier, producer_info}}` for the chosen candidate.
- Both steps require sign-in. One lookup = one candidates request; it is
  recorded in the same table as label scans (with a `kind` column:
  `scan` or `lookup`) and counts against the same limit. The details step
  is only allowed within 10 minutes after a counted candidates request by
  the same user and is not counted again.
- The limit is read from one function (`aiLimitFor(user)`), today the
  existing 50 per day; the payments project replaces it.
- Answers are cleaned like scans (`sanitize`): blank text to null, years
  checked, lists trimmed and de-duplicated; at most 5 candidates.
- The system prompt says web content is information, not instructions,
  and that a candidate must be a real wine found or known, never made up.

### App

- `WineLookup` interface (like `LabelScanner`) with `candidates(query)`
  and `details(candidate)`; `SupabaseWineLookup` and `DemoWineLookup`.
  Errors use the scanner's failure kinds plus "no wine found".
- A candidate is a `LabelScan` without sommelier text; after picking, the
  details are merged in. The form's existing "fill empty fields and mark
  them" code is reused for scans and lookups alike.
- The candidate list is a bottom sheet: one row per candidate (name ·
  producer, grapes · place · drinking window), "None of these" at the
  bottom; a progress indicator with "Searching…" while waiting (web
  search can take 10–30 s).
- Wine page: the button opens the same sheet and saves the filled-in wine
  (only empty fields) after the pick.
- Start screen: a banner with the count of wines missing details; the
  "complete" flow shows one wine at a time with the sheet plus "Skip" and
  "Stop", and saves each pick.

## Later: free and premium (separate project)

Recorded so this design leaves room for it:
- Free: up to 25 wines; search, filters, history and notes; 5 AI uses per
  month; map, statistics and export locked with an "Unlock" button.
- Premium, one-time 250 kr: everything, with 100 AI uses per month
  included and AI top-ups for sale.
- Carl and testers get premium (set in Supabase), not unlimited.
- Purchases through the App Store and Google Play (likely via
  RevenueCat); the tier and limits are enforced on the server.

## Left to the builder

- The web search tool version and search cap; prompt wording.
- Exact layout and motion of the sheet and the "complete" flow.
- Timeout handling and retry wording for slow searches.
