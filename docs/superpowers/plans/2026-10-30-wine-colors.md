# Wine Colors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the pale-pink theme with "Bordeaux frames" (light) and "The cellar" (dark).

**Architecture:** Swap the two hand-picked `ColorScheme` constants in `AppTheme`; the light theme fills the app bar and navigation bar with `primary`, using a new `AppTheme.champagne` color for their text and icons.

**Tech Stack:** Flutter 3.47, Material 3.

**Spec:** `docs/superpowers/specs/2026-10-30-wine-colors-design.md`

## Global Constraints

- Text contrast ≥ 7:1, graphics ≥ 3:1 (`test/theme_test.dart`).
- Light: surface `#FBF8F1`, primary `#6B1530`, containers `#F1E3C2`, secondary `#7A5A12`.
- Dark: surface `#1A0E11`, primary `#D9B46A`, containers `#5E1226`.
- Drinking-status and wine-type colors unchanged.

## Review Focus

- Status bar icons on the bordeaux app bar: must be light, not black-on-bordeaux.
- Unselected navigation labels/icons on bordeaux: must meet 7:1, not just the selected one.
- Buttons inside the bordeaux app bar (back, edit, share): champagne, not default dark.
- Dark theme's "Drick en flaska" tonal button and demo banner (bordeaux containers): text 7:1.
- Rating stars (gold) on the new light cards: still ≥ 3:1.

---

### Task 1: New color schemes and filled bars

**Files:**
- Modify: `lib/theme/app_theme.dart` (`lightScheme`, `darkScheme`, `_build`)
- Test: `test/theme_test.dart`

**Interfaces:**
- Produces: `AppTheme.champagne` (`Color(0xFFF1E3C2)`), the text/icon color on bordeaux bars in light mode.

- [ ] **Step 1: Add failing tests** in `theme_test.dart`:
  `test('light bars: champagne on bordeaux')` → `contrast(AppTheme.champagne, AppTheme.lightScheme.primary) >= 7`;
  `testWidgets('light app bar and navigation bar are bordeaux')` → `AppTheme.light().appBarTheme.backgroundColor == lightScheme.primary`, `navigationBarTheme.backgroundColor == lightScheme.primary`, `appBarTheme.systemOverlayStyle!.statusBarIconBrightness == Brightness.light`;
  `test('dark theme is the cellar')` → `darkScheme.surface == Color(0xFF1A0E11)`, `darkScheme.primary == Color(0xFFD9B46A)`.
- [ ] **Step 2: Run** `flutter test test/theme_test.dart` — expect FAIL (`champagne` undefined).
- [ ] **Step 3: Implement**: replace the schemes with the spike values (`ivoryLight`, `cellarDark` from the palette spike); in `_build`, for light brightness set app bar background `primary`, foreground/title `champagne`, `systemOverlayStyle: SystemUiOverlayStyle.light`; navigation bar background `primary`, indicator `primaryContainer`, unselected icons/labels `champagne`, selected icon `onPrimaryContainer`.
- [ ] **Step 4: Run** `flutter test` — all pass, incl. `design_test.dart` guideline tests in both themes. Adjust hex values only if a contrast test fails.
- [ ] **Step 5: Screenshot** light + dark in the web build and compare with the spike's B/C.
- [ ] **Step 6: Commit** `Wine colors: bordeaux frames (light), the cellar (dark)`.
