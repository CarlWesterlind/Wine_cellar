# Wine colors (small change)

## Why
The current light theme reads as pale pink and doesn't feel like wine.
Carl compared three palettes in the running app and picked B for light
mode and C for dark mode.

## What
- **Light (B, "Bordeaux frames")**: warm ivory background (`#FBF8F1`),
  deep bordeaux primary (`#6B1530`), champagne-gold containers
  (`#F1E3C2`), gold secondary (`#7A5A12`). The top app bar and the bottom
  navigation bar are filled bordeaux with champagne text and icons; the
  selected tab has a champagne pill.
- **Dark (C, "The cellar")**: oxblood-black background (`#1A0E11`) with
  red-brown cards, gold primary (`#D9B46A`), bordeaux containers
  (`#5E1226`) with champagne text.
- Unchanged: the drinking-status colors, the wine-type colors, layout,
  motion.

## Constraints
- Every text/background pair keeps WCAG AAA contrast (7:1), checked by
  `test/theme_test.dart`, including champagne on bordeaux in the bars.
- Flutter's accessibility guideline tests keep passing in both themes.

## Approaches
1. **Replace the two hand-picked color schemes** (chosen): smallest
   change, one look for everyone.
2. A palette picker in Settings: not asked for; more to build and test.

## Left to the builder
- Status bar icons on the bordeaux app bar must be light (Android/iOS).
- Small tweaks to hex values if a contrast test fails.
